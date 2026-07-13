#!/bin/bash

set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
source "$script_dir/lib/env.sh"
source "$script_dir/lib/http.sh"
source "$script_dir/lib/output.sh"
source "$script_dir/lib/messages_input.sh"
source "$script_dir/lib/messages_validate.sh"

org_id=""
platform=""
where_file=""
schedule_at=""
inbox_to_done="false"
message_tag=""
wa_template_id=""
messages_file=""
use_stdin_payload="false"
quick_reply_file=""
skip_validate="false"

customer_ids=()
texts=()
images=()
videos=()
files=()
order=()

while [ "$#" -gt 0 ]; do
  case "$1" in
    --org-id) org_id="${2:-}"; shift 2 ;;
    --platform) platform="${2:-}"; shift 2 ;;
    --customer-id) customer_ids+=("${2:-}"); shift 2 ;;
    --where-file) where_file="${2:-}"; shift 2 ;;
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
    --schedule-at) schedule_at="${2:-}"; shift 2 ;;
    --inbox-to-done) inbox_to_done="true"; shift ;;
    --message-tag) message_tag="${2:-}"; shift 2 ;;
    --wa-template-id) wa_template_id="${2:-}"; shift 2 ;;
    --skip-validate) skip_validate="true"; shift ;;
    *) printf 'Unknown option: %s\n' "$1" >&2; exit 1 ;;
  esac
done

if [ -z "$platform" ]; then
  printf 'Provide --platform (one of line, facebook, instagram, whatsapp).\n' >&2
  exit 1
fi

case "$platform" in
  line|facebook|instagram|whatsapp) ;;
  *) printf -- '--platform must be one of line, facebook, instagram, whatsapp (got: %s).\n' "$platform" >&2; exit 1 ;;
esac

if [ "${#customer_ids[@]}" -eq 0 ] && [ -z "$where_file" ]; then
  printf 'Provide at least one --customer-id OR --where-file.\n' >&2
  exit 1
fi

if [ "${#customer_ids[@]}" -gt 0 ] && [ -n "$where_file" ]; then
  printf '--customer-id and --where-file are mutually exclusive.\n' >&2
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
    s8_run_messages_validate --file "$messages_file" --platform "$platform"
  else
    payload_json="$(jq -nc --argjson messages "$messages_json" --argjson quickReply "$quick_reply_json" --arg platform "$platform" '
      {messages, platform}
      + (if $quickReply == null then {} else {quickReply: $quickReply} end)
    ')"
    s8_run_messages_validate --json "$payload_json" --platform "$platform"
  fi
fi

s8_load_runtime_env
org_id="$(s8_resolve_org_id "$org_id")"

if [ "${#customer_ids[@]}" -gt 0 ]; then
  ids_json="$(printf '%s\n' "${customer_ids[@]}" | jq -R . | jq -s .)"
  recipients_json="$(jq -nc --argjson customerIds "$ids_json" '{customerIds: $customerIds}')"
else
  if [ ! -f "$where_file" ]; then
    printf '%s does not exist.\n' "$where_file" >&2
    exit 1
  fi
  where_json="$(cat "$where_file")"
  recipients_json="$(jq -nc --argjson where "$where_json" '{where: $where}')"
fi

body_args=( --arg orgId "$org_id" --arg platform "$platform" --argjson recipients "$recipients_json" --argjson messages "$messages_json" )
body_filter='{orgId: $orgId, platform: $platform, recipients: $recipients, messages: $messages}'

if [ "$quick_reply_json" != "null" ]; then
  body_args+=( --argjson quickReply "$quick_reply_json" )
  body_filter="$body_filter | . + {quickReply: \$quickReply}"
fi

if [ -n "$schedule_at" ]; then
  body_args+=( --arg scheduleAt "$schedule_at" )
  body_filter="$body_filter | . + {scheduleAt: \$scheduleAt}"
fi
if [ "$inbox_to_done" = "true" ]; then
  body_filter="$body_filter | . + {inboxToDone: true}"
fi
if [ -n "$message_tag" ]; then
  body_args+=( --arg messageTag "$message_tag" )
  body_filter="$body_filter | . + {messageTag: \$messageTag}"
fi
if [ -n "$wa_template_id" ]; then
  body_args+=( --arg waTemplateId "$wa_template_id" )
  body_filter="$body_filter | . + {waTemplateId: \$waTemplateId}"
fi

body="$(jq -nc "${body_args[@]}" "$body_filter")"

response_file="$(mktemp)"
status_file="$(mktemp)"
trap 'rm -f "$response_file" "$status_file"' EXIT

s8_api_request POST "/developer/v1/broadcasts" "$body" "$response_file" "$status_file"
s8_expect_success "$(<"$status_file")" "$response_file"
s8_print_json_file "$response_file"
