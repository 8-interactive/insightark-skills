#!/bin/bash

S8_INSTALL_CONFIG_FILENAME='.insightark.config'
S8_ENV_FILENAME='.insightark.env'

s8_install_config_path() {
  printf '%s/%s' "${HOME:-}" "$S8_INSTALL_CONFIG_FILENAME"
}

s8_install_config_present() {
  [ -f "$(s8_install_config_path)" ]
}

s8_read_install_config_value() {
  local key="$1"
  local config_path line

  config_path="$(s8_install_config_path)"
  [ -f "$config_path" ] || return 1
  line="$(grep -E "^${key}=" "$config_path" | tail -1 || true)"
  [ -n "$line" ] || return 1
  printf '%s' "${line#*=}"
}

s8_install_skills_targets() {
  local csv target
  local -a targets=()

  csv="$(s8_read_install_config_value skills_targets)" || return 1
  csv="$(printf '%s' "$csv" | tr -d '[:space:]')"
  [ -n "$csv" ] || return 0

  IFS=',' read -r -a targets <<<"$csv"
  for target in "${targets[@]}"; do
    target="$(printf '%s' "$target" | tr -d '[:space:]')"
    [ -n "$target" ] || continue
    printf '%s\n' "$target"
  done
}

super8_write_install_config() {
  local layout="$1"
  local base_dir="${2:-}"
  local agents_csv="${3:-}"
  local config_path tmp targets_line target

  shift 3 || true
  local -a targets=("$@")

  if [ "${#targets[@]}" -eq 0 ]; then
    printf 'No install targets to record in config.\n' >&2
    return 1
  fi

  targets_line=''
  for target in "${targets[@]}"; do
    [ -n "$target" ] || continue
    if [ -n "$targets_line" ]; then
      targets_line="${targets_line},${target}"
    else
      targets_line="$target"
    fi
  done

  config_path="$(s8_install_config_path)"
  tmp="$(mktemp)"
  {
    printf '%s\n' '# Super 8 Studio install registry (managed by install.sh)'
    printf 'layout=%s\n' "$layout"
    printf 'base_dir=%s\n' "$base_dir"
    printf 'agents=%s\n' "$agents_csv"
    printf 'skills_targets=%s\n' "$targets_line"
    printf 'installed_at=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date)"
  } >"$tmp"
  mv "$tmp" "$config_path"
  chmod 600 "$config_path"
}

super8_remove_install_config() {
  local config_path
  config_path="$(s8_install_config_path)"
  [ -f "$config_path" ] || return 0
  rm -f "$config_path"
}
