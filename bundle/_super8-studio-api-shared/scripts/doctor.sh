#!/bin/bash

set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
source "$script_dir/lib/env.sh"
source "$script_dir/lib/http.sh"

soft_fail="false"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --soft-fail) soft_fail="true"; shift ;;
    *) printf 'Unknown option: %s\n' "$1" >&2; exit 1 ;;
  esac
done

fail() {
  printf '%s\n' "$1" >&2
  if [ "$soft_fail" = "true" ]; then
    return 0
  fi
  exit 1
}

s8_require_command curl || fail 'curl is required'
s8_require_command jq || fail 'jq is required'
s8_require_command mktemp || fail 'mktemp is required'

s8_load_runtime_env || fail 'Runtime environment is not ready'

response_file="$(mktemp)"
status_file="$(mktemp)"
orgs_file="$(mktemp)"
orgs_status_file="$(mktemp)"
trap 'rm -f "$response_file" "$status_file" "$orgs_file" "$orgs_status_file"' EXIT

s8_api_request GET "/developer/v1/auth/me" "" "$response_file" "$status_file" || fail 'Failed to reach auth/me endpoint'
s8_expect_success "$(<"$status_file")" "$response_file" || fail 'Current session is not usable'

bundle_version_file="$script_dir/../VERSION"
installed_version="$(cat "$bundle_version_file" 2>/dev/null || printf 'unknown')"
latest_skill_version="$(jq -r '.data.latestSkillVersion // empty' "$response_file")"

printf 'Doctor status: ok\n'
printf 'API URL: %s\n' "$S8_API_ROOT"
printf 'Session token: present\n'
jq -r '"User: " + (.data.user.email // "unknown")' "$response_file"
printf 'Installed skill bundle version: %s\n' "$installed_version"
if [ -n "$latest_skill_version" ]; then
  printf 'Latest skill bundle version: %s\n' "$latest_skill_version"
  if [ "$installed_version" != "$latest_skill_version" ] && [ "$installed_version" != "unknown" ]; then
    printf 'Warning: skill bundle is outdated. Re-run install.sh to update.\n' >&2
  fi
fi

s8_api_request GET "/developer/v1/auth/organizations" "" "$orgs_file" "$orgs_status_file" || fail 'Failed to reach auth/organizations endpoint'
if s8_expect_success "$(<"$orgs_status_file")" "$orgs_file"; then
  jq -r '"Manageable orgs: " + ((.data.organizations // []) | length | tostring)' "$orgs_file"
fi

if [ -n "${S8_ORG_ID:-}" ]; then
  printf 'Default org: %s\n' "$S8_ORG_ID"
else
  printf 'Default org: not set\n'
fi
