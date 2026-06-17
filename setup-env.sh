#!/bin/bash

set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
env_lib="$script_dir/bundle/_super8-studio-api-shared/scripts/lib/env.sh"
install_config_lib="$script_dir/bundle/_super8-studio-api-shared/scripts/lib/install-config.sh"
release_lib="$script_dir/bundle/_super8-studio-api-shared/scripts/lib/release.sh"
doctor_script="$script_dir/bundle/_super8-studio-api-shared/scripts/doctor.sh"
example_file="$script_dir/.super8-studio.env.example"

source "$script_dir/installer/common.sh"
source "$install_config_lib"
source "$release_lib"

mode="user"
check_only="false"
env_hints_only="false"
no_open_browser="false"
console_url_override=""
api_url_override=""
project_path=""

super8_setup_print_usage() {
  cat <<EOF
Usage: ./setup-env.sh [options]

With no options, runs the interactive credential wizard (default).

Options:
  --check             Validate existing credentials (doctor)
  --env-hints         Print shell export instructions only
  --repo-only         Write project override file only (advanced)
  --project-path PATH Project root for --repo-only
  --user-only         Same as no options (interactive wizard)
  --no-open-browser   Do not open Console when creating a token
  --api-url URL       Override API base URL (local dev / cross-environment testing)
  --console-url URL   Override Console base URL
  --help              Show this help message
EOF
}

super8_print_setup_wizard_intro() {
  printf 'Super 8 Studio API — credential setup\n\n' >&2
  printf 'Connect your Super 8 account so skills can call the API.\n' >&2
  if ! s8_install_config_present; then
    printf 'Tip: run ./install.sh first if you have not installed skills yet.\n' >&2
  fi
  printf '\n' >&2
  printf 'For non-interactive / advanced options: ./setup-env.sh --help\n\n' >&2
}

super8_collect_env_targets() {
  local -a targets=()
  local skills_target user_path

  if s8_install_config_present; then
    while IFS= read -r skills_target; do
      [ -n "$skills_target" ] || continue
      targets+=("${skills_target%/}/.super8-studio.env")
    done < <(s8_install_skills_targets)
  fi

  if [ "${#targets[@]}" -eq 0 ]; then
    user_path="$(s8_user_env_path)"
    targets+=("$user_path")
  fi

  printf '%s\n' "${targets[@]}"
}

super8_write_env_to_targets() {
  local api_url="$1"
  local session_token="$2"
  local org_id="${3:-}"
  local target

  while IFS= read -r target; do
    [ -n "$target" ] || continue
    super8_ensure_directory "$(dirname "$target")"
    super8_write_env_file "$target" "$api_url" "$session_token" "$org_id"
    printf 'Wrote %s (mode 600)\n' "$(super8_format_display_path "$target")"
  done < <(super8_collect_env_targets)
}

super8_resolve_api_url() {
  local api_url channel_label

  if [ -n "$api_url_override" ]; then
    printf '%s' "$api_url_override"
    return 0
  fi

  if s8_release_present; then
    api_url="$(s8_read_release_value api_url)" || true
    if [ -n "$api_url" ]; then
      channel_label="$(s8_release_channel_label)"
      printf 'API environment: %s (%s)\n' "$channel_label" "$api_url" >&2
      printf '\n' >&2
      printf '%s' "$api_url"
      return 0
    fi
  fi

  super8_prompt_api_url
}

super8_resolve_console_url() {
  local api_url="$1"
  local console_url

  if [ -n "$console_url_override" ]; then
    printf '%s' "$console_url_override"
    return 0
  fi

  if s8_release_present; then
    console_url="$(s8_read_release_value console_url)" || true
    if [ -n "$console_url" ]; then
      printf '%s' "$console_url"
      return 0
    fi
  fi

  super8_console_base_for_api_url "$api_url"
}

super8_prompt_api_url() {
  local choice api_url
  printf 'Select API environment (local / git checkout):\n' >&2
  printf '  1) Production  https://api-next.no8.io\n' >&2
  printf '  2) Staging     https://stage-api-next.no8.io\n' >&2
  printf '  3) Custom URL\n' >&2
  printf 'Choice [1]: ' >&2
  read -r choice
  case "${choice:-1}" in
    1 | prod | production) api_url='https://api-next.no8.io' ;;
    2 | stag | stage | staging) api_url='https://stage-api-next.no8.io' ;;
    3 | custom)
      printf 'API base URL: ' >&2
      read -r api_url
      ;;
    *)
      printf 'Unknown choice.\n' >&2
      return 1
      ;;
  esac
  if [ -z "$api_url" ]; then
    printf 'API URL is required.\n' >&2
    return 1
  fi
  printf '%s' "$api_url"
}

super8_prompt_session_token() {
  local api_url="$1"
  local console_base token_url

  console_base="$(super8_resolve_console_url "$api_url")"

  if [ -n "$console_base" ] && [ "$no_open_browser" = "false" ]; then
    token_url="$(super8_build_console_token_url "$console_base")"
    printf '\nOpening Super 8 Console to create a Developer API token...\n' >&2
    printf '%s\n\n' "$token_url" >&2
    super8_open_url "$token_url"
    printf 'Copy the token from the one-time modal, then paste it below.\n' >&2
  else
    printf 'In Super 8 Console: Account Settings → Developer API → Create token.\n' >&2
  fi

  printf 'Paste S8_SESSION_TOKEN: ' >&2
  read -r -s token
  printf '\n' >&2
  if [ -z "$token" ]; then
    printf 'Session token is required.\n' >&2
    return 1
  fi
  printf '%s' "$token"
}

super8_fetch_eligible_orgs() {
  local api_url="${1%/}"
  local token="$2"
  local response_file status_file status

  s8_require_command curl
  s8_require_command jq

  response_file="$(mktemp)"
  status_file="$(mktemp)"
  trap 'rm -f "$response_file" "$status_file"' RETURN

  status="$(
    curl -sS -o "$response_file" -w '%{http_code}' \
      -H 'Accept: application/json' \
      -H "_SessionToken: ${token}" \
      "${api_url}/developer/v1/auth/organizations"
  )"

  if [ "$status" != "200" ]; then
    printf 'Failed to list organizations (HTTP %s).\n' "$status" >&2
    jq '.' "$response_file" >&2 2>/dev/null || cat "$response_file" >&2
    return 1
  fi

  jq -c '[.data.organizations[] | select(.developerApiEnabled == true)]' "$response_file"
}

super8_prompt_org_id_from_api() {
  local api_url="$1"
  local token="$2"
  local orgs_json count choice idx org_id display_name
  local -a org_ids=()
  local -a org_names=()

  orgs_json="$(super8_fetch_eligible_orgs "$api_url" "$token")"
  count="$(printf '%s' "$orgs_json" | jq 'length')"

  if [ "$count" -eq 0 ]; then
    printf 'No organizations with Developer API enabled for this account.\n' >&2
    printf 'Enable Developer API in Console organization settings, then retry.\n' >&2
    return 1
  fi

  if [ "$count" -eq 1 ]; then
    org_id="$(printf '%s' "$orgs_json" | jq -r '.[0].id')"
    display_name="$(printf '%s' "$orgs_json" | jq -r '.[0].displayName // .[0].id')"
    printf 'Using organization: %s (%s)\n' "$display_name" "$org_id" >&2
    printf '%s' "$org_id"
    return 0
  fi

  printf '\nSelect organization (Developer API enabled):\n' >&2
  idx=1
  while IFS=$'\t' read -r org_id display_name; do
    org_ids+=("$org_id")
    org_names+=("$display_name")
    printf '  %s) %s (%s)\n' "$idx" "$display_name" "$org_id" >&2
    idx=$((idx + 1))
  done < <(printf '%s' "$orgs_json" | jq -r '.[] | [.id, (.displayName // .id)] | @tsv')

  printf 'Choice: ' >&2
  read -r choice
  if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt "$count" ]; then
    printf 'Invalid choice.\n' >&2
    return 1
  fi

  printf '%s' "${org_ids[$((choice - 1))]}"
}

super8_write_env_file() {
  local target_path="$1"
  local api_url="$2"
  local session_token="$3"
  local org_id="${4:-}"
  local tmp_file

  tmp_file="$(mktemp)"
  {
    printf '%s=%q\n' 'S8_API_URL' "$api_url"
    printf '%s=%q\n' 'S8_SESSION_TOKEN' "$session_token"
    if [ -n "$org_id" ]; then
      printf '%s=%q\n' 'S8_ORG_ID' "$org_id"
    fi
  } >"$tmp_file"
  mv "$tmp_file" "$target_path"
  chmod 600 "$target_path"
}

super8_write_repo_env_file() {
  local target_path="$1"
  local api_url="${2:-}"
  local org_id="${3:-}"
  local tmp_file

  tmp_file="$(mktemp)"
  : >"$tmp_file"
  if [ -n "$api_url" ]; then
    printf '%s=%q\n' 'S8_API_URL' "$api_url" >>"$tmp_file"
  fi
  if [ -n "$org_id" ]; then
    printf '%s=%q\n' 'S8_ORG_ID' "$org_id" >>"$tmp_file"
  fi
  if [ ! -s "$tmp_file" ]; then
    rm -f "$tmp_file"
    printf 'Nothing to write. Provide at least S8_ORG_ID or S8_API_URL for project config.\n' >&2
    return 1
  fi
  mv "$tmp_file" "$target_path"
  chmod 600 "$target_path"
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --user-only) mode="user"; shift ;;
    --repo-only) mode="repo"; shift ;;
    --project-path)
      project_path="${2:-}"
      shift 2
      ;;
    --check) check_only="true"; shift ;;
    --env-hints) env_hints_only="true"; shift ;;
    --no-open-browser) no_open_browser="true"; shift ;;
    --api-url)
      api_url_override="${2:-}"
      shift 2
      ;;
    --console-url)
      console_url_override="${2:-}"
      shift 2
      ;;
    --help)
      super8_setup_print_usage
      exit 0
      ;;
    *)
      printf 'Unknown option: %s\n' "$1" >&2
      super8_setup_print_usage
      exit 1
      ;;
  esac
done

if [ ! -f "$env_lib" ]; then
  printf 'Missing env library: %s\n' "$env_lib" >&2
  exit 1
fi

# shellcheck source=bundle/_super8-studio-api-shared/scripts/lib/env.sh
source "$env_lib"

if [ "$env_hints_only" = "true" ]; then
  s8_print_process_env_instructions
  exit 0
fi

if [ "$check_only" = "true" ]; then
  if ! s8_load_runtime_env; then
    exit 1
  fi
  bash "$doctor_script"
  exit 0
fi

if [ "$mode" = "user" ]; then
  super8_print_setup_wizard_intro

  existing_target=""
  while IFS= read -r target; do
    [ -n "$target" ] || continue
    if [ -f "$target" ]; then
      existing_target="$target"
      break
    fi
  done < <(super8_collect_env_targets)

  if [ -n "$existing_target" ]; then
    printf 'Credential file already exists: %s\n' "$(super8_format_display_path "$existing_target")" >&2
    printf 'Overwrite? [y/N]: ' >&2
    read -r confirm
    case "$confirm" in
      y | Y | yes | YES) ;;
      *)
        printf 'Aborted.\n' >&2
        exit 0
        ;;
    esac
  fi

  api_url="$(super8_resolve_api_url)"
  session_token="$(super8_prompt_session_token "$api_url")"
  org_id="$(super8_prompt_org_id_from_api "$api_url" "$session_token")"
  printf '\n' >&2
  super8_write_env_to_targets "$api_url" "$session_token" "$org_id"
elif [ "$mode" = "repo" ]; then
  if [ -z "$project_path" ]; then
    printf 'Project path for .super8-studio.env: ' >&2
    read -r project_path
  fi
  project_path="$(super8_expand_base_dir "$project_path")"
  target="${project_path%/}/.super8-studio.env"
  if [ -f "$target" ]; then
    printf 'File already exists: %s\n' "$target" >&2
    printf 'Overwrite? [y/N]: ' >&2
    read -r confirm
    case "$confirm" in
      y | Y | yes | YES) ;;
      *)
        printf 'Aborted.\n' >&2
        exit 0
        ;;
    esac
  fi
  printf 'Project config usually overrides org or stage API URL. Leave blank to skip.\n' >&2
  printf 'S8_API_URL override (optional): ' >&2
  read -r api_url
  printf 'S8_ORG_ID: ' >&2
  read -r org_id
  super8_ensure_directory "$project_path"
  super8_write_repo_env_file "$target" "$api_url" "$org_id"
  printf 'Wrote %s (mode 600). Add this file to .gitignore.\n' "$target"
fi

if [ -f "$doctor_script" ]; then
  printf '\nRunning doctor...\n'
  export S8_API_URL="${S8_API_URL:-}"
  if bash "$doctor_script"; then
    printf 'Setup complete.\n'
  else
    printf 'Config written but doctor failed. Check token and API URL.\n' >&2
    exit 1
  fi
fi
