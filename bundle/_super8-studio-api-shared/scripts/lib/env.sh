#!/bin/bash

S8_ENV_FILENAME='.super8-studio.env'

_lib_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=install-config.sh
. "$_lib_dir/install-config.sh"

s8_require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    printf 'Missing required command: %s\n' "$1" >&2
    return 1
  fi
}

s8_user_env_path() {
  printf '%s/%s' "${HOME:-}" "$S8_ENV_FILENAME"
}

s8_repo_env_path() {
  printf './%s' "$S8_ENV_FILENAME"
}

s8_load_env_file_if_present() {
  local path="$1"
  if [ ! -f "$path" ]; then
    return 1
  fi
  set -a
  # shellcheck disable=SC1090
  . "$path"
  set +a
  return 0
}

s8_load_env_files() {
  local user_path repo_path
  local preserve_api=0 preserve_token=0 preserve_org=0
  local saved_api saved_token saved_org

  user_path="$(s8_user_env_path)"
  repo_path="$(s8_repo_env_path)"

  if [ -n "${S8_API_URL:-}" ]; then
    preserve_api=1
    saved_api="$S8_API_URL"
  fi
  if [ -n "${S8_SESSION_TOKEN:-}" ]; then
    preserve_token=1
    saved_token="$S8_SESSION_TOKEN"
  fi
  if [ -n "${S8_ORG_ID:-}" ]; then
    preserve_org=1
    saved_org="$S8_ORG_ID"
  fi

  S8_ENV_USER_FOUND=0
  S8_ENV_REPO_FOUND=0
  S8_ENV_SKILLS_FOUND=0

  if s8_load_env_file_if_present "$user_path"; then
    S8_ENV_USER_FOUND=1
  fi

  if s8_install_config_present; then
    local skills_target skills_env_path
    while IFS= read -r skills_target; do
      [ -n "$skills_target" ] || continue
      skills_env_path="${skills_target%/}/$S8_ENV_FILENAME"
      if s8_load_env_file_if_present "$skills_env_path"; then
        S8_ENV_SKILLS_FOUND=1
      fi
    done < <(s8_install_skills_targets 2>/dev/null || true)
  fi

  if s8_load_env_file_if_present "$repo_path"; then
    S8_ENV_REPO_FOUND=1
  fi

  if [ "$preserve_api" -eq 1 ]; then
    export S8_API_URL="$saved_api"
  fi
  if [ "$preserve_token" -eq 1 ]; then
    export S8_SESSION_TOKEN="$saved_token"
  fi
  if [ "$preserve_org" -eq 1 ]; then
    export S8_ORG_ID="$saved_org"
  fi

  export S8_ENV_USER_PATH="$user_path"
  export S8_ENV_REPO_PATH="$repo_path"
}

s8_print_missing_credentials_help() {
  local user_path repo_path
  user_path="$(s8_user_env_path)"
  repo_path="$(s8_repo_env_path)"

  printf 'Missing Super 8 Studio API credentials.\n\n' >&2
  printf 'Priority (highest first): process environment > %s > skills install dir > %s\n\n' "$repo_path" "$user_path" >&2
  printf 'Checked:\n' >&2
  if [ "${S8_ENV_SKILLS_FOUND:-0}" = 1 ]; then
    printf '  - {skills-target}/%s from %s (loaded)\n' "$S8_ENV_FILENAME" "$(s8_install_config_path)" >&2
  elif s8_install_config_present; then
    printf '  - {skills-target}/%s from %s (not found)\n' "$S8_ENV_FILENAME" "$(s8_install_config_path)" >&2
  fi
  if [ "${S8_ENV_USER_FOUND:-0}" = 1 ]; then
    printf '  - %s (loaded)\n' "$user_path" >&2
  else
    printf '  - %s (not found)\n' "$user_path" >&2
  fi
  if [ "${S8_ENV_REPO_FOUND:-0}" = 1 ]; then
    printf '  - %s (loaded)\n' "$repo_path" >&2
  else
    printf '  - %s (not found)\n' "$repo_path" >&2
  fi
  if [ -n "${S8_API_URL+x}" ] || [ -n "${S8_SESSION_TOKEN+x}" ]; then
    printf '  - process environment (partially set)\n' >&2
  else
    printf '  - process environment (S8_API_URL / S8_SESSION_TOKEN not set)\n' >&2
  fi
  printf '\nRun: ./setup-env.sh\n' >&2
  printf 'Or create %s — see .super8-studio.env.example\n' "$user_path" >&2
  printf '\n' >&2
  s8_print_process_env_instructions >&2
}

s8_detect_shell_rc_file() {
  local shell_name
  shell_name="$(basename "${SHELL:-}")"
  case "$shell_name" in
    zsh)
      printf '%s\n' "${HOME:-}/.zshrc"
      ;;
    bash)
      if [ -f "${HOME:-}/.bashrc" ]; then
        printf '%s\n' "${HOME:-}/.bashrc"
      elif [ -f "${HOME:-}/.bash_profile" ]; then
        printf '%s\n' "${HOME:-}/.bash_profile"
      else
        printf '%s\n' "${HOME:-}/.bashrc"
      fi
      ;;
    fish)
      printf '%s\n' "${HOME:-}/.config/fish/config.fish"
      ;;
    *)
      if [ -f "${HOME:-}/.profile" ]; then
        printf '%s\n' "${HOME:-}/.profile"
      else
        printf '%s\n' "${HOME:-}/.profile"
      fi
      ;;
  esac
}

s8_print_process_env_instructions() {
  local rc_file shell_name
  rc_file="$(s8_detect_shell_rc_file)"
  shell_name="$(basename "${SHELL:-sh}")"

  printf 'Alternative: process environment (highest priority — overrides config files)\n'
  printf 'Detected shell: %s (from $SHELL)\n' "$shell_name"
  printf 'Suggested profile file: %s\n\n' "$rc_file"

  case "$shell_name" in
    fish)
      printf 'Add to %s:\n' "$rc_file"
      printf "  set -gx S8_API_URL 'https://api-next.no8.io'\n"
      printf "  set -gx S8_SESSION_TOKEN 'r:your-token'\n"
      printf "  set -gx S8_ORG_ID 'your-org-id'  # optional\n\n"
      printf 'Then run: source %s\n' "$rc_file"
      ;;
    *)
      printf 'Add to %s:\n' "$rc_file"
      printf "  export S8_API_URL='https://api-next.no8.io'\n"
      printf "  export S8_SESSION_TOKEN='r:your-token'\n"
      printf "  export S8_ORG_ID='your-org-id'  # optional\n\n"
      printf 'Then run: source %s\n' "$rc_file"
      printf 'Or for the current terminal session only:\n'
      printf "  export S8_API_URL='https://api-next.no8.io'\n"
      printf "  export S8_SESSION_TOKEN='r:your-token'\n"
      ;;
  esac

  printf '\nNote: some agent sandboxes do not inherit shell exports. Prefer ~/.super8-studio.env for agents.\n'
}

s8_load_runtime_env() {
  s8_load_env_files

  if [ -z "${S8_API_URL:-}" ] || [ -z "${S8_SESSION_TOKEN:-}" ]; then
    s8_print_missing_credentials_help
    return 1
  fi

  S8_API_ROOT="${S8_API_URL%/}"
  export S8_API_ROOT
}

s8_resolve_org_id() {
  local explicit_org_id="${1:-}"
  if [ -n "$explicit_org_id" ]; then
    printf '%s\n' "$explicit_org_id"
    return 0
  fi
  if [ -n "${S8_ORG_ID:-}" ]; then
    printf '%s\n' "$S8_ORG_ID"
    return 0
  fi

  printf 'Missing organization context. Provide --org-id or set S8_ORG_ID in %s or %s.\n' "$(s8_repo_env_path)" "$(s8_user_env_path)" >&2
  return 1
}

s8_query_pair() {
  local key="$1"
  local value="$2"
  local encoded

  encoded="$(jq -rn --arg value "$value" '$value|@uri')"
  printf '%s=%s\n' "$key" "$encoded"
}

s8_iso_now() {
  date -u +%Y-%m-%dT%H:%M:%SZ
}

# Prints an ISO-8601 UTC timestamp N days before now (macOS and GNU date).
s8_iso_days_ago() {
  local days="${1:-90}"
  if date -u -v-"${days}"d +%Y-%m-%dT%H:%M:%SZ >/dev/null 2>&1; then
    date -u -v-"${days}"d +%Y-%m-%dT%H:%M:%SZ
  else
    date -u -d "${days} days ago" +%Y-%m-%dT%H:%M:%SZ
  fi
}
