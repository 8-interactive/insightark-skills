#!/bin/bash

set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
source "$script_dir/lib/env.sh"
source "$script_dir/lib/http.sh"
source "$script_dir/lib/output.sh"

org_id=""
limit=""
cursor=""
status_filter=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --org-id) org_id="${2:-}"; shift 2 ;;
    --limit) limit="${2:-}"; shift 2 ;;
    --cursor) cursor="${2:-}"; shift 2 ;;
    --status) status_filter="${2:-}"; shift 2 ;;
    *) printf 'Unknown option: %s\n' "$1" >&2; exit 1 ;;
  esac
done

s8_require_command curl
s8_require_command jq
s8_load_runtime_env
org_id="$(s8_resolve_org_id "$org_id")"

query_parts=("$(s8_query_pair orgId "$org_id")")
[ -n "$limit" ] && query_parts+=("$(s8_query_pair limit "$limit")")
[ -n "$cursor" ] && query_parts+=("$(s8_query_pair cursor "$cursor")")
[ -n "$status_filter" ] && query_parts+=("$(s8_query_pair status "$status_filter")")

query_string="?$(IFS='&'; printf '%s' "${query_parts[*]}")"

response_file="$(mktemp)"
status_file="$(mktemp)"
trap 'rm -f "$response_file" "$status_file"' EXIT

s8_api_request GET "/developer/v1/broadcasts${query_string}" "" "$response_file" "$status_file"
s8_expect_success "$(<"$status_file")" "$response_file"
s8_print_json_file "$response_file"
