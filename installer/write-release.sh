#!/bin/bash

set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
release_file="$script_dir/../skills/_super8-studio-api-shared/RELEASE"
branch="${DRONE_BRANCH:-}"

case "$branch" in
  staging)
    printf '%s\n' \
      'channel=staging' \
      'api_url=https://stage-api-next.no8.io' \
      'console_url=https://stage-console.no8.io' \
      'built_from_branch=staging' >"$release_file"
    ;;
  main)
    printf '%s\n' \
      'channel=production' \
      'api_url=https://api-next.no8.io' \
      'console_url=https://console.no8.io' \
      'built_from_branch=main' >"$release_file"
    ;;
  *)
    printf 'Unsupported branch for skills release: %s\n' "$branch" >&2
    exit 1
    ;;
esac

printf 'Wrote %s for branch %s\n' "$release_file" "$branch" >&2
