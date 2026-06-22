#!/bin/bash

set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
source "$script_dir/lib/env.sh"
source "$script_dir/lib/http.sh"
source "$script_dir/lib/output.sh"

org_id=""
customer_id=""
reply_token=""
inbox_to_done="false"
message_tag=""
wa_template_id=""

texts=()
images=()
videos=()
order=()

while [ "$#" -gt 0 ]; do
  case "$1" in
    --org-id) org_id="${2:-}"; shift 2 ;;
    --customer-id) customer_id="${2:-}"; shift 2 ;;
    --text) texts+=("${2:-}"); order+=("text:$((${#texts[@]} - 1))"); shift 2 ;;
    --image) images+=("${2:-}"); order+=("image:$((${#images[@]} - 1))"); shift 2 ;;
    --video) videos+=("${2:-}"); order+=("video:$((${#videos[@]} - 1))"); shift 2 ;;
    --reply-token) reply_token="${2:-}"; shift 2 ;;
    --inbox-to-done) inbox_to_done="true"; shift ;;
    --message-tag) message_tag="${2:-}"; shift 2 ;;
    --wa-template-id) wa_template_id="${2:-}"; shift 2 ;;
    *) printf 'Unknown option: %s\n' "$1" >&2; exit 1 ;;
  esac
done

if [ -z "$customer_id" ]; then
  printf 'Missing required option: --customer-id\n' >&2
  exit 1
fi

if [ "${#order[@]}" -eq 0 ]; then
  printf 'Provide at least one --text, --image, or --video value.\n' >&2
  exit 1
fi

s8_require_command curl
s8_require_command jq
s8_load_runtime_env
org_id="$(s8_resolve_org_id "$org_id")"

messages_json="[]"
for entry in "${order[@]}"; do
  kind="${entry%%:*}"
  index="${entry##*:}"
  case "$kind" in
    text)
      value="${texts[$index]}"
      message="$(jq -nc --arg content "$value" '{contentType: "text/plain", data: {content: $content}}')"
      ;;
    image)
      value="${images[$index]}"
      message="$(jq -nc --arg url "$value" '{contentType: "application/x-image", data: {url: $url}}')"
      ;;
    video)
      value="${videos[$index]}"
      message="$(jq -nc --arg url "$value" '{contentType: "application/x-video", data: {url: $url}}')"
      ;;
  esac

  if [ -n "$message_tag" ]; then
    message="$(jq -nc --argjson msg "$message" --arg tag "$message_tag" '$msg + {messageTag: $tag}')"
  fi
  if [ -n "$wa_template_id" ]; then
    message="$(jq -nc --argjson msg "$message" --arg waTemplateId "$wa_template_id" '$msg + {waTemplateId: $waTemplateId}')"
  fi

  messages_json="$(jq -nc --argjson list "$messages_json" --argjson item "$message" '$list + [$item]')"
done

body_args=( --arg orgId "$org_id" --argjson messages "$messages_json" )
body_filter='{orgId: $orgId, messages: $messages}'

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
