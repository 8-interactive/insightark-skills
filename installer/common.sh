#!/bin/bash

set -euo pipefail

super8_all_agent_ids() {
  printf '%s\n' claude-code opencode cursor github-copilot codex
}

super8_agent_label() {
  local agent="$1"
  case "$agent" in
    claude-code) printf 'Claude Code' ;;
    opencode) printf 'OpenCode' ;;
    cursor) printf 'Cursor' ;;
    github-copilot) printf 'GitHub Copilot' ;;
    codex) printf 'Codex' ;;
    *) printf '%s' "$agent" ;;
  esac
}

super8_agent_subpath() {
  local agent="$1"
  case "$agent" in
    claude-code) printf '.claude/skills' ;;
    opencode) printf '.opencode/skills' ;;
    cursor) printf '.cursor/skills' ;;
    github-copilot) printf '.copilot/skills' ;;
    codex) printf '.codex/skills' ;;
    *)
      printf 'Unsupported agent: %s\n' "$agent" >&2
      return 1
      ;;
  esac
}

super8_expand_base_dir() {
  local input="${1:-}"
  local expanded

  if [ -z "$input" ]; then
    printf 'Base directory is required.\n' >&2
    return 1
  fi

  case "$input" in
    '~') expanded="${HOME:-}" ;;
    '~'/*) expanded="${HOME:-}${input#\~}" ;;
    *) expanded="$input" ;;
  esac

  if [ -z "$expanded" ]; then
    printf 'Could not resolve home directory for path: %s\n' "$input" >&2
    return 1
  fi

  expanded="${expanded%/}"
  printf '%s' "$expanded"
}

super8_resolve_install_target() {
  local base_dir="$1"
  local agent="$2"
  local subpath

  subpath="$(super8_agent_subpath "$agent")"
  printf '%s/%s' "$base_dir" "$subpath"
}

super8_format_display_path() {
  local path="$1"
  local home="${HOME:-}"

  if [ -z "$path" ]; then
    return 0
  fi
  if [ -n "$home" ] && [ "$path" = "$home" ]; then
    printf '~'
    return 0
  fi
  if [ -n "$home" ] && [[ "$path" == "$home/"* ]]; then
    printf '~/%s' "${path#"$home/"}"
    return 0
  fi
  printf '%s' "$path"
}

super8_is_supported_agent() {
  local agent="$1"
  local id
  while IFS= read -r id; do
    if [ "$id" = "$agent" ]; then
      return 0
    fi
  done < <(super8_all_agent_ids)
  return 1
}

super8_parse_agents() {
  local csv="${1:-}"
  local item
  local -a agents=()

  if [ -z "$csv" ]; then
    printf 'At least one agent is required.\n' >&2
    return 1
  fi

  if [ "$csv" = "all" ]; then
    super8_all_agent_ids
    return 0
  fi

  IFS=',' read -r -a agents <<<"$csv"
  for item in "${agents[@]}"; do
    item="$(printf '%s' "$item" | tr -d '[:space:]')"
    [ -n "$item" ] || continue
    if ! super8_is_supported_agent "$item"; then
      printf 'Unsupported agent: %s\n' "$item" >&2
      return 1
    fi
    printf '%s\n' "$item"
  done
}

super8_agent_from_legacy_host() {
  local host="$1"
  case "$host" in
    claude-code | opencode | cursor | github-copilot | codex) printf '%s' "$host" ;;
    *)
      printf 'Unsupported host: %s\n' "$host" >&2
      return 1
      ;;
  esac
}

super8_resolve_default_target() {
  local host="$1"
  local agent base_dir

  agent="$(super8_agent_from_legacy_host "$host")"
  base_dir="$(super8_expand_base_dir '~')"
  super8_resolve_install_target "$base_dir" "$agent"
}

super8_print_usage() {
  local script_name="$1"
  cat <<EOF
Usage: ${script_name} [options]

Options:
  --base-dir PATH   Base directory (default: ~). Skills install to {base}/{agent-subpath}
  --agents LIST     Comma-separated agents: claude-code,opencode,cursor,github-copilot,codex (or "all")
  --target PATH     Install directly to PATH (advanced; skips agent subpaths; mutually exclusive with --agents)
  --host AGENT      Deprecated alias for --agents AGENT (single agent, base ~)
  --help            Show this help message

Interactive mode runs when --base-dir, --agents, --target, and --host are all omitted.
EOF
}

super8_count_bundle_skills() {
  local bundle_dir="$1"
  local count=0
  local entry

  shopt -s nullglob
  for entry in "$bundle_dir"/insightark-*/; do
    [ -d "$entry" ] || continue
    count=$((count + 1))
  done
  shopt -u nullglob
  printf '%s' "$count"
}

super8_print_interactive_header() {
  local mode="${1:-install}"
  local bundle_dir="${2:-}"

  printf '\n' >&2
  printf '%s\n' '============================================================' >&2
  if [ "$mode" = "install" ]; then
    printf '%s\n' '  SUPER 8 Studio InsightArk Skills — Installer' >&2
  else
    printf '%s\n' '  SUPER 8 Studio InsightArk Skills — Uninstaller' >&2
  fi
  printf '%s\n' '============================================================' >&2
  printf '\n' >&2

  if [ "$mode" = "install" ]; then
    printf 'This script installs AI agent skills for the Super 8 Studio\n' >&2
    printf 'Developer API. After install, your agent (Cursor, Claude Code,\n' >&2
    printf 'OpenCode, GitHub Copilot, Codex, etc.) can help you manage\n' >&2
    printf 'customers, conversations, broadcasts, marketing automation,\n' >&2
    printf 'and more via shell scripts backed by the API.\n' >&2
    if [ -n "$bundle_dir" ] && [ -d "$bundle_dir" ]; then
      printf '\n' >&2
      printf 'Package: %s skill(s) from this bundle.\n' \
        "$(super8_count_bundle_skills "$bundle_dir")" >&2
    fi
    printf '\n' >&2
    printf 'Credentials are configured separately — after install you can\n' >&2
    printf 'run ./setup-env.sh to set up ~/.insightark.env.\n' >&2
  else
    printf 'This script removes InsightArk skills previously\n' >&2
    printf 'installed under your agent skills directories.\n' >&2
  fi
  printf '\n' >&2
}

super8_print_step_divider() {
  local step="$1"
  local title="$2"

  printf '%s\n' '------------------------------------------------------------' >&2
  printf '%s — %s\n' "$step" "$title" >&2
  printf '%s\n' '------------------------------------------------------------' >&2
}

super8_print_selected_agent_paths() {
  local base_dir="$1"
  shift
  local agent target

  printf '\n' >&2
  printf 'Skills will be installed to:\n' >&2
  for agent in "$@"; do
    target="$(super8_resolve_install_target "$base_dir" "$agent")"
    printf '  • %s → %s\n' "$(super8_agent_label "$agent")" "$(super8_format_display_path "$target")" >&2
  done
  printf '\n' >&2
}

super8_print_install_plan() {
  local layout="$1"
  local location="$2"
  shift 2
  local -a agents=("$@")
  local agent target

  printf '\n' >&2
  printf '%s\n' '============================================================' >&2
  printf '%s\n' '  Confirm installation' >&2
  printf '%s\n' '============================================================' >&2
  printf '\n' >&2
  printf 'InsightArk skills will be installed to:\n' >&2
  printf '\n' >&2

  if [ "$layout" = "direct" ]; then
    printf '  • %s\n' "$(super8_format_display_path "$location")" >&2
  else
    for agent in "${agents[@]}"; do
      target="$(super8_resolve_install_target "$location" "$agent")"
      printf '  • %s → %s\n' "$(super8_agent_label "$agent")" "$(super8_format_display_path "$target")" >&2
    done
  fi
  printf '\n' >&2
}

super8_prompt_install_confirm() {
  local confirm

  printf 'Proceed with installation? [Y/n]: ' >&2
  read -r confirm
  case "${confirm:-Y}" in
    y | Y | yes | YES | '')
      return 0
      ;;
    *)
      printf 'Installation cancelled.\n' >&2
      return 1
      ;;
  esac
}

# stdout: direct | per-agent
super8_prompt_install_mode() {
  local context="${1:-install}"
  local choice

  if [ "$context" = "install" ]; then
    super8_print_step_divider 'Step 1' 'How should skills be installed?'
    printf '\n' >&2
    printf '  1) I specify the skills folder myself\n' >&2
    printf '     One shared folder for all agents (e.g. ~/.agents/skills)\n' >&2
    printf '  2) Install into each coding agent'\''s default folder\n' >&2
    printf '     We place skills only for the agents you select\n' >&2
  else
    super8_print_step_divider 'Step 1' 'How were skills installed?'
    printf '\n' >&2
    printf '  1) A custom/shared skills folder I specified\n' >&2
    printf '  2) Per-agent default folders (auto layout)\n' >&2
  fi
  printf '\n' >&2
  printf 'Choice [2]: ' >&2
  read -r choice

  case "${choice:-2}" in
    1 | direct | custom | shared | folder)
      printf 'direct'
      ;;
    2 | per-agent | agent | agents | auto)
      printf 'per-agent'
      ;;
    *)
      printf 'Unknown choice. Enter 1 or 2.\n' >&2
      return 1
      ;;
  esac
}

# stdout: expanded path
super8_prompt_direct_skills_path() {
  local step_label="${1:-Step 2 of 2}"
  local path expanded

  super8_print_step_divider "$step_label" 'Skills folder path'
  printf '\n' >&2
  printf 'Enter the folder where skills should be installed.\n' >&2
  printf 'Path [~/.agents/skills]: ' >&2
  read -r path
  if [ -z "$path" ]; then
    path='~/.agents/skills'
  fi
  expanded="$(super8_expand_base_dir "$path")"
  printf '\n' >&2
  printf 'Using skills folder: %s\n' "$(super8_format_display_path "$expanded")" >&2
  printf '%s' "$expanded"
}

# stdout: expanded base path
super8_prompt_per_agent_base() {
  local step_label="${1:-Step 3 of 3}"
  local context="${2:-install}"
  local choice path expanded

  if [ "$context" = "install" ]; then
    super8_print_step_divider "$step_label" 'User space or project space?'
    printf '\n' >&2
    printf '  1) User space — your home directory (~)\n' >&2
    printf '  2) Project space — a project root path\n' >&2
  else
    super8_print_step_divider "$step_label" 'Where was the base directory?'
    printf '\n' >&2
    printf '  1) Home directory (~)\n' >&2
    printf '  2) A project root path\n' >&2
  fi
  printf '\n' >&2
  printf 'Choice [1]: ' >&2
  read -r choice

  case "${choice:-1}" in
    1 | ~ | home | Home | user)
      expanded="$(super8_expand_base_dir '~')"
      ;;
    2 | project | path | custom)
      if [ "$context" = "install" ]; then
        printf 'Project root path (e.g. ~/my-project): ' >&2
      else
        printf 'Project root path: ' >&2
      fi
      read -r path
      expanded="$(super8_expand_base_dir "$path")"
      ;;
    *)
      if super8_expand_base_dir "$choice" >/dev/null 2>&1; then
        expanded="$(super8_expand_base_dir "$choice")"
      else
        printf 'Unknown choice. Enter 1, 2, or a valid path.\n' >&2
        return 1
      fi
      ;;
  esac

  printf '\n' >&2
  printf 'Using base directory: %s\n' "$(super8_format_display_path "$expanded")" >&2
  printf '%s' "$expanded"
}

super8_prompt_agents() {
  local mode="${1:-install}"
  local step_label="${2:-}"
  local choice selection item num agent_id
  local -a selected=()
  local -a agent_ids=()

  while IFS= read -r agent_id; do
    agent_ids+=("$agent_id")
  done < <(super8_all_agent_ids)

  if [ "$mode" = "install" ]; then
    if [ -n "$step_label" ]; then
      super8_print_step_divider "$step_label" 'Which coding agents do you use?'
    else
      super8_print_step_divider 'Step 2' 'Which coding agents do you use?'
    fi
    printf '\n' >&2
    printf 'Skills will be installed only for the agents you pick.\n' >&2
    printf 'Enter comma-separated numbers, agent ids, or "all":\n' >&2
  else
    if [ -n "$step_label" ]; then
      super8_print_step_divider "$step_label" 'Which agents should be cleaned up?'
    else
      super8_print_step_divider 'Step 2' 'Which agents should be cleaned up?'
    fi
    printf '\n' >&2
    printf 'Select agents to remove InsightArk skills from:\n' >&2
  fi
  printf '\n' >&2
  num=1
  for agent_id in "${agent_ids[@]}"; do
    printf '  %s) %s (%s)\n' "$num" "$(super8_agent_label "$agent_id")" "$agent_id" >&2
    num=$((num + 1))
  done
  printf '\n' >&2
  if [ "$mode" = "install" ]; then
    printf 'Selection [e.g. 3 for Cursor, or 1,3,5]: ' >&2
  else
    printf 'Selection: ' >&2
  fi
  read -r choice

  if [ -z "$choice" ]; then
    printf 'At least one agent is required.\n' >&2
    return 1
  fi

  if [ "$choice" = "all" ]; then
    super8_all_agent_ids
    return 0
  fi

  IFS=',' read -r -a selected <<<"$choice"
  for item in "${selected[@]}"; do
    item="$(printf '%s' "$item" | tr -d '[:space:]')"
    [ -n "$item" ] || continue
    if ! [[ "$item" =~ ^[0-9]+$ ]]; then
      if super8_is_supported_agent "$item"; then
        printf '%s\n' "$item"
        continue
      fi
      printf 'Invalid selection: %s\n' "$item" >&2
      return 1
    fi
    if [ "$item" -lt 1 ] || [ "$item" -gt "${#agent_ids[@]}" ]; then
      printf 'Invalid selection: %s\n' "$item" >&2
      return 1
    fi
    printf '%s\n' "${agent_ids[$((item - 1))]}"
  done
}

super8_ensure_directory() {
  local dir="$1"
  if [ -d "$dir" ]; then
    return 0
  fi
  mkdir -p "$dir"
}

super8_list_bundle_dirs() {
  local bundle_dir="$1"
  local entry
  shopt -s nullglob
  for entry in "$bundle_dir"/insightark-*/ "$bundle_dir"/_insightark-*/; do
    [ -d "$entry" ] || continue
    basename "$entry"
  done
  shopt -u nullglob
}

super8_remove_bundle_dirs() {
  local target_dir="$1"
  local entry
  shopt -s nullglob
  for entry in "$target_dir"/insightark-*/ "$target_dir"/_insightark-*/; do
    [ -d "$entry" ] || continue
    rm -rf "$entry"
  done
  shopt -u nullglob
}

super8_copy_bundle() {
  local bundle_dir="$1"
  local target_dir="$2"
  local dir_name

  mkdir -p "$target_dir"
  while IFS= read -r dir_name; do
    [ -n "$dir_name" ] || continue
    cp -R "$bundle_dir/$dir_name" "$target_dir/$dir_name"
  done < <(super8_list_bundle_dirs "$bundle_dir")
}

super8_open_url() {
  local url="$1"
  if command -v open >/dev/null 2>&1; then
    open "$url" >/dev/null 2>&1 || true
  elif command -v xdg-open >/dev/null 2>&1; then
    xdg-open "$url" >/dev/null 2>&1 || true
  elif command -v cmd.exe >/dev/null 2>&1; then
    cmd.exe /c start "" "$url" >/dev/null 2>&1 || true
  else
    printf 'Open this URL in your browser:\n%s\n' "$url"
  fi
}

super8_console_base_for_api_url() {
  local api_url="${1%/}"
  case "$api_url" in
    https://api-next.no8.io) printf 'https://console.no8.io' ;;
    https://stage-api-next.no8.io) printf 'https://stage-console.no8.io' ;;
    *) printf '' ;;
  esac
}

super8_build_console_token_url() {
  local console_base="${1%/}"
  local label="${2:-insightark-skills}"
  printf '%s/account-setting/user-info?setup=developer-api-skills&action=create-token&label=%s' \
    "$console_base" "$label"
}
