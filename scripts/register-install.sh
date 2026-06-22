#!/bin/bash

set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
repo_dir="$(CDPATH= cd -- "$script_dir/.." && pwd)"

source "$repo_dir/installer/common.sh"
source "$repo_dir/skills/_super8-studio-api-shared/scripts/lib/install-config.sh"

base_dir=""
agents_csv=""
target_dir=""
layout="direct"

print_usage() {
  cat <<EOF
Usage: scripts/register-install.sh [options]

Records installed Super 8 Studio skills paths in ~/.super8-studio.config.
This helper is for package managers that already copied skills/ themselves.
Prefer ./install.sh when the install flow can copy files directly.

Options:
  --target PATH     Installed skills directory to record
  --base-dir PATH   Base directory for per-agent installs
  --agents LIST     Comma-separated agents: claude-code,opencode,cursor,github-copilot,codex
  --help            Show this help message
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --target)
      target_dir="${2:-}"
      layout="direct"
      shift 2
      ;;
    --base-dir)
      base_dir="${2:-}"
      layout="per-agent"
      shift 2
      ;;
    --agents)
      agents_csv="${2:-}"
      layout="per-agent"
      shift 2
      ;;
    --help)
      print_usage
      exit 0
      ;;
    *)
      printf 'Unknown option: %s\n' "$1" >&2
      print_usage
      exit 1
      ;;
  esac
done

install_targets=()
expanded_base=""

if [ -n "$target_dir" ]; then
  if [ -n "$agents_csv" ] || [ -n "$base_dir" ]; then
    printf '--target cannot be combined with --base-dir or --agents.\n' >&2
    exit 1
  fi
  expanded_base="$(super8_expand_base_dir "$target_dir")"
  install_targets+=("$expanded_base")
  layout="direct"
else
  if [ -z "$base_dir" ]; then
    base_dir='~'
  fi
  if [ -z "$agents_csv" ]; then
    printf 'Either --target or --agents is required.\n' >&2
    print_usage
    exit 1
  fi
  expanded_base="$(super8_expand_base_dir "$base_dir")"
  while IFS= read -r agent; do
    [ -n "$agent" ] || continue
    install_targets+=("$(super8_resolve_install_target "$expanded_base" "$agent")")
  done < <(super8_parse_agents "$agents_csv" | sort -u)
  layout="per-agent"
fi

if [ "${#install_targets[@]}" -eq 0 ]; then
  printf 'No install targets resolved.\n' >&2
  exit 1
fi

super8_write_install_config "$layout" "$expanded_base" "$agents_csv" "${install_targets[@]}"
printf 'Recorded Super 8 Studio skills install registry: %s\n' "$(super8_format_display_path "$(s8_install_config_path)")"
for target in "${install_targets[@]}"; do
  printf '  - %s\n' "$(super8_format_display_path "$target")"
done
