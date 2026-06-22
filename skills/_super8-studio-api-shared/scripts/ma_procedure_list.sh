#!/usr/bin/env bash

set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
source "$script_dir/lib/env.sh"
source "$script_dir/lib/http.sh"
source "$script_dir/lib/output.sh"

org_id=""
name_filter=""
skip_val=""
limit_val=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --org-id) org_id="${2:-}"; shift 2 ;;
    --name) name_filter="${2:-}"; shift 2 ;;
    --skip) skip_val="${2:-}"; shift 2 ;;
    --limit) limit_val="${2:-}"; shift 2 ;;
    *)
      printf 'Unknown option: %s\n' "$1" >&2
      exit 1
      ;;
  esac
done

s8_require_command curl
s8_require_command jq
s8_load_runtime_env
org_id="$(s8_resolve_org_id "$org_id")"

: "${limit_val:=20}"

query_string="?$(s8_query_pair orgId "$org_id")"
if [ -n "$name_filter" ]; then
  query_string="${query_string}&$(s8_query_pair name "$name_filter")"
fi
if [ -n "$skip_val" ]; then
  query_string="${query_string}&$(s8_query_pair skip "$skip_val")"
fi
query_string="${query_string}&$(s8_query_pair limit "$limit_val")"

response_file="$(mktemp)"
status_file="$(mktemp)"
trap 'rm -f "$response_file" "$status_file"' EXIT

s8_api_request GET "/developer/v1/automation/procedures${query_string}" "" "$response_file" "$status_file"
s8_expect_success "$(<"$status_file")" "$response_file"
s8_print_json_file "$response_file"
