#!/bin/bash

set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
source "$script_dir/lib/env.sh"
source "$script_dir/lib/http.sh"
source "$script_dir/lib/output.sh"

org_id=""
customer_ids=()
display_name=""
original_display_name=""
email=""
cell_phone=""
platforms=()
include_tags=()
exclude_tags=()
joined_start_at=""
joined_end_at=""
last_inbound_start_at=""
last_inbound_end_at=""
last_message_start_at=""
last_message_end_at=""
limit=""
skip=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --org-id) org_id="${2:-}"; shift 2 ;;
    --customer-id) customer_ids+=("${2:-}"); shift 2 ;;
    --display-name) display_name="${2:-}"; shift 2 ;;
    --original-display-name) original_display_name="${2:-}"; shift 2 ;;
    --email) email="${2:-}"; shift 2 ;;
    --cell-phone) cell_phone="${2:-}"; shift 2 ;;
    --platform) platforms+=("${2:-}"); shift 2 ;;
    --include-tag) include_tags+=("${2:-}"); shift 2 ;;
    --exclude-tag) exclude_tags+=("${2:-}"); shift 2 ;;
    --joined-start-at) joined_start_at="${2:-}"; shift 2 ;;
    --joined-end-at) joined_end_at="${2:-}"; shift 2 ;;
    --last-inbound-start-at) last_inbound_start_at="${2:-}"; shift 2 ;;
    --last-inbound-end-at) last_inbound_end_at="${2:-}"; shift 2 ;;
    --last-message-start-at) last_message_start_at="${2:-}"; shift 2 ;;
    --last-message-end-at) last_message_end_at="${2:-}"; shift 2 ;;
    --limit) limit="${2:-}"; shift 2 ;;
    --skip) skip="${2:-}"; shift 2 ;;
    *) printf 'Unknown option: %s\n' "$1" >&2; exit 1 ;;
  esac
done

s8_require_command curl
s8_require_command jq
s8_load_runtime_env
org_id="$(s8_resolve_org_id "$org_id")"

customer_ids_json='[]'
[ "${#customer_ids[@]}" -gt 0 ] && customer_ids_json="$(printf '%s\n' "${customer_ids[@]}" | jq -R . | jq -s .)"

platforms_json='[]'
[ "${#platforms[@]}" -gt 0 ] && platforms_json="$(printf '%s\n' "${platforms[@]}" | jq -R . | jq -s .)"

include_tags_json='[]'
[ "${#include_tags[@]}" -gt 0 ] && include_tags_json="$(printf '%s\n' "${include_tags[@]}" | jq -R . | jq -s .)"

exclude_tags_json='[]'
[ "${#exclude_tags[@]}" -gt 0 ] && exclude_tags_json="$(printf '%s\n' "${exclude_tags[@]}" | jq -R . | jq -s .)"

body="$(jq -nc \
  --arg orgId "$org_id" \
  --arg displayName "$display_name" \
  --arg originalDisplayName "$original_display_name" \
  --arg email "$email" \
  --arg cellPhone "$cell_phone" \
  --arg joinedStartAt "$joined_start_at" \
  --arg joinedEndAt "$joined_end_at" \
  --arg lastInboundStartAt "$last_inbound_start_at" \
  --arg lastInboundEndAt "$last_inbound_end_at" \
  --arg lastMessageStartAt "$last_message_start_at" \
  --arg lastMessageEndAt "$last_message_end_at" \
  --arg limit "$limit" \
  --arg skip "$skip" \
  --argjson customerIds "$customer_ids_json" \
  --argjson platforms "$platforms_json" \
  --argjson includeTags "$include_tags_json" \
  --argjson excludeTags "$exclude_tags_json" \
  '{orgId: $orgId}
   + (if ($customerIds | length) > 0 then {customerIds: $customerIds} else {} end)
   + (if $displayName != "" then {displayName: $displayName} else {} end)
   + (if $originalDisplayName != "" then {originalDisplayName: $originalDisplayName} else {} end)
   + (if $email != "" then {email: $email} else {} end)
   + (if $cellPhone != "" then {cellPhone: $cellPhone} else {} end)
   + (if ($platforms | length) > 0 then {platforms: $platforms} else {} end)
   + (if ($includeTags | length) > 0 then {includeTags: $includeTags} else {} end)
   + (if ($excludeTags | length) > 0 then {excludeTags: $excludeTags} else {} end)
   + (if ($joinedStartAt != "" or $joinedEndAt != "") then {
        joinedAt: ({ }
          + (if $joinedStartAt != "" then {startAt: $joinedStartAt} else {} end)
          + (if $joinedEndAt != "" then {endAt: $joinedEndAt} else {} end))
      } else {} end)
   + (if ($lastInboundStartAt != "" or $lastInboundEndAt != "") then {
        lastInboundAt: ({ }
          + (if $lastInboundStartAt != "" then {startAt: $lastInboundStartAt} else {} end)
          + (if $lastInboundEndAt != "" then {endAt: $lastInboundEndAt} else {} end))
      } else {} end)
   + (if ($lastMessageStartAt != "" or $lastMessageEndAt != "") then {
        lastMessageAt: ({ }
          + (if $lastMessageStartAt != "" then {startAt: $lastMessageStartAt} else {} end)
          + (if $lastMessageEndAt != "" then {endAt: $lastMessageEndAt} else {} end))
      } else {} end)
   + (if $limit != "" then {limit: ($limit | tonumber)} else {} end)
   + (if $skip != "" then {skip: ($skip | tonumber)} else {} end)')"

response_file="$(mktemp)"
status_file="$(mktemp)"
trap 'rm -f "$response_file" "$status_file"' EXIT

s8_api_request POST "/developer/v1/customers/search" "$body" "$response_file" "$status_file"
s8_expect_success "$(<"$status_file")" "$response_file"
s8_print_json_file "$response_file"