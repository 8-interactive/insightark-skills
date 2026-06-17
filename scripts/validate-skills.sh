#!/bin/bash
# Static compliance checker for plugin structure and SKILL.md files.
set -euo pipefail

repo_root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
bundle_dir="$repo_root/bundle"
errors=0

check() {
  local label="$1" result="$2"
  if [ "$result" = "pass" ]; then
    printf '  \033[32m✓\033[0m %s\n' "$label"
  else
    printf '  \033[31m✗\033[0m %s\n' "$label"
    errors=$((errors + 1))
  fi
}

extract_first_field() {
  local field="$1" file="$2"
  grep -m1 "^$field:" "$file" | sed "s/$field:[[:space:]]*//" || true
}

frontmatter_has() {
  local key="$1" file="$2"
  awk -v key="$key" '
    BEGIN { closed = 0; found = 0 }
    NR == 1 && $0 != "---" { exit 1 }
    NR == 1 { next }
    $0 == "---" { closed = 1; exit(found ? 0 : 1) }
    index($0, key) == 1 { found = 1 }
    END { if (!closed) exit 1 }
  ' "$file"
}

# ── Plugin structure ──────────────────────────────────────────────────────────
printf '\n[Plugin structure]\n'

plugin_json="$repo_root/.codex-plugin/plugin.json"
if [ -f "$plugin_json" ]; then
  check ".codex-plugin/plugin.json exists" pass
  if python3 -m json.tool < "$plugin_json" > /dev/null 2>&1; then
    check ".codex-plugin/plugin.json is valid JSON" pass
    p_name=$(python3 -c "import json; d=json.load(open('$plugin_json')); print(d.get('name',''))")
    p_ver=$(python3 -c "import json; d=json.load(open('$plugin_json')); print(d.get('version',''))")
    p_skills=$(python3 -c "import json; d=json.load(open('$plugin_json')); print(d.get('skills',''))")
  else
    check ".codex-plugin/plugin.json is valid JSON" fail
    p_name=""
    p_ver=""
    p_skills=""
  fi
else
  check ".codex-plugin/plugin.json exists" fail
  check ".codex-plugin/plugin.json is valid JSON" fail
  p_name=""
  p_ver=""
  p_skills=""
fi
check "plugin.json has name" "$([ -n "$p_name" ] && echo pass || echo fail)"
check "plugin.json has version" "$([ -n "$p_ver" ] && echo pass || echo fail)"
check "plugin.json has skills" "$([ -n "$p_skills" ] && echo pass || echo fail)"
skills_abs=""
if [ -n "$p_skills" ]; then
  skills_abs=$(cd "$repo_root/.codex-plugin" && cd "$p_skills" 2>/dev/null && pwd || echo "")
fi
check "plugin.json skills path resolves" "$([ -d "$skills_abs" ] && echo pass || echo fail)"

mkt_json="$repo_root/.agents/plugins/marketplace.json"
if [ -f "$mkt_json" ]; then
  check ".agents/plugins/marketplace.json exists" pass
  if python3 -m json.tool < "$mkt_json" > /dev/null 2>&1; then
    check ".agents/plugins/marketplace.json is valid JSON" pass
  else
    check ".agents/plugins/marketplace.json is valid JSON" fail
  fi
else
  check ".agents/plugins/marketplace.json exists" fail
  check ".agents/plugins/marketplace.json is valid JSON" fail
fi

check "LICENSE exists" "$([ -f "$repo_root/LICENSE" ] && echo pass || echo fail)"
check "SECURITY.md exists" "$([ -f "$repo_root/SECURITY.md" ] && echo pass || echo fail)"

# ── Skills in bundle/ ─────────────────────────────────────────────────────────
printf '\n[Skills in bundle/]\n'

required_sections=("## When not to use" "## Inputs" "## Outputs" "## Failure handling")

for skill_dir in "$bundle_dir"/*/; do
  skill_name="$(basename "$skill_dir")"
  [[ "$skill_name" == _* ]] && continue

  skill_md="$skill_dir/SKILL.md"
  if [ ! -f "$skill_md" ]; then
    check "$skill_name/SKILL.md exists" fail
    continue
  fi
  check "$skill_name/SKILL.md exists" pass

  name_in_md=$(extract_first_field name "$skill_md")
  check "$skill_name: name matches folder" \
    "$([ "$name_in_md" = "$skill_name" ] && echo pass || echo fail)"

  desc=$(extract_first_field description "$skill_md")
  check "$skill_name: description length > 20 chars" \
    "$([ ${#desc} -gt 20 ] && echo pass || echo fail)"

  check "$skill_name: license in frontmatter" \
    "$(frontmatter_has "license:" "$skill_md" && echo pass || echo fail)"

  check "$skill_name: metadata block in frontmatter" \
    "$(frontmatter_has "metadata:" "$skill_md" && echo pass || echo fail)"

  for section in "${required_sections[@]}"; do
    label_safe="${section//\#\# /}"
    check "$skill_name: '## $label_safe' section present" \
      "$(grep -qF "$section" "$skill_md" && echo pass || echo fail)"
  done
done

# ── Summary ───────────────────────────────────────────────────────────────────
printf '\n'
if [ "$errors" -eq 0 ]; then
  printf '\033[32mAll checks passed.\033[0m\n'
  exit 0
else
  printf '\033[31m%d check(s) failed.\033[0m\n' "$errors"
  exit 1
fi
