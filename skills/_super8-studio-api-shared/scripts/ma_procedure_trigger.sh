#!/bin/bash

set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
source "$script_dir/lib/env.sh"
source "$script_dir/lib/http.sh"
source "$script_dir/lib/output.sh"

org_id=""
procedure_id=""
customer_id=""
trigger_type="api"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --org-id) org_id="${2:-}"; shift 2 ;;
    --procedure-id) procedure_id="${2:-}"; shift 2 ;;
    --customer-id) customer_id="${2:-}"; shift 2 ;;
    --type) trigger_type="${2:-}"; shift 2 ;;
    *) printf 'Unknown option: %s\n' "$1" >&2; exit 1 ;;
  esac
done

s8_require_command curl
s8_require_command jq
s8_load_runtime_env
org_id="$(s8_resolve_org_id "$org_id")"

if [ -z "$procedure_id" ] || [ -z "$customer_id" ]; then
  printf '--procedure-id and --customer-id are required.\n' >&2
  exit 1
fi

body="$(jq -nc \
  --arg orgId "$org_id" \
  --arg customerId "$customer_id" \
  --arg type "$trigger_type" \
  '{orgId: $orgId, customerId: $customerId, type: $type}')"

response_file="$(mktemp)"
status_file="$(mktemp)"
trap 'rm -f "$response_file" "$status_file"' EXIT

s8_api_request POST "/developer/v1/automation/procedures/${procedure_id}/trigger" "$body" "$response_file" "$status_file"
s8_expect_success "$(<"$status_file")" "$response_file"
s8_print_json_file "$response_file"
