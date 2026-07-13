#!/bin/bash

set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
bundle_dir="$script_dir/skills"

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
    --skip-doctor)
      printf 'Warning: --skip-doctor is deprecated; install no longer runs doctor (use ./setup-env.sh).\n' >&2
      shift
      ;;
    --help)
      super8_print_usage "install.sh"
      exit 0
      ;;
    *)
      printf 'Unknown option: %s\n' "$1" >&2
      super8_print_usage "install.sh"
      exit 1
      ;;
  esac
done

if [ -n "$target_dir" ] && { [ -n "$agents_csv" ] || [ -n "$legacy_host" ]; }; then
  printf '--target cannot be combined with --agents or --host.\n' >&2
  exit 1
fi

install_targets=()
selected_agents=()
agents_for_config=""
expanded_base=""

if [ -n "$target_dir" ]; then
  expanded_base="$(super8_expand_base_dir "$target_dir")"
  install_targets+=("$expanded_base")
elif [ "$interactive" = "true" ]; then
  super8_print_interactive_header install "$bundle_dir"
  install_layout="$(super8_prompt_install_mode install)"

  if [ "$install_layout" = "direct" ]; then
    expanded_base="$(super8_prompt_direct_skills_path 'Step 2 of 2')"
    install_targets+=("$expanded_base")
  else
    while IFS= read -r agent; do
      [ -n "$agent" ] || continue
      selected_agents+=("$agent")
    done < <(super8_prompt_agents install 'Step 2 of 3' | sort -u)

    if [ "${#selected_agents[@]}" -eq 0 ]; then
      printf 'No agents selected.\n' >&2
      exit 1
    fi

    expanded_base="$(super8_prompt_per_agent_base 'Step 3 of 3' install)"

    for agent in "${selected_agents[@]}"; do
      install_targets+=("$(super8_resolve_install_target "$expanded_base" "$agent")")
    done
  fi

  if [ "$install_layout" = "direct" ]; then
    super8_print_install_plan direct "$expanded_base"
  else
    super8_print_install_plan per-agent "$expanded_base" "${selected_agents[@]}"
  fi
  if ! super8_prompt_install_confirm; then
    exit 0
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
    super8_print_usage "install.sh"
    exit 1
  fi

  agents_for_config="$agents_csv"
  while IFS= read -r agent; do
    [ -n "$agent" ] || continue
    install_targets+=("$(super8_resolve_install_target "$expanded_base" "$agent")")
  done < <(super8_parse_agents "$agents_csv" | sort -u)
fi

if [ -z "$agents_for_config" ] && [ "${#selected_agents[@]}" -gt 0 ]; then
  agents_for_config="$(IFS=,; printf '%s' "${selected_agents[*]}")"
fi

super8_write_install_config "$install_layout" "${expanded_base:-}" "$agents_for_config" "${install_targets[@]}"
printf 'Wrote install registry %s\n' "$(super8_format_display_path "$(s8_install_config_path)")" >&2

if [ "${#install_targets[@]}" -eq 0 ]; then
  printf 'No install targets resolved.\n' >&2
  exit 1
fi

printf '\n' >&2
printf 'Installing InsightArk skills...\n' >&2
printf '\n' >&2

for target in "${install_targets[@]}"; do
  printf '  → %s\n' "$(super8_format_display_path "$target")" >&2
  super8_ensure_directory "$target"
  super8_remove_bundle_dirs "$target"
  super8_copy_bundle "$bundle_dir" "$target"
  find "$target/_insightark-shared/scripts" -type f -name '*.sh' -exec chmod +x {} +
done

printf '\n' >&2
printf 'Done. Installed to %s location(s).\n' "${#install_targets[@]}" >&2

if [ "$interactive" = "true" ]; then
  printf '\n' >&2
  printf '%s\n' '============================================================' >&2
  printf '%s\n' '  Next step: API credentials' >&2
  printf '%s\n' '============================================================' >&2
  printf '\n' >&2
  printf 'Skills are installed. Configure API credentials next;\n' >&2
  printf 'setup will run a health check (doctor) when finished.\n' >&2
  printf '\n' >&2
  printf 'Run ./setup-env.sh now? [Y/n]: ' >&2
  read -r run_setup
  case "${run_setup:-Y}" in
    y | Y | yes | YES | '')
      bash "$script_dir/setup-env.sh"
      ;;
    *)
      printf '\n' >&2
      printf 'When ready, run ./setup-env.sh (includes doctor check).\n' >&2
      ;;
  esac
else
  printf '\n' >&2
  printf 'Next: run ./setup-env.sh to configure credentials and verify with doctor.\n' >&2
fi
