#!/bin/bash

set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
# shellcheck source=lib/messages_validate.sh
source "$script_dir/lib/messages_validate.sh"

file=""
platform=""
max_messages=""
max_payload_bytes=""
skip_validate="false"

while [ "$#" -gt 0 ]; do
	case "$1" in
		--messages-file) file="${2:-}"; shift 2 ;;
		--platform) platform="${2:-}"; shift 2 ;;
		--max-messages) max_messages="${2:-}"; shift 2 ;;
		--max-payload-bytes) max_payload_bytes="${2:-}"; shift 2 ;;
		--skip-validate) skip_validate="true"; shift ;;
		*)
			printf 'Usage: %s --messages-file PATH [--platform line] [--max-messages N] [--max-payload-bytes N] [--skip-validate]\n' "$(basename "$0")" >&2
			exit 1
			;;
	esac
done

if [ -z "$file" ]; then
	printf 'Usage: %s --messages-file PATH [--platform line] [--max-messages N] [--max-payload-bytes N] [--skip-validate]\n' "$(basename "$0")" >&2
	exit 1
fi

args=(--file "$file")
[ -n "$platform" ] && args+=(--platform "$platform")
[ -n "$max_messages" ] && args+=(--max-messages "$max_messages")
[ -n "$max_payload_bytes" ] && args+=(--max-payload-bytes "$max_payload_bytes")
[ "$skip_validate" = "true" ] && args+=(--skip-validate)

s8_run_messages_validate "${args[@]}"
