#!/bin/bash

set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
source "$script_dir/lib/env.sh"
source "$script_dir/lib/http.sh"
source "$script_dir/lib/output.sh"
source "$script_dir/lib/messages_validate.sh"

org_id=""
messages_file=""
skip_validate="false"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --org-id) org_id="${2:-}"; shift 2 ;;
    --messages-file) messages_file="${2:-}"; shift 2 ;;
    --skip-validate) skip_validate="true"; shift ;;
    *) printf 'Unknown option: %s\n' "$1" >&2; exit 1 ;;
  esac
done

if [ -z "$messages_file" ] || [ ! -f "$messages_file" ]; then
  printf 'Usage: %s --messages-file PATH [--org-id ID]\n' "$(basename "$0")" >&2
  printf 'JSON file must include a non-empty messages array.\n' >&2
  printf 'Optional fields: quickReply, sampleCustomer, orgIconUrl, meta, platform.\n' >&2
  exit 1
fi

s8_require_command curl
s8_require_command jq

file_json="$(cat "$messages_file")"
messages_count="$(jq -r 'if (.messages | type) == "array" then (.messages | length) else "invalid" end' <<<"$file_json")"
if [ "$messages_count" = "invalid" ] || [ "$messages_count" -eq 0 ]; then
  printf 'messages-file must contain a non-empty messages array.\n' >&2
  exit 1
fi

platform="$(jq -r '.platform // "line"' <<<"$file_json")"
validate_args=(--file "$messages_file" --platform "$platform" --max-messages 50 --max-payload-bytes 262144)
if [ "$skip_validate" = "true" ]; then
  validate_args+=(--skip-validate)
fi
s8_run_messages_validate "${validate_args[@]}"

s8_load_runtime_env
org_id="$(s8_resolve_org_id "$org_id")"

body="$(jq -nc --arg orgId "$org_id" --argjson file "$file_json" '
  $file + {orgId: $orgId}
  | {
      orgId,
      messages,
      quickReply: (.quickReply? // null),
      sampleCustomer: (.sampleCustomer? // null),
      orgIconUrl: (.orgIconUrl? // null),
      meta: (.meta? // null),
      platform: (.platform? // null)
    }
  | with_entries(select(.value != null))
')"

response_file="$(mktemp)"
status_file="$(mktemp)"
trap 'rm -f "$response_file" "$status_file"' EXIT

s8_api_request POST "/developer/v1/preview/tokens" "$body" "$response_file" "$status_file"
s8_expect_success "$(<"$status_file")" "$response_file"

preview_url="$(jq -r '.data.previewUrl // .previewUrl // empty' "$response_file")"
expires_at="$(jq -r '.data.expiresAt // .expiresAt // empty' "$response_file")"

printf '\n'
printf '=== Message Preview ===\n'
printf 'previewUrl: %s\n' "$preview_url"
printf 'expiresAt: %s\n' "$expires_at"
printf 'note: Link expires in ~4 hours; costs 2 Developer API credits per token.\n'
printf '\n'
s8_print_json_file "$response_file"
