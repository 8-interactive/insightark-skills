#!/bin/bash

s8_api_request() {
  local method="$1"
  local path="$2"
  local body="$3"
  local response_file="$4"
  local status_file="$5"
  local status
  local url="${S8_API_ROOT}${path}"
  local curl_args

  curl_args=(
    -sS
    -X "$method"
    # MCP Streamable HTTP requires both types; JSON-only APIs still accept this.
    -H "Accept: application/json, text/event-stream"
    -H "_SessionToken: ${S8_SESSION_TOKEN}"
    -o "$response_file"
    -w "%{http_code}"
  )

  if [ -n "$body" ]; then
    curl_args+=( -H "Content-Type: application/json" --data "$body" )
  fi

  status="$(curl "${curl_args[@]}" "$url")"
  printf '%s' "$status" > "$status_file"
}

s8_expect_success() {
  local status="$1"
  local response_file="$2"

  case "$status" in
    2*)
      return 0
      ;;
    401)
      printf 'InsightArk MCP session is invalid or expired.\n' >&2
      printf 'Create a new token in Super 8 Console: Account Settings → InsightArk MCP.\n' >&2
      printf 'Do not commit tokens to version control.\n' >&2
      jq '.' "$response_file" >&2 2>/dev/null || cat "$response_file" >&2
      return 1
      ;;
    429)
      printf 'InsightArk MCP rate limit exceeded.\n' >&2
      jq '.' "$response_file" >&2 2>/dev/null || cat "$response_file" >&2
      return 1
      ;;
    *)
      printf 'API request failed with status %s\n' "$status" >&2
      jq '.' "$response_file" >&2 2>/dev/null || cat "$response_file" >&2
      return 1
      ;;
  esac
}
