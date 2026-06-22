#!/bin/bash

set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
source "$script_dir/lib/env.sh"
source "$script_dir/lib/http.sh"
source "$script_dir/lib/output.sh"

org_id=""
customer_id=""
tags=()

while [ "$#" -gt 0 ]; do
  case "$1" in
    --org-id) org_id="${2:-}"; shift 2 ;;
    --customer-id) customer_id="${2:-}"; shift 2 ;;
    --tag) tags+=("${2:-}"); shift 2 ;;
    *) printf 'Unknown option: %s\n' "$1" >&2; exit 1 ;;
  esac
done

if [ -z "$customer_id" ]; then
  printf 'Missing required option: --customer-id\n' >&2
  exit 1
fi

if [ "${#tags[@]}" -eq 0 ]; then
  printf 'Provide at least one --tag value.\n' >&2
  exit 1
fi

s8_require_command curl
s8_require_command jq
s8_load_runtime_env
org_id="$(s8_resolve_org_id "$org_id")"

tags_json="$(printf '%s\n' "${tags[@]}" | jq -R . | jq -s .)"
body="$(jq -nc --arg orgId "$org_id" --argjson tags "$tags_json" '{orgId: $orgId, tags: $tags}')"

response_file="$(mktemp)"
status_file="$(mktemp)"
trap 'rm -f "$response_file" "$status_file"' EXIT

s8_api_request POST "/developer/v1/customers/${customer_id}/tags/remove" "$body" "$response_file" "$status_file"
s8_expect_success "$(<"$status_file")" "$response_file"
s8_print_json_file "$response_file"