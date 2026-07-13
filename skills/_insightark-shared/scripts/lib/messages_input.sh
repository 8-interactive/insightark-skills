#!/bin/bash
# Shared hybrid message input resolution for InsightArk skills.
#
# Caller sets input variables, then calls s8_resolve_messages_input:
#   _s8_mi_messages_file     — path to JSON file (--messages-file)
#   _s8_mi_use_stdin_payload   — "true" when --payload -
#   _s8_mi_quick_reply_file    — optional path (--quick-reply-file)
#   _s8_mi_texts, _s8_mi_images, _s8_mi_videos, _s8_mi_files — typed flag arrays
#   _s8_mi_order               — entries like text:0, image:1 in CLI order
#
# Outputs:
#   messages_json    — JSON array of outbound messages
#   quick_reply_json — JSON quickReply value or the literal string "null"
#
# Caller may also set texts/images/videos/files/order typed-flag arrays, then call
# s8_mi_bind_typed_arrays before s8_resolve_messages_input.

s8_mi_bind_typed_arrays() {
	_s8_mi_texts=()
	_s8_mi_images=()
	_s8_mi_videos=()
	_s8_mi_files=()
	_s8_mi_order=()
	# Bash 3.2 + set -u treats "${arr[@]}" on empty arrays as unbound; copy only when non-empty.
	if [ "${#texts[@]}" -gt 0 ]; then _s8_mi_texts=("${texts[@]}"); fi
	if [ "${#images[@]}" -gt 0 ]; then _s8_mi_images=("${images[@]}"); fi
	if [ "${#videos[@]}" -gt 0 ]; then _s8_mi_videos=("${videos[@]}"); fi
	if [ "${#files[@]}" -gt 0 ]; then _s8_mi_files=("${files[@]}"); fi
	if [ "${#order[@]}" -gt 0 ]; then _s8_mi_order=("${order[@]}"); fi
}

s8_mi_validate_messages_array() {
	local json="$1"
	local count
	count="$(jq -r 'if type == "array" then length else "invalid" end' <<<"$json")"
	if [ "$count" = "invalid" ] || [ "$count" -eq 0 ]; then
		printf 'Message input must contain a non-empty messages array.\n' >&2
		return 1
	fi
}

s8_mi_read_quick_reply_file() {
	local path="$1"
	local raw
	if [ ! -f "$path" ]; then
		printf '%s does not exist.\n' "$path" >&2
		return 1
	fi
	raw="$(cat "$path")"
	if [ -z "$raw" ]; then
		printf 'quick-reply-file must not be empty.\n' >&2
		return 1
	fi
	jq -ec 'if type == "array" then . elif (.quickReply | type) == "array" then .quickReply else empty end' <<<"$raw" || {
		printf 'quick-reply-file must be a JSON array or an object with a quickReply array.\n' >&2
		return 1
	}
}

s8_mi_build_from_typed_flags() {
	local messages_json_local="[]"
	local entry kind index value message

	if [ "${#_s8_mi_order[@]}" -eq 0 ]; then
		messages_json="[]"
		quick_reply_json="null"
		return 0
	fi

	for entry in "${_s8_mi_order[@]}"; do
		kind="${entry%%:*}"
		index="${entry##*:}"
		case "$kind" in
			text)
				value="${_s8_mi_texts[$index]}"
				message="$(jq -nc --arg content "$value" '{contentType: "text/plain", data: {content: $content}}')"
				;;
			image)
				value="${_s8_mi_images[$index]}"
				message="$(jq -nc --arg url "$value" '{contentType: "application/x-image", data: {url: $url}}')"
				;;
			video)
				value="${_s8_mi_videos[$index]}"
				message="$(jq -nc --arg url "$value" '{contentType: "application/x-video", data: {url: $url}}')"
				;;
			file)
				value="${_s8_mi_files[$index]}"
				message="$(jq -nc --arg url "$value" '{contentType: "application/x-file", data: {url: $url}}')"
				;;
			*)
				printf 'Internal error: unknown message kind %s\n' "$kind" >&2
				return 1
				;;
		esac
		messages_json_local="$(jq -nc --argjson list "$messages_json_local" --argjson item "$message" '$list + [$item]')"
	done

	messages_json="$messages_json_local"
	quick_reply_json="null"
}

s8_resolve_messages_input() {
	local payload_json=""

	messages_json=""
	quick_reply_json="null"

	if [ -n "${_s8_mi_messages_file:-}" ]; then
		if [ ! -f "$_s8_mi_messages_file" ]; then
			printf '%s does not exist.\n' "$_s8_mi_messages_file" >&2
			return 1
		fi
		payload_json="$(cat "$_s8_mi_messages_file")"
	elif [ "${_s8_mi_use_stdin_payload:-}" = "true" ]; then
		payload_json="$(cat)"
		if [ -z "$payload_json" ]; then
			printf 'Stdin payload is empty; supply JSON with a non-empty messages array.\n' >&2
			return 1
		fi
	else
		if [ "${#_s8_mi_order[@]}" -eq 0 ]; then
			printf 'Provide message input: --messages-file, --payload -, or at least one --text, --image, --video, or --file flag.\n' >&2
			return 1
		fi
		s8_mi_build_from_typed_flags || return 1
	fi

	if [ -n "$payload_json" ]; then
		if ! jq -e . >/dev/null 2>&1 <<<"$payload_json"; then
			printf 'Message payload is not valid JSON.\n' >&2
			return 1
		fi
		messages_json="$(jq -c '.messages // empty' <<<"$payload_json")"
		if [ -z "$messages_json" ]; then
			s8_mi_validate_messages_array "[]" || return 1
		fi
		s8_mi_validate_messages_array "$messages_json" || return 1
		quick_reply_json="$(jq -c '.quickReply // null' <<<"$payload_json")"
	fi

	if [ -n "${_s8_mi_quick_reply_file:-}" ]; then
		quick_reply_json="$(s8_mi_read_quick_reply_file "$_s8_mi_quick_reply_file")" || return 1
	fi

	export messages_json quick_reply_json
}
