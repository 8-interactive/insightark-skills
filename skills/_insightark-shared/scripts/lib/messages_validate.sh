#!/bin/bash
# Tier 0 (bash) + Tier 1 (jq) local message payload checks.
# Full validation runs on the Developer API (preview / send / broadcast).

_lib_mv_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

s8_mv_tier0_file_checks() {
	local path="$1"
	if [ -z "$path" ] || [ ! -f "$path" ]; then
		printf '%s does not exist.\n' "${path:-<empty>}" >&2
		return 1
	fi
	if [ ! -s "$path" ]; then
		printf '%s is empty.\n' "$path" >&2
		return 1
	fi
	return 0
}

s8_mv_tier0_payload_size_check() {
	local path="$1"
	local max_bytes="${2:-}"
	if [ -z "$max_bytes" ]; then
		return 0
	fi
	local size
	size="$(wc -c <"$path" | tr -d ' ')"
	if [ "$size" -gt "$max_bytes" ]; then
		printf 'Payload exceeds %s bytes (got %s).\n' "$max_bytes" "$size" >&2
		return 1
	fi
	return 0
}

s8_mv_tier1_jq_checks() {
	local json="$1"
	local platform="${2:-}"
	local max_messages="${3:-}"
	local jq_bin="${4:-jq}"

	local errors
	local jq_errors
	jq_errors="$(
		"$jq_bin" -r -f "$_lib_mv_dir/messages_validate.jq" \
			--arg platform_arg "$platform" \
			--arg max_messages "$max_messages" \
			<<<"$json"
	)" || {
		printf 'Local message validation failed (jq error).\n' >&2
		return 1
	}

	errors="$("$jq_bin" -r '.[] | "\(.path): \(.message)"' <<<"$jq_errors")"

	if [ -n "$errors" ]; then
		printf '%s\n' "$errors" >&2
		return 1
	fi
	return 0
}

# Validate a messages payload (object with messages + optional quickReply/platform).
# Options via flags:
#   --file PATH
#   --json STRING
#   --platform line|facebook|instagram|whatsapp (optional; falls back to .platform in JSON, then line)
#   --max-messages N (optional)
#   --max-payload-bytes N (optional; file mode only)
#   --skip-validate
s8_run_messages_validate() {
	local file=""
	local json=""
	local platform=""
	local max_messages=""
	local max_payload_bytes=""
	local skip_validate="false"

	while [ "$#" -gt 0 ]; do
		case "$1" in
			--file) file="${2:-}"; shift 2 ;;
			--json) json="${2:-}"; shift 2 ;;
			--platform) platform="${2:-}"; shift 2 ;;
			--max-messages) max_messages="${2:-}"; shift 2 ;;
			--max-payload-bytes) max_payload_bytes="${2:-}"; shift 2 ;;
			--skip-validate) skip_validate="true"; shift ;;
			*) printf 'Unknown messages_validate option: %s\n' "$1" >&2; return 1 ;;
		esac
	done

	if [ "$skip_validate" = "true" ]; then
		return 0
	fi

	if [ -n "$file" ] && [ -n "$json" ]; then
		printf 'Provide only one of --file or --json.\n' >&2
		return 1
	fi

	if [ -z "$file" ] && [ -z "$json" ]; then
		printf 'Provide --file or --json for message validation.\n' >&2
		return 1
	fi

	if [ -n "$file" ]; then
		s8_mv_tier0_file_checks "$file" || return 1
		s8_mv_tier0_payload_size_check "$file" "$max_payload_bytes" || return 1
		json="$(cat "$file")"
	fi

	if [ -z "$json" ]; then
		printf 'Message payload is empty.\n' >&2
		return 1
	fi

	if ! command -v jq >/dev/null 2>&1; then
		printf 'Warning: jq not found; skipping structural message checks. Install jq and run doctor.sh. Full validation runs on API call.\n' >&2
		return 0
	fi

	if ! jq -e . >/dev/null 2>&1 <<<"$json"; then
		printf 'Message payload is not valid JSON.\n' >&2
		return 1
	fi

	if [ -z "$platform" ]; then
		platform="$(jq -r '.platform // empty' <<<"$json")"
	fi

	if ! s8_mv_tier1_jq_checks "$json" "$platform" "$max_messages" jq; then
		return 1
	fi

	printf 'Local message checks passed. Full validation runs on API call.\n'
	return 0
}
