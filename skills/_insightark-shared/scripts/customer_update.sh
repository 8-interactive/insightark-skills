#!/bin/bash

set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
source "$script_dir/lib/env.sh"
source "$script_dir/lib/http.sh"
source "$script_dir/lib/output.sh"

org_id=""
customer_id=""

display_name_set=false
display_name=""
cell_phone_set=false
cell_phone=""
email_set=false
email=""
birthday_set=false
birthday=""
gender_set=false
gender=""
language_set=false
language=""
nation_set=false
nation=""
location_set=false
location=""
address_set=false
address=""
about_set=false
about=""
custom_field_1_set=false
custom_field_1=""
custom_field_2_set=false
custom_field_2=""
custom_field_3_set=false
custom_field_3=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --org-id) org_id="${2:-}"; shift 2 ;;
    --customer-id) customer_id="${2:-}"; shift 2 ;;
    --display-name) display_name_set=true; display_name="${2-}"; shift 2 ;;
    --cell-phone) cell_phone_set=true; cell_phone="${2-}"; shift 2 ;;
    --email) email_set=true; email="${2-}"; shift 2 ;;
    --birthday) birthday_set=true; birthday="${2-}"; shift 2 ;;
    --gender) gender_set=true; gender="${2-}"; shift 2 ;;
    --language) language_set=true; language="${2-}"; shift 2 ;;
    --nation) nation_set=true; nation="${2-}"; shift 2 ;;
    --location) location_set=true; location="${2-}"; shift 2 ;;
    --address) address_set=true; address="${2-}"; shift 2 ;;
    --about) about_set=true; about="${2-}"; shift 2 ;;
    --custom-field-1) custom_field_1_set=true; custom_field_1="${2-}"; shift 2 ;;
    --custom-field-2) custom_field_2_set=true; custom_field_2="${2-}"; shift 2 ;;
    --custom-field-3) custom_field_3_set=true; custom_field_3="${2-}"; shift 2 ;;
    *) printf 'Unknown option: %s\n' "$1" >&2; exit 1 ;;
  esac
done

if [ -z "$customer_id" ]; then
  printf 'Missing required option: --customer-id\n' >&2
  exit 1
fi

if ! $display_name_set && ! $cell_phone_set && ! $email_set && ! $birthday_set && ! $gender_set && ! $language_set && ! $nation_set && ! $location_set && ! $address_set && ! $about_set && ! $custom_field_1_set && ! $custom_field_2_set && ! $custom_field_3_set; then
  printf 'Provide at least one update field.\n' >&2
  exit 1
fi

s8_require_command curl
s8_require_command jq
s8_load_runtime_env
org_id="$(s8_resolve_org_id "$org_id")"

body="$(jq -nc \
  --arg orgId "$org_id" \
  --arg displayName "$display_name" \
  --arg cellPhone "$cell_phone" \
  --arg email "$email" \
  --arg birthday "$birthday" \
  --arg gender "$gender" \
  --arg language "$language" \
  --arg nation "$nation" \
  --arg location "$location" \
  --arg address "$address" \
  --arg about "$about" \
  --arg customField1 "$custom_field_1" \
  --arg customField2 "$custom_field_2" \
  --arg customField3 "$custom_field_3" \
  --argjson displayNameSet "$display_name_set" \
  --argjson cellPhoneSet "$cell_phone_set" \
  --argjson emailSet "$email_set" \
  --argjson birthdaySet "$birthday_set" \
  --argjson genderSet "$gender_set" \
  --argjson languageSet "$language_set" \
  --argjson nationSet "$nation_set" \
  --argjson locationSet "$location_set" \
  --argjson addressSet "$address_set" \
  --argjson aboutSet "$about_set" \
  --argjson customField1Set "$custom_field_1_set" \
  --argjson customField2Set "$custom_field_2_set" \
  --argjson customField3Set "$custom_field_3_set" \
  '{orgId: $orgId}
   + (if $displayNameSet then {displayName: $displayName} else {} end)
   + (if $cellPhoneSet then {cellPhone: $cellPhone} else {} end)
   + (if $emailSet then {email: $email} else {} end)
   + (if $birthdaySet then {birthday: $birthday} else {} end)
   + (if $genderSet then {gender: $gender} else {} end)
   + (if $languageSet then {language: $language} else {} end)
   + (if $nationSet then {nation: $nation} else {} end)
   + (if $locationSet then {location: $location} else {} end)
   + (if $addressSet then {address: $address} else {} end)
   + (if $aboutSet then {about: $about} else {} end)
   + (if $customField1Set then {customField1: $customField1} else {} end)
   + (if $customField2Set then {customField2: $customField2} else {} end)
   + (if $customField3Set then {customField3: $customField3} else {} end)')"

response_file="$(mktemp)"
status_file="$(mktemp)"
trap 'rm -f "$response_file" "$status_file"' EXIT

s8_api_request PATCH "/developer/v1/customers/${customer_id}?$(s8_query_pair orgId "$org_id")" "$body" "$response_file" "$status_file"
s8_expect_success "$(<"$status_file")" "$response_file"
s8_print_json_file "$response_file"