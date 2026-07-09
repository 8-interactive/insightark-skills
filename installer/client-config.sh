#!/bin/bash

# Client MCP config merge helpers for Cursor and Codex fallback.

super8_cursor_mcp_config_path() {
  printf '%s/.cursor/mcp.json' "${HOME:-}"
}

super8_codex_config_path() {
  printf '%s/.codex/config.toml' "${HOME:-}"
}

super8_node_bin() {
  local probe_home="${SUPER8_TOOL_HOME:-${HOME:-}}"
  local node_bin=""

  if command -v asdf >/dev/null 2>&1; then
    node_bin="$(HOME="$probe_home" asdf which node 2>/dev/null || true)"
  fi
  if [ -z "$node_bin" ]; then
    node_bin="$(HOME="$probe_home" command -v node 2>/dev/null || true)"
  fi
  if [ -n "$node_bin" ]; then
    printf '%s' "$node_bin"
  fi
}

super8_merge_client_mcp_configs() {
  local mcp_url="$1"
  local session_token="$2"
  local merge_script cursor_path codex_path node_bin

  node_bin="$(super8_node_bin)"
  if [ -z "$node_bin" ]; then
    printf 'node is required to merge client MCP config\n' >&2
    return 1
  fi

  merge_script="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../scripts" && pwd)/merge-client-mcp-config.js"
  if [ ! -f "$merge_script" ]; then
    printf 'Missing merge script: %s\n' "$merge_script" >&2
    return 1
  fi

  cursor_path="$(super8_cursor_mcp_config_path)"
  codex_path="$(super8_codex_config_path)"

  super8_ensure_directory "$(dirname "$cursor_path")"
  HOME="${SUPER8_TOOL_HOME:-$HOME}" "$node_bin" "$merge_script" cursor --file "$cursor_path" --url "$mcp_url" --token "$session_token"
  printf 'Wrote %s (mode 600)\n' "$(super8_format_display_path "$cursor_path")"

  super8_ensure_directory "$(dirname "$codex_path")"
  HOME="${SUPER8_TOOL_HOME:-$HOME}" "$node_bin" "$merge_script" codex --file "$codex_path" --url "$mcp_url" --token "$session_token"
  printf 'Wrote %s (mode 600)\n' "$(super8_format_display_path "$codex_path")"
}
