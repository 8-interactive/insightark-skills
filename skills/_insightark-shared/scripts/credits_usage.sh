#!/bin/bash

set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
source "$script_dir/lib/env.sh"
source "$script_dir/lib/http.sh"
source "$script_dir/lib/output.sh"

org_id=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --org-id) org_id="${2:-}"; shift 2 ;;
    -h|--help)
      printf 'Usage: %s [--org-id ID]\n' "$(basename "$0")" >&2
      printf 'GET /developer/v1/usage/credits — no credit cost; subject to org RPM only.\n' >&2
      exit 0
      ;;
    *) printf 'Unknown option: %s\n' "$1" >&2; exit 1 ;;
  esac
done

s8_require_command curl
s8_require_command jq
s8_load_runtime_env
org_id="$(s8_resolve_org_id "$org_id")"

response_file="$(mktemp)"
status_file="$(mktemp)"
trap 'rm -f "$response_file" "$status_file"' EXIT

s8_api_request GET "/developer/v1/usage/credits?orgId=$(printf '%s' "$org_id" | jq -sRr @uri)" "" "$response_file" "$status_file"
s8_expect_success "$(<"$status_file")" "$response_file"

remaining="$(jq -r '.data.remaining // .remaining // empty' "$response_file")"
refill="$(jq -r '.data.refillPerHour // .refillPerHour // empty' "$response_file")"
seconds="$(jq -r '.data.secondsUntilNextCredit // .secondsUntilNextCredit // empty' "$response_file")"
exhausted="$(jq -r '.data.creditExhausted // .creditExhausted // empty' "$response_file")"

printf '\n'
printf '=== Developer API Credits ===\n'
printf 'remaining: %s\n' "$remaining"
printf 'refillPerHour: %s\n' "$refill"
if [ "$exhausted" = "true" ] && [ -n "$seconds" ] && [ "$seconds" != "0" ]; then
  printf 'secondsUntilNextCredit: %s\n' "$seconds"
fi
printf 'note: This query does not consume credits (org RPM limits still apply).\n'
printf '\n'
s8_print_json_file "$response_file"
