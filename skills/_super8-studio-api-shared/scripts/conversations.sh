#!/bin/bash

set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
source "$script_dir/lib/env.sh"
source "$script_dir/lib/http.sh"
source "$script_dir/lib/output.sh"

org_id=""
customer_id=""
platform=""
start_at=""
end_at=""
time_field=""
cursor=""
limit=""
inbox=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --org-id) org_id="${2:-}"; shift 2 ;;
    --customer-id) customer_id="${2:-}"; shift 2 ;;
    --platform) platform="${2:-}"; shift 2 ;;
    --inbox) inbox="${2:-}"; shift 2 ;;
    --start-at) start_at="${2:-}"; shift 2 ;;
    --end-at) end_at="${2:-}"; shift 2 ;;
    --time-field) time_field="${2:-}"; shift 2 ;;
    --cursor) cursor="${2:-}"; shift 2 ;;
    --limit) limit="${2:-}"; shift 2 ;;
    *) printf 'Unknown option: %s\n' "$1" >&2; exit 1 ;;
  esac
done

s8_require_command curl
s8_require_command jq
s8_load_runtime_env
org_id="$(s8_resolve_org_id "$org_id")"

query_parts=("$(s8_query_pair orgId "$org_id")")
[ -n "$customer_id" ] && query_parts+=("$(s8_query_pair customerId "$customer_id")")
[ -n "$platform" ] && query_parts+=("$(s8_query_pair platform "$platform")")
[ -n "$inbox" ] && query_parts+=("$(s8_query_pair inbox "$inbox")")
[ -n "$start_at" ] && query_parts+=("$(s8_query_pair startAt "$start_at")")
[ -n "$end_at" ] && query_parts+=("$(s8_query_pair endAt "$end_at")")
[ -n "$time_field" ] && query_parts+=("$(s8_query_pair timeField "$time_field")")
[ -n "$cursor" ] && query_parts+=("$(s8_query_pair cursor "$cursor")")
[ -n "$limit" ] && query_parts+=("$(s8_query_pair limit "$limit")")

query_string="?$(IFS='&'; printf '%s' "${query_parts[*]}")"

response_file="$(mktemp)"
status_file="$(mktemp)"
trap 'rm -f "$response_file" "$status_file"' EXIT

s8_api_request GET "/developer/v1/conversations${query_string}" "" "$response_file" "$status_file"
s8_expect_success "$(<"$status_file")" "$response_file"
s8_print_json_file "$response_file"
