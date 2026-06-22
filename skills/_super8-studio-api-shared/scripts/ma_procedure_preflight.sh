#!/usr/bin/env bash

set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
source "$script_dir/lib/env.sh"
source "$script_dir/lib/output.sh"

json_file=""
confirmation_file=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --json-file) json_file="${2:-}"; shift 2 ;;
    --confirmation-file) confirmation_file="${2:-}"; shift 2 ;;
    *)
      printf 'Unknown option: %s\n' "$1" >&2
      exit 1
      ;;
  esac
done

if [ -z "$json_file" ] || [ ! -f "$json_file" ]; then
  printf 'Usage: %s --json-file PATH --confirmation-file PATH\n' "$(basename "$0")" >&2
  printf 'Local gate before validate/create: required keys, schedule TZ, placeholder scan, Meta fbTag, confirmation parity.\n' >&2
  exit 1
fi

if [ -z "$confirmation_file" ] || [ ! -f "$confirmation_file" ]; then
  printf '%s: --confirmation-file is required.\n' "$(basename "$0")" >&2
  exit 1
fi

s8_require_command jq

jq empty "$json_file" >/dev/null 2>&1 || {
  printf 'Invalid JSON in --json-file\n' >&2
  exit 1
}

jq empty "$confirmation_file" >/dev/null 2>&1 || {
  printf 'Invalid JSON in --confirmation-file\n' >&2
  exit 1
}

if ! jq \
  --slurpfile payload "$json_file" \
  --slurpfile conf "$confirmation_file" \
  -n \
  '
  def openapi_required_root:
    ["orgId","templateType","name","enabled","platform","startTime","endTime","limits","oos","nodes","edges"];

  def iso8601_with_tz($s):
    ($s | type == "string") and (
      ($s | test("Z$")) or ($s | test("[+-][0-9]{2}:[0-9]{2}$"))
    );

  def meta_need_fb_tag($p):
    (($p.platform | ascii_downcase) == "facebook")
    or (($p.platform | ascii_downcase) == "instagram")
    or (($p.platform | ascii_downcase) == "messenger");

  def per_customer_allowed($pc):
      (($pc | type) == "number" and ($pc >= 0) and (($pc | floor) == $pc))
      or (($pc | type) == "string" and $pc == "onceByDay");

  def oos_sleep_window_ok($oos):
      (($oos | type) == "object")
      and (($oos.hour | type) == "number") and ($oos.hour >= 0) and ($oos.hour <= 23) and (($oos.hour | floor) == $oos.hour)
      and (($oos.minute | type) == "number") and ($oos.minute >= 0) and ($oos.minute <= 59) and (($oos.minute | floor) == $oos.minute)
      and (($oos.duration | type) == "number") and ($oos.duration > 0) and (($oos.duration | floor) == $oos.duration);

  def expected_match_keys($p):
    (["enabled","endTime","limits","name","oos","orgId","platform","startTime","templateType"]
    + (if meta_need_fb_tag($p) or ($p | has("fbTag")) then ["fbTag"] else [] end))
    | unique
    | sort;

  def forbid_placeholder_walk($doc):
    $doc | walk(
      if type == "string" then
        if
          (. | contains("<REQUIRED_FROM_CUSTOMER"))
          or (. | contains("YOUR_ORG_ID"))
          or (. | contains("CHANGE_ME"))
          or (. | test("\\bTODO\\b"; "i"))
          or (. | test("\\bFIXME\\b"; "i"))
        then
          error("payload contains forbidden placeholder-like string")
        else .
        end
      else .
      end
    );

  ($payload[0]) as $p |
  ($conf[0]) as $c |

  if ($p | type) != "object" then error("payload root must be object")
  elif ($c | type) != "object" then error("confirmation root must be object")
  elif ($c.customerExplicitApproval != true) then error("customerExplicitApproval must be true")
  elif ($c.nodesEdgesCustomerApproved != true) then error("nodesEdgesCustomerApproved must be true")
  elif ($c.matchTopLevel | type) != "object" then error("matchTopLevel must be object")

  elif any(openapi_required_root[]; . as $k | ($p | has($k)) | not) then error("missing one of openapi_required_root fields")

  elif ($p.enabled | type) != "boolean" then error("enabled must be boolean")
  elif ($p.limits | type) != "object" then error("limits must be object")
  elif (($p.limits | has("message")) | not) then error("limits.message is required (non-negative integer)")
  elif (($p.limits.message | type) != "number") or ($p.limits.message < 0) or (($p.limits.message | floor) != $p.limits.message) then error("limits.message must be non-negative integer")
  elif (($p.limits | has("per_customer")) | not) then error("limits.per_customer is required (non-negative integer or onceByDay)")
  elif (per_customer_allowed($p.limits.per_customer) | not) then error("limits.per_customer must be non-negative integer or literal string onceByDay")
  elif ($p.nodes | type) != "array" or (($p.nodes | length) == 0) then error("nodes must be non-empty array")
  elif ($p.edges | type) != "array" or (($p.edges | length) == 0) then error("edges must be non-empty array")

  elif ($p.startTime == null or $p.endTime == null) then error("startTime and endTime are required (journey schedule window)")
  elif iso8601_with_tz($p.startTime) | not then error("startTime must be timezone-aware ISO 8601 (Z or +/-HH:MM)")
  elif iso8601_with_tz($p.endTime) | not then error("endTime must be timezone-aware ISO 8601 (Z or +/-HH:MM)")

  elif ($p.oos != null) and (($p.oos | type) == "object") and ($p.oos.enabled == true) and ((oos_sleep_window_ok($p.oos) | not))
    then error("when oos.enabled is true, oos.hour (0–23), oos.minute (0–59), and oos.duration (positive integer seconds) are required")

  elif meta_need_fb_tag($p) and (($p | has("fbTag") | not) or (($p.fbTag | type) != "string") or (($p.fbTag | length) == 0))
    then error("fbTag must be a non-empty string for facebook/instagram/messenger")

  elif (($c.matchTopLevel | keys | sort) != expected_match_keys($p))
    then error("matchTopLevel keys must exactly equal approved top-level keys for this payload (always includes enabled, endTime, limits, name, oos, orgId, platform, startTime, templateType; plus fbTag when Meta platform or body carries fbTag)")

  elif any($c.matchTopLevel | keys[]; . as $mk | $p[$mk] != $c.matchTopLevel[$mk])
    then error("payload differs from matchTopLevel for at least one confirmed field")

  elif (try (forbid_placeholder_walk($p) | true) catch false) != true
    then error("payload contains forbidden placeholder-like string")

  else empty
  end
  '; then
  printf 'Preflight failed (see jq error above).\n' >&2
  exit 1
fi

s8_print_step 'Preflight OK (local checks passed).'
