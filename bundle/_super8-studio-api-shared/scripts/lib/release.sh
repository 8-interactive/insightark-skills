#!/bin/bash

# RELEASE is written at CI pack time (see .drone.yml). Not committed to git.

s8_release_file_path() {
  local lib_dir
  lib_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
  printf '%s/../../RELEASE' "$lib_dir"
}

s8_release_present() {
  [ -f "$(s8_release_file_path)" ]
}

s8_read_release_value() {
  local key="$1"
  local release_path line

  release_path="$(s8_release_file_path)"
  [ -f "$release_path" ] || return 1
  line="$(grep -E "^${key}=" "$release_path" | tail -1 || true)"
  [ -n "$line" ] || return 1
  printf '%s' "${line#*=}"
}

s8_release_channel_label() {
  local channel
  channel="$(s8_read_release_value channel 2>/dev/null || true)"
  case "$channel" in
    staging) printf 'Staging' ;;
    production) printf 'Production' ;;
    *) printf '%s' "$channel" ;;
  esac
}
