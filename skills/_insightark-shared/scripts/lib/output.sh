#!/bin/bash

s8_print_json_file() {
  local file_path="$1"
  jq '.' "$file_path" 2>/dev/null || cat "$file_path"
}

s8_print_step() {
  printf '%s\n' "$1"
}
