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
  printf 'JSON body must include orgId plus MA graph fields required by POST /automation.\n' >&2
  exit 1
fi

s8_require_command curl
s8_require_command jq
s8_load_runtime_env

body="$(cat "$json_file")"
response_file="$(mktemp)"
status_file="$(mktemp)"
trap 'rm -f "$response_file" "$status_file"' EXIT

s8_api_request POST "/developer/v1/automation/procedures" "$body" "$response_file" "$status_file"
s8_expect_success "$(<"$status_file")" "$response_file"
s8_print_json_file "$response_file"
