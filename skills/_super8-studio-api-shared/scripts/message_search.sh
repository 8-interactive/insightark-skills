#!/bin/bash

set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
source "$script_dir/lib/env.sh"
source "$script_dir/lib/http.sh"
source "$script_dir/lib/output.sh"

org_id=""
conversation_id=""
platform=""
start_at=""
end_at=""
limit=""
skip=""
keywords=()
sender_types=()
sender_ids=()

while [ "$#" -gt 0 ]; do
  case "$1" in
    --org-id) org_id="${2:-}"; shift 2 ;;
    --conversation-id) conversation_id="${2:-}"; shift 2 ;;
    --platform) platform="${2:-}"; shift 2 ;;
    --start-at) start_at="${2:-}"; shift 2 ;;
    --end-at) end_at="${2:-}"; shift 2 ;;
    --limit) limit="${2:-}"; shift 2 ;;
    --skip) skip="${2:-}"; shift 2 ;;
    --keyword) keywords+=("${2:-}"); shift 2 ;;
    --sender-type) sender_types+=("${2:-}"); shift 2 ;;
    --sender-id) sender_ids+=("${2:-}"); shift 2 ;;
    *) printf 'Unknown option: %s\n' "$1" >&2; exit 1 ;;
  esac
done

s8_require_command curl
s8_require_command jq
s8_load_runtime_env
org_id="$(s8_resolve_org_id "$org_id")"

if [ "${#keywords[@]}" -eq 0 ]; then
  printf 'Missing required option: at least one --keyword\n' >&2
  exit 1
fi

keyword_json='null'
if [ "${#keywords[@]}" -eq 1 ]; then
  keyword_json="$(jq -nc --arg keyword "${keywords[0]}" '$keyword')"
elif [ "${#keywords[@]}" -gt 1 ]; then
  keyword_json="$(printf '%s\n' "${keywords[@]}" | jq -R . | jq -s .)"
fi

sender_type_json='null'
if [ "${#sender_types[@]}" -eq 1 ]; then
  sender_type_json="$(jq -nc --arg senderType "${sender_types[0]}" '$senderType')"
elif [ "${#sender_types[@]}" -gt 1 ]; then
  sender_type_json="$(printf '%s\n' "${sender_types[@]}" | jq -R . | jq -s .)"
fi

sender_ids_json='null'
if [ "${#sender_ids[@]}" -eq 1 ]; then
  sender_ids_json="$(jq -nc --arg senderId "${sender_ids[0]}" '[$senderId]')"
elif [ "${#sender_ids[@]}" -gt 1 ]; then
  sender_ids_json="$(printf '%s\n' "${sender_ids[@]}" | jq -R . | jq -s .)"
fi

body="$(jq -nc \
  --arg orgId "$org_id" \
  --arg conversationId "$conversation_id" \
  --arg platform "$platform" \
  --arg startAt "$start_at" \
  --arg endAt "$end_at" \
  --argjson keyword "$keyword_json" \
  --argjson senderType "$sender_type_json" \
  --argjson senderIds "$sender_ids_json" \
  --arg limit "$limit" \
  --arg skip "$skip" \
  '{orgId: $orgId}
   + (if $conversationId != "" then {conversationId: $conversationId} else {} end)
   + (if $platform != "" then {platform: $platform} else {} end)
   + (if $keyword != null then {keyword: $keyword} else {} end)
   + (if $startAt != "" then {startAt: $startAt} else {} end)
   + (if $endAt != "" then {endAt: $endAt} else {} end)
   + (if $senderType != null then {senderType: $senderType} else {} end)
   + (if $senderIds != null then {senderIds: $senderIds} else {} end)
   + (if $limit != "" then {limit: ($limit | tonumber)} else {} end)
   + (if $skip != "" then {skip: ($skip | tonumber)} else {} end)')"

response_file="$(mktemp)"
status_file="$(mktemp)"
trap 'rm -f "$response_file" "$status_file"' EXIT

s8_api_request POST "/developer/v1/messages/search" "$body" "$response_file" "$status_file"
s8_expect_success "$(<"$status_file")" "$response_file"
s8_print_json_file "$response_file"
