#!/bin/bash

set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"

source "$script_dir/installer/common.sh"
source "$script_dir/skills/_insightark-shared/scripts/lib/install-config.sh"

base_dir=""
agents_csv=""
target_dir=""
legacy_host=""
interactive="true"
install_layout="per-agent"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --base-dir)
      base_dir="${2:-}"
      interactive="false"
      shift 2
      ;;
    --agents)
      agents_csv="${2:-}"
      interactive="false"
      shift 2
      ;;
    --host)
      legacy_host="${2:-}"
      interactive="false"
      printf 'Warning: --host is deprecated; use --agents %s\n' "$legacy_host" >&2
      shift 2
      ;;
    --target)
      target_dir="${2:-}"
      install_layout="direct"
      interactive="false"
      shift 2
      ;;
    --help)
      super8_print_usage "uninstall.sh"
      exit 0
      ;;
    *)
      printf 'Unknown option: %s\n' "$1" >&2
      super8_print_usage "uninstall.sh"
      exit 1
      ;;
  esac
done

if [ -n "$target_dir" ] && { [ -n "$agents_csv" ] || [ -n "$legacy_host" ]; }; then
  printf '--target cannot be combined with --agents or --host.\n' >&2
  exit 1
fi

remove_targets=()
selected_agents=()
expanded_base=""

if [ -n "$target_dir" ]; then
  remove_targets+=("$(super8_expand_base_dir "$target_dir")")
elif [ "$interactive" = "true" ]; then
  super8_print_interactive_header uninstall

  if s8_install_config_present; then
    printf 'Found install registry: %s\n' "$(super8_format_display_path "$(s8_install_config_path)")" >&2
    printf 'Use saved install locations? [Y/n]: ' >&2
    read -r use_config
    case "${use_config:-Y}" in
      y | Y | yes | YES | '')
        install_layout="$(s8_read_install_config_value layout)"
        expanded_base="$(s8_read_install_config_value base_dir)"
        while IFS= read -r target; do
          [ -n "$target" ] || continue
          remove_targets+=("$target")
        done < <(s8_install_skills_targets)
        if [ "${#remove_targets[@]}" -eq 0 ]; then
          printf 'No targets in install registry.\n' >&2
          exit 1
        fi
        ;;
      *)
        install_layout="$(super8_prompt_install_mode uninstall)"
        ;;
    esac
  else
    install_layout="$(super8_prompt_install_mode uninstall)"
  fi

  if [ "${#remove_targets[@]}" -eq 0 ]; then

    if [ "$install_layout" = "direct" ]; then
      expanded_base="$(super8_prompt_direct_skills_path 'Step 2 of 2')"
      remove_targets+=("$expanded_base")
    else
      while IFS= read -r agent; do
        [ -n "$agent" ] || continue
        selected_agents+=("$agent")
      done < <(super8_prompt_agents uninstall 'Step 2 of 3' | sort -u)

      if [ "${#selected_agents[@]}" -eq 0 ]; then
        printf 'No agents selected.\n' >&2
        exit 1
      fi

      expanded_base="$(super8_prompt_per_agent_base 'Step 3 of 3' uninstall)"
      for agent in "${selected_agents[@]}"; do
        remove_targets+=("$(super8_resolve_install_target "$expanded_base" "$agent")")
      done
    fi
  fi
else
  if [ -z "$base_dir" ]; then
    base_dir='~'
  fi
  expanded_base="$(super8_expand_base_dir "$base_dir")"

  if [ -n "$legacy_host" ] && [ -z "$agents_csv" ]; then
    agents_csv="$legacy_host"
  fi
  if [ -z "$agents_csv" ]; then
    printf 'Either --agents or --target is required in non-interactive mode.\n' >&2
    super8_print_usage "uninstall.sh"
    exit 1
  fi

  while IFS= read -r agent; do
    [ -n "$agent" ] || continue
    remove_targets+=("$(super8_resolve_install_target "$expanded_base" "$agent")")
  done < <(super8_parse_agents "$agents_csv" | sort -u)
fi

if [ "${#remove_targets[@]}" -eq 0 ]; then
  printf 'No uninstall targets resolved.\n' >&2
  exit 1
fi

for target in "${remove_targets[@]}"; do
  if [ -d "$target" ]; then
    super8_remove_bundle_dirs "$target"
    printf 'Removed InsightArk skills from %s\n' "$(super8_format_display_path "$target")"
    if [ -f "${target%/}/.insightark.env" ]; then
      rm -f "${target%/}/.insightark.env"
      printf 'Removed %s\n' "$(super8_format_display_path "${target%/}/.insightark.env")"
    fi
  else
    printf 'Skipped missing directory: %s\n' "$(super8_format_display_path "$target")" >&2
  fi
done

if s8_install_config_present; then
  super8_remove_install_config
  printf 'Removed install registry %s\n' "$(super8_format_display_path "$(s8_install_config_path)")"
fi
