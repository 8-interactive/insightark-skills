#!/bin/bash

set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
source "$script_dir/lib/env.sh"
source "$script_dir/lib/http.sh"
source "$script_dir/lib/output.sh"

s8_require_command curl
s8_require_command jq
s8_load_runtime_env

response_file="$(mktemp)"
status_file="$(mktemp)"
trap 'rm -f "$response_file" "$status_file"' EXIT

s8_api_request GET "/developer/v1/auth/me" "" "$response_file" "$status_file"
s8_expect_success "$(<"$status_file")" "$response_file"
s8_print_json_file "$response_file"
