#!/bin/bash

set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
source "$script_dir/lib/env.sh"
source "$script_dir/lib/http.sh"
source "$script_dir/lib/output.sh"
source "$script_dir/lib/messages_input.sh"
source "$script_dir/lib/messages_validate.sh"

org_id=""
customer_id=""
reply_token=""
inbox_to_done="false"
message_tag=""
wa_template_id=""
messages_file=""
use_stdin_payload="false"
quick_reply_file=""
skip_validate="false"

texts=()
images=()
videos=()
files=()
order=()

while [ "$#" -gt 0 ]; do
  case "$1" in
    --org-id) org_id="${2:-}"; shift 2 ;;
    --customer-id) customer_id="${2:-}"; shift 2 ;;
    --messages-file) messages_file="${2:-}"; shift 2 ;;
    --payload)
      if [ "${2:-}" != "-" ]; then
        printf 'Inline --payload JSON is not supported. Use --payload - with stdin or --messages-file PATH.\n' >&2
        exit 1
      fi
      use_stdin_payload="true"
      shift 2
      ;;
    --quick-reply-file) quick_reply_file="${2:-}"; shift 2 ;;
    --text) texts+=("${2:-}"); order+=("text:$((${#texts[@]} - 1))"); shift 2 ;;
    --image) images+=("${2:-}"); order+=("image:$((${#images[@]} - 1))"); shift 2 ;;
    --video) videos+=("${2:-}"); order+=("video:$((${#videos[@]} - 1))"); shift 2 ;;
    --file) files+=("${2:-}"); order+=("file:$((${#files[@]} - 1))"); shift 2 ;;
    --reply-token) reply_token="${2:-}"; shift 2 ;;
    --inbox-to-done) inbox_to_done="true"; shift ;;
    --message-tag) message_tag="${2:-}"; shift 2 ;;
    --wa-template-id) wa_template_id="${2:-}"; shift 2 ;;
    --skip-validate) skip_validate="true"; shift ;;
    *) printf 'Unknown option: %s\n' "$1" >&2; exit 1 ;;
  esac
done

if [ -z "$customer_id" ]; then
  printf 'Missing required option: --customer-id\n' >&2
  exit 1
fi

s8_require_command curl
s8_require_command jq

_s8_mi_messages_file="$messages_file"
_s8_mi_use_stdin_payload="$use_stdin_payload"
_s8_mi_quick_reply_file="$quick_reply_file"
s8_mi_bind_typed_arrays
s8_resolve_messages_input

if [ "$skip_validate" != "true" ]; then
  if [ -n "$messages_file" ]; then
    file_platform="$(jq -r '.platform // empty' <"$messages_file")"
    if [ -n "$file_platform" ]; then
      s8_run_messages_validate --file "$messages_file" --platform "$file_platform"
    else
      s8_run_messages_validate --file "$messages_file"
    fi
  else
    payload_json="$(jq -nc --argjson messages "$messages_json" --argjson quickReply "$quick_reply_json" '
      {messages}
      + (if $quickReply == null then {} else {quickReply: $quickReply} end)
    ')"
    s8_run_messages_validate --json "$payload_json"
  fi
fi

s8_load_runtime_env
org_id="$(s8_resolve_org_id "$org_id")"

if [ -z "$messages_file" ] && [ "$use_stdin_payload" != "true" ]; then
  if [ -n "$message_tag" ] || [ -n "$wa_template_id" ]; then
    updated_messages="[]"
    while IFS= read -r message; do
      item="$message"
      if [ -n "$message_tag" ]; then
        item="$(jq -nc --argjson msg "$item" --arg tag "$message_tag" '$msg + {messageTag: $tag}')"
      fi
      if [ -n "$wa_template_id" ]; then
        item="$(jq -nc --argjson msg "$item" --arg waTemplateId "$wa_template_id" '$msg + {waTemplateId: $waTemplateId}')"
      fi
      updated_messages="$(jq -nc --argjson list "$updated_messages" --argjson item "$item" '$list + [$item]')"
    done < <(jq -c '.[]' <<<"$messages_json")
    messages_json="$updated_messages"
  fi
fi

body_args=( --arg orgId "$org_id" --argjson messages "$messages_json" )
body_filter='{orgId: $orgId, messages: $messages}'

if [ "$quick_reply_json" != "null" ]; then
  body_args+=( --argjson quickReply "$quick_reply_json" )
  body_filter="$body_filter | . + {quickReply: \$quickReply}"
fi

if [ -n "$reply_token" ]; then
  body_args+=( --arg replyToken "$reply_token" )
  body_filter="$body_filter | . + {replyToken: \$replyToken}"
fi

if [ "$inbox_to_done" = "true" ]; then
  body_filter="$body_filter | . + {inboxToDone: true}"
fi

body="$(jq -nc "${body_args[@]}" "$body_filter")"

response_file="$(mktemp)"
status_file="$(mktemp)"
trap 'rm -f "$response_file" "$status_file"' EXIT

s8_api_request POST "/developer/v1/customers/${customer_id}/messages" "$body" "$response_file" "$status_file"
s8_expect_success "$(<"$status_file")" "$response_file"
s8_print_json_file "$response_file"
