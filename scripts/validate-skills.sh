#!/bin/bash

set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
repo_dir="$(CDPATH= cd -- "$script_dir/.." && pwd)"

failures=0

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  failures=$((failures + 1))
}

pass() {
  printf 'PASS: %s\n' "$1"
}

require_file() {
  local path="$1"
  if [ -f "$repo_dir/$path" ]; then
    pass "$path exists"
  else
    fail "$path is missing"
  fi
}

json_value() {
  local path="$1"
  local expr="$2"
  node -e "const fs=require('fs'); const data=JSON.parse(fs.readFileSync(process.argv[1], 'utf8')); const value=(${expr})(data); if (value === undefined || value === null) process.exit(2); console.log(value);" "$repo_dir/$path"
}

validate_json() {
  local path="$1"
  if node -e "JSON.parse(require('fs').readFileSync(process.argv[1], 'utf8'))" "$repo_dir/$path" >/dev/null 2>&1; then
    pass "$path is valid JSON"
  else
    fail "$path is not valid JSON"
  fi
}

validate_versions() {
  local bundle_version plugin_version package_version

  bundle_version="$(tr -d '[:space:]' <"$repo_dir/bundle/_super8-studio-api-shared/VERSION")"
  plugin_version="$(json_value ".codex-plugin/plugin.json" "data => data.version")" || {
    fail ".codex-plugin/plugin.json version is missing"
    return
  }
  package_version="$(json_value "package.json" "data => data.version")" || {
    fail "package.json version is missing"
    return
  }

  if [ "$bundle_version" = "$plugin_version" ] && [ "$bundle_version" = "$package_version" ]; then
    pass "versions are synchronized ($bundle_version)"
  else
    fail "versions differ: bundle=$bundle_version plugin=$plugin_version package=$package_version"
  fi
}

validate_plugin_manifest() {
  local skills_path resolved_skills marketplace_path

  skills_path="$(json_value ".codex-plugin/plugin.json" "data => data.skills")" || {
    fail ".codex-plugin/plugin.json skills is missing"
    return
  }
  resolved_skills="$(CDPATH= cd -- "$repo_dir/.codex-plugin" && CDPATH= cd -- "$skills_path" && pwd)" || {
    fail ".codex-plugin/plugin.json skills path does not resolve: $skills_path"
    return
  }
  if [ "$resolved_skills" = "$repo_dir/bundle" ]; then
    pass "plugin skills path resolves to bundle/"
  else
    fail "plugin skills path resolves to unexpected path: $resolved_skills"
  fi

  marketplace_path="$(json_value ".agents/plugins/marketplace.json" "data => data.plugins && data.plugins[0] && data.plugins[0].source && data.plugins[0].source.path")" || {
    fail ".agents/plugins/marketplace.json source.path is missing"
    return
  }
  if [ "$marketplace_path" = "./" ]; then
    pass "marketplace source.path points to repository root"
  else
    fail "marketplace source.path should be ./ but is $marketplace_path"
  fi
}

validate_package_manifest() {
  local bin_path

  bin_path="$(json_value "package.json" "data => data.bin && data.bin['super8-studio-api-skills']")" || {
    fail "package.json bin.super8-studio-api-skills is missing"
    return
  }
  bin_path="${bin_path#./}"
  if [ -f "$repo_dir/$bin_path" ]; then
    pass "package bin exists ($bin_path)"
  else
    fail "package bin target is missing: $bin_path"
  fi
}

frontmatter_value() {
  local file="$1"
  local key="$2"
  awk -v key="$key" '
    NR == 1 && $0 == "---" { in_fm=1; next }
    in_fm && $0 == "---" { exit }
    in_fm && index($0, key ":") == 1 {
      sub("^[^:]+:[[:space:]]*", "")
      print
      exit
    }
  ' "$file"
}

validate_skills() {
  local skill_dir skill_file folder_name skill_name description count

  count=0
  while IFS= read -r skill_dir; do
    count=$((count + 1))
    folder_name="$(basename "$skill_dir")"
    skill_file="$skill_dir/SKILL.md"
    if [ ! -f "$skill_file" ]; then
      fail "$folder_name is missing SKILL.md"
      continue
    fi

    skill_name="$(frontmatter_value "$skill_file" "name")"
    description="$(frontmatter_value "$skill_file" "description")"

    if [ "$skill_name" = "$folder_name" ]; then
      pass "$folder_name frontmatter name matches folder"
    else
      fail "$folder_name frontmatter name mismatch: ${skill_name:-<missing>}"
    fi

    if [ "${#description}" -ge 40 ]; then
      pass "$folder_name description is present"
    else
      fail "$folder_name description is missing or too short"
    fi
  done < <(find "$repo_dir/bundle" -mindepth 1 -maxdepth 1 -type d -name 'super8-studio-*' | sort)

  if [ "$count" -gt 0 ]; then
    pass "found $count skill directories"
  else
    fail "no skill directories found under bundle/"
  fi
}

validate_install_contract() {
  if grep -q 'super8_write_install_config' "$repo_dir/install.sh"; then
    pass "install.sh writes install registry"
  else
    fail "install.sh does not call super8_write_install_config"
  fi

  if grep -q 'super8_write_install_config' "$repo_dir/scripts/register-install.sh"; then
    pass "register-install.sh writes install registry"
  else
    fail "register-install.sh does not call super8_write_install_config"
  fi

  if grep -q 'installScript' "$repo_dir/scripts/super8-skills-cli.js" && grep -q 'install.sh' "$repo_dir/scripts/super8-skills-cli.js"; then
    pass "npm adapter delegates install to install.sh"
  else
    fail "npm adapter does not delegate install to install.sh"
  fi
}

require_file ".codex-plugin/plugin.json"
require_file ".agents/plugins/marketplace.json"
require_file "package.json"
require_file "LICENSE"
require_file "SECURITY.md"
require_file "CHANGELOG.md"
require_file "CONTRIBUTING.md"
require_file "docs/install-flow-contract.md"
require_file "docs/plugin-release-process.md"
require_file "docs/skill-authoring-guide.md"
require_file "scripts/register-install.sh"

validate_json ".codex-plugin/plugin.json"
validate_json ".agents/plugins/marketplace.json"
validate_json "package.json"
validate_versions
validate_plugin_manifest
validate_package_manifest
validate_skills
validate_install_contract

if [ "$failures" -gt 0 ]; then
  printf '\n%s validation failure(s).\n' "$failures" >&2
  exit 1
fi

printf '\nAll validations passed.\n'
