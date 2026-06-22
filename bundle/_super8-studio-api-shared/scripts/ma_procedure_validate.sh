#!/bin/bash

set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
source "$script_dir/lib/env.sh"
source "$script_dir/lib/http.sh"
source "$script_dir/lib/output.sh"

json_file=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --json-file) json_file="${2:-}"; shift 2 ;;
    *) printf 'Unknown option: %s\n' "$1" >&2; exit 1 ;;
  esac
done

if [ -z "$json_file" ] || [ ! -f "$json_file" ]; then
  printf 'Usage: %s --json-file PATH\n' "$(basename "$0")" >&2
  printf 'Validates POST body against /developer/v1/automation/procedures/validate (HTTP 200 + data.valid).\n' >&2
  printf 'Exits 0 only when HTTP 2xx and data.valid is true.\n' >&2
  exit 1
fi

s8_require_command curl
s8_require_command jq
s8_load_runtime_env

body="$(cat "$json_file")"
response_file="$(mktemp)"
status_file="$(mktemp)"
trap 'rm -f "$response_file" "$status_file"' EXIT

s8_api_request POST "/developer/v1/automation/procedures/validate" "$body" "$response_file" "$status_file"
http_status="$(<"$status_file")"

case "$http_status" in
  2*) ;;
  *)
    printf 'Validate request failed with HTTP status %s\n' "$http_status" >&2
    jq '.' "$response_file" >&2 2>/dev/null || cat "$response_file" >&2
    exit 1
    ;;
esac

valid="$(jq -r '.data.valid // empty' "$response_file")"
if [ "$valid" != "true" ]; then
  printf 'Payload invalid (data.valid is not true)\n' >&2
  jq '.' "$response_file" >&2
  exit 1
fi

s8_print_json_file "$response_file"
