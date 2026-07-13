#!/bin/bash
# Optional follow-up registry writer for install paths that copy skill files
# without running install.sh (e.g. a marketplace or external skills manager
# that already placed `skills/` somewhere and exposes the resulting path).
#
# This does not copy any files — it only records the target directory in the
# install registry (~/.insightark.config) so setup-env.sh / uninstall.sh and
# skill runtime credential loading can find it. See
# docs/implementation/install-flow-contract.md.

set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
repo_dir="$(CDPATH= cd -- "$script_dir/.." && pwd)"

# shellcheck source=../installer/common.sh
source "$repo_dir/installer/common.sh"
# shellcheck source=../skills/_insightark-shared/scripts/lib/install-config.sh
source "$repo_dir/skills/_insightark-shared/scripts/lib/install-config.sh"

target_dir=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --target)
      target_dir="${2:-}"
      shift 2
      ;;
    --help)
      printf 'Usage: register-install.sh --target <skills-dir>\n'
      printf '\n'
      printf 'Records <skills-dir> in the install registry (~/.insightark.config)\n'
      printf 'without copying any files. Use this only after another tool has\n'
      printf 'already placed a copy of skills/ at <skills-dir>.\n'
      exit 0
      ;;
    *)
      printf 'Unknown option: %s\n' "$1" >&2
      printf 'Usage: register-install.sh --target <skills-dir>\n' >&2
      exit 1
      ;;
  esac
done

if [ -z "$target_dir" ]; then
  printf '--target is required.\n' >&2
  printf 'Usage: register-install.sh --target <skills-dir>\n' >&2
  exit 1
fi

expanded_target="$(super8_expand_base_dir "$target_dir")"

if [ ! -d "$expanded_target" ]; then
  printf 'Warning: %s does not exist yet.\n' "$expanded_target" >&2
fi

super8_write_install_config "direct" "" "" "$expanded_target"
printf 'Wrote install registry %s\n' "$(super8_format_display_path "$(s8_install_config_path)")" >&2
