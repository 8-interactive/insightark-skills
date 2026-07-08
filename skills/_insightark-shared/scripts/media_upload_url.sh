#!/bin/bash

set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
source "$script_dir/lib/env.sh"
source "$script_dir/lib/http.sh"
source "$script_dir/lib/output.sh"
source "$script_dir/lib/media_upload.sh"

org_id=""
file_path=""
filename=""
content_type=""
purpose="image"
do_put="false"
output_json="false"

usage() {
  printf 'Usage: %s [--org-id ID] (--file PATH | --filename NAME --content-type TYPE) [--purpose card|imagemap|image|file] [--put] [--json]\n' "$(basename "$0")" >&2
  printf '\n' >&2
  printf 'Request a presigned upload URL from POST /developer/v1/media/upload-url.\n' >&2
  printf 'With --put, upload the local file via PUT and print publicUrl.\n' >&2
  printf 'Default --purpose is image.\n' >&2
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --org-id) org_id="${2:-}"; shift 2 ;;
    --file) file_path="${2:-}"; shift 2 ;;
    --filename) filename="${2:-}"; shift 2 ;;
    --content-type) content_type="${2:-}"; shift 2 ;;
    --purpose) purpose="${2:-}"; shift 2 ;;
    --put) do_put="true"; shift ;;
    --json) output_json="true"; shift ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'Unknown option: %s\n' "$1" >&2; usage; exit 1 ;;
  esac
done

if [ -n "$file_path" ] && { [ -n "$filename" ] || [ -n "$content_type" ]; }; then
  printf 'Use either --file PATH or --filename with --content-type, not both.\n' >&2
  exit 1
fi

if [ -n "$file_path" ]; then
  if [ ! -f "$file_path" ]; then
    printf 'File not found: %s\n' "$file_path" >&2
    exit 1
  fi
  filename="$(basename "$file_path")"
  content_type="$(s8_guess_content_type_from_filename "$filename")"
elif [ -n "$filename" ] && [ -n "$content_type" ]; then
  :
else
  usage
  exit 1
fi

s8_validate_media_upload_purpose "$purpose"

s8_require_command curl
s8_require_command jq
s8_load_runtime_env
org_id="$(s8_resolve_org_id "$org_id")"

response_file="$(mktemp)"
status_file="$(mktemp)"
trap 'rm -f "$response_file" "$status_file"' EXIT

s8_request_media_upload_url "$org_id" "$filename" "$content_type" "$purpose" "$response_file" "$status_file"
s8_expect_success "$(<"$status_file")" "$response_file"

if [ "$output_json" = "true" ]; then
  s8_print_json_file "$response_file"
  exit 0
fi

upload_url="$(s8_extract_media_upload_response "$response_file" uploadUrl)"
public_url="$(s8_extract_media_upload_response "$response_file" publicUrl)"

if [ -z "$upload_url" ] || [ -z "$public_url" ]; then
  printf 'Upload URL response missing uploadUrl or publicUrl.\n' >&2
  s8_print_json_file "$response_file" >&2
  exit 1
fi

if [ "$do_put" != "true" ]; then
  printf '%s\n' "$public_url"
  exit 0
fi

if [ -z "$file_path" ]; then
  printf '--put requires --file PATH\n' >&2
  exit 1
fi

max_bytes="$(s8_extract_media_upload_response "$response_file" maxBytes)"
if [ -n "$max_bytes" ] && [ "$max_bytes" -gt 0 ]; then
  file_size="$(wc -c <"$file_path" | tr -d ' ')"
  if [ "$file_size" -gt "$max_bytes" ]; then
    printf 'File size %s bytes exceeds maxBytes %s for purpose %s.\n' "$file_size" "$max_bytes" "$purpose" >&2
    exit 1
  fi
fi

response_content_type="$(s8_extract_media_upload_response "$response_file" contentType)"
if [ -n "$response_content_type" ]; then
  content_type="$response_content_type"
fi

put_status_file="$(mktemp)"
trap 'rm -f "$response_file" "$status_file" "$put_status_file"' EXIT

s8_media_put_file "$upload_url" "$file_path" "$content_type" "$put_status_file"
s8_expect_media_put_success "$(<"$put_status_file")"

printf '%s\n' "$public_url"
