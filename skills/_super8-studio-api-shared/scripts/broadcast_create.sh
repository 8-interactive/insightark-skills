#!/bin/bash

set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
source "$script_dir/lib/env.sh"
source "$script_dir/lib/http.sh"
source "$script_dir/lib/output.sh"

org_id=""
platform=""
where_file=""
schedule_at=""
inbox_to_done="false"
message_tag=""
wa_template_id=""

customer_ids=()
texts=()
images=()
videos=()
order=()

while [ "$#" -gt 0 ]; do
  case "$1" in
    --org-id) org_id="${2:-}"; shift 2 ;;
    --platform) platform="${2:-}"; shift 2 ;;
    --customer-id) customer_ids+=("${2:-}"); shift 2 ;;
    --where-file) where_file="${2:-}"; shift 2 ;;
    --text) texts+=("${2:-}"); order+=("text:$((${#texts[@]} - 1))"); shift 2 ;;
    --image) images+=("${2:-}"); order+=("image:$((${#images[@]} - 1))"); shift 2 ;;
    --video) videos+=("${2:-}"); order+=("video:$((${#videos[@]} - 1))"); shift 2 ;;
    --schedule-at) schedule_at="${2:-}"; shift 2 ;;
    --inbox-to-done) inbox_to_done="true"; shift ;;
    --message-tag) message_tag="${2:-}"; shift 2 ;;
    --wa-template-id) wa_template_id="${2:-}"; shift 2 ;;
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
  messages_json="$(jq -nc --argjson list "$messages_json" --argjson item "$message" '$list + [$item]')"
done

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
