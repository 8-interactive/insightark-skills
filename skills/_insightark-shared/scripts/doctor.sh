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
    printf 'Doctor status: failed (soft)\n'
    exit 0
  fi
  exit 1
}

s8_require_command curl || fail 'curl is required'
s8_require_command jq || fail 'jq is required'
s8_require_command mktemp || fail 'mktemp is required'

is_tty() {
  [ -t 0 ] && [ -t 1 ] && [ -t 2 ]
}

console_base_url_for_api() {
  local api="${1:-}"
  api="${api%/}"
  case "$api" in
    https://stage-api-*.no8.io|https://stage-api-next.no8.io)
      printf '%s\n' 'https://stage-console.no8.io'
      ;;
    *)
      printf '%s\n' 'https://console.no8.io'
      ;;
  esac
}

open_url() {
  local url="$1"
  if command -v open >/dev/null 2>&1; then
    open "$url" >/dev/null 2>&1 || true
    return 0
  fi
  if command -v xdg-open >/dev/null 2>&1; then
    xdg-open "$url" >/dev/null 2>&1 || true
    return 0
  fi
  return 1
}

print_token_onboarding() {
  local console_url="$1"
  printf '\nMissing or invalid S8_SESSION_TOKEN.\n\n' >&2
  printf 'How to get a token:\n' >&2
  printf '  1) Open Console: %s\n' "$console_url" >&2
  printf '  2) Account Settings → InsightArk MCP → Create token\n' >&2
  printf '  3) Copy the token (starts with r:) — shown once\n\n' >&2
  if [ -n "${CLAUDE_PLUGIN_ROOT:-}" ]; then
    printf 'Then in Claude Code, run:\n' >&2
    printf '  /plugin configure insightark-skills@insightark-skills\n\n' >&2
  else
    printf 'Then run:\n' >&2
    printf '  ./setup-env.sh\n\n' >&2
  fi
  if is_tty; then
    printf 'Open Console now? [Y/n]: ' >&2
    read -r answer
    case "${answer:-Y}" in
      y|Y|yes|YES|'')
        open_url "$console_url" || true
        ;;
    esac
  else
    printf 'Tip: open the Console URL above to create a token.\n' >&2
  fi
}

s8_mcp_tool_call() {
  local tool_name="$1"
  local args_json="${2-}"
  local response_file="$3"
  local status_file="$4"
  local body status url

  if [ -z "$args_json" ]; then
    args_json='{}'
  fi

  body="$(jq -nc --arg name "$tool_name" --argjson args "$args_json" \
    '{jsonrpc:"2.0",id:1,method:"tools/call",params:{name:$name,arguments:$args}}')"
  url="${S8_API_ROOT%/}/mcp"
  status="$(
    curl -sS -X POST \
      -H 'Accept: application/json, text/event-stream' \
      -H 'Content-Type: application/json' \
      -H "_SessionToken: ${S8_SESSION_TOKEN}" \
      -o "$response_file" \
      -w '%{http_code}' \
      --data "$body" \
      "$url"
  )"
  printf '%s' "$status" >"$status_file"
}

s8_mcp_tool_ok() {
  local response_file="$1"
  local is_error
  is_error="$(jq -r '.result.isError // false' "$response_file" 2>/dev/null || printf 'true')"
  if [ "$is_error" = "true" ]; then
    return 1
  fi
  return 0
}

s8_mcp_tool_text_json() {
  local response_file="$1"
  jq -r '.result.content[0].text // empty' "$response_file"
}

s8_load_env_files || true
if [ -z "${S8_API_URL:-}" ]; then
  S8_API_URL='https://api-next.no8.io'
fi
if [ -z "${S8_SESSION_TOKEN:-}" ]; then
  print_token_onboarding "$(console_base_url_for_api "$S8_API_URL")"
  fail 'Runtime environment is not ready'
fi

s8_load_runtime_env || fail 'Runtime environment is not ready'

response_file="$(mktemp)"
status_file="$(mktemp)"
trap 'rm -f "$response_file" "$status_file"' EXIT

s8_mcp_tool_call 'auth_me' '{}' "$response_file" "$status_file" || fail 'Failed to reach MCP auth_me'
if ! s8_expect_success "$(<"$status_file")" "$response_file" || ! s8_mcp_tool_ok "$response_file"; then
  print_token_onboarding "$(console_base_url_for_api "$S8_API_ROOT")"
  fail 'Current session is not usable'
fi

bundle_version_file="$script_dir/../VERSION"
installed_version="$(cat "$bundle_version_file" 2>/dev/null || printf 'unknown')"
auth_payload="$(s8_mcp_tool_text_json "$response_file")"

printf 'API URL: %s\n' "$S8_API_ROOT"
printf 'MCP endpoint: %s/mcp\n' "${S8_API_ROOT%/}"
printf 'Session token: present\n'
printf '%s\n' "$auth_payload" | jq -r '"User: " + (.user.email // "unknown")'
printf 'Installed skill bundle version: %s\n' "$installed_version"

printf 'Doctor status: ok\n'
