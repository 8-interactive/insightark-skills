#!/bin/bash

# Shared helpers for Developer API media upload (presigned PUT).

s8_guess_content_type_from_filename() {
  local filename="$1"
  local ext="${filename##*.}"
  ext="$(printf '%s' "$ext" | tr '[:upper:]' '[:lower:]')"

  case "$ext" in
    jpg|jpeg) printf '%s\n' 'image/jpeg' ;;
    png) printf '%s\n' 'image/png' ;;
    gif) printf '%s\n' 'image/gif' ;;
    webp) printf '%s\n' 'image/webp' ;;
    pdf) printf '%s\n' 'application/pdf' ;;
    *)
      printf 'Cannot infer content type from filename extension: %s\n' "$filename" >&2
      printf 'Provide --content-type explicitly.\n' >&2
      return 1
      ;;
  esac
}

s8_validate_media_upload_purpose() {
  local purpose="$1"

  case "$purpose" in
    card|imagemap|image|file) return 0 ;;
    *)
      printf 'Invalid --purpose: %s (expected card, imagemap, image, or file)\n' "$purpose" >&2
      return 1
      ;;
  esac
}

s8_request_media_upload_url() {
  local org_id="$1"
  local filename="$2"
  local content_type="$3"
  local purpose="$4"
  local response_file="$5"
  local status_file="$6"
  local body

  body="$(jq -nc \
    --arg orgId "$org_id" \
    --arg filename "$filename" \
    --arg contentType "$content_type" \
    --arg purpose "$purpose" \
    '{orgId: $orgId, filename: $filename, contentType: $contentType, purpose: $purpose}')"

  s8_api_request POST "/developer/v1/media/upload-url" "$body" "$response_file" "$status_file"
}

s8_media_put_file() {
  local upload_url="$1"
  local file_path="$2"
  local content_type="$3"
  local status_file="$4"
  local status

  status="$(curl -sS \
    -X PUT \
    -H "Content-Type: ${content_type}" \
    --data-binary "@${file_path}" \
    -o /dev/null \
    -w "%{http_code}" \
    "$upload_url")"
  printf '%s' "$status" > "$status_file"
}

s8_expect_media_put_success() {
  local status="$1"

  case "$status" in
    2*)
      return 0
      ;;
    *)
      printf 'S3 upload failed with status %s\n' "$status" >&2
      return 1
      ;;
  esac
}

s8_extract_media_upload_response() {
  local response_file="$1"
  local field="$2"

  jq -r --arg field "$field" '
    if (.data | type) == "object" and (.data[$field] // empty) != "" then
      .data[$field]
    else
      .[$field] // empty
    end
  ' "$response_file"
}
