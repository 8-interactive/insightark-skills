#!/bin/bash
# Static compliance checker for plugin structure and SKILL.md files.
set -euo pipefail
repo_root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
bundle_dir="$repo_root/bundle"
errors=0
check(){ local label="$1" result="$2"; if [ "$result" = pass ]; then printf '  \033[32m✓\033[0m %s\n' "$label"; else printf '  \033[31m✗\033[0m %s\n' "$label"; errors=$((errors+1)); fi; }
printf '\n[Plugin structure]\n'
plugin_json="$repo_root/.codex-plugin/plugin.json"
if [ -f "$plugin_json" ]; then
 check ".codex-plugin/plugin.json exists" pass
 if python3 -m json.tool < "$plugin_json" >/dev/null 2>&1; then
  check ".codex-plugin/plugin.json is valid JSON" pass
  p_name=$(python3 -c "import json;d=json.load(open('$plugin_json'));print(d.get('name',''))")
  p_ver=$(python3 -c "import json;d=json.load(open('$plugin_json'));print(d.get('version',''))")
  p_skills=$(python3 -c "import json;d=json.load(open('$plugin_json'));print(d.get('skills',''))")
  check "plugin.json has name" "$([ -n "$p_name" ] && echo pass || echo fail)"
  check "plugin.json has version" "$([ -n "$p_ver" ] && echo pass || echo fail)"
  check "plugin.json has skills" "$([ -n "$p_skills" ] && echo pass || echo fail)"
  if [ -n "$p_skills" ]; then skills_abs=$(cd "$repo_root/.codex-plugin" && cd "$p_skills" 2>/dev/null && pwd || echo ""); check "plugin.json skills path resolves" "$([ -d "$skills_abs" ] && echo pass || echo fail)"; fi
 else check ".codex-plugin/plugin.json is valid JSON" fail; fi
else check ".codex-plugin/plugin.json exists" fail; errors=$((errors+4)); fi
mkt_json="$repo_root/.agents/plugins/marketplace.json"
if [ -f "$mkt_json" ]; then check ".agents/plugins/marketplace.json exists" pass; if python3 -m json.tool < "$mkt_json" >/dev/null 2>&1; then check ".agents/plugins/marketplace.json is valid JSON" pass; else check ".agents/plugins/marketplace.json is valid JSON" fail; fi; else check ".agents/plugins/marketplace.json exists" fail; errors=$((errors+1)); fi
check "LICENSE exists" "$([ -f "$repo_root/LICENSE" ] && echo pass || echo fail)"
check "SECURITY.md exists" "$([ -f "$repo_root/SECURITY.md" ] && echo pass || echo fail)"
printf '\n[Skills in bundle/]\n'
required_sections=("## When not to use" "## Inputs" "## Outputs" "## Failure handling")
for skill_dir in "$bundle_dir"/*/; do
 skill_name="$(basename "$skill_dir")"; [[ "$skill_name" == _* ]] && continue; skill_md="$skill_dir/SKILL.md"
 if [ ! -f "$skill_md" ]; then check "$skill_name/SKILL.md exists" fail; continue; fi
 check "$skill_name/SKILL.md exists" pass
 name_in_md=$(grep -m1 '^name:' "$skill_md" | sed 's/name:[[:space:]]*//')
 check "$skill_name: name matches folder" "$([ "$name_in_md" = "$skill_name" ] && echo pass || echo fail)"
 desc=$(grep -m1 '^description:' "$skill_md" | sed 's/description:[[:space:]]*//')
 check "$skill_name: description length > 20 chars" "$([ ${#desc} -gt 20 ] && echo pass || echo fail)"
 check "$skill_name: license in frontmatter" "$(grep -q '^license:' "$skill_md" && echo pass || echo fail)"
 check "$skill_name: metadata block in frontmatter" "$(grep -q '^metadata:' "$skill_md" && echo pass || echo fail)"
 for section in "${required_sections[@]}"; do label_safe="${section//\#\# /}"; check "$skill_name: '## $label_safe' section present" "$(grep -qF "$section" "$skill_md" && echo pass || echo fail)"; done
done
printf '\n'; if [ "$errors" -eq 0 ]; then printf '\033[32mAll checks passed.\033[0m\n'; exit 0; else printf '\033[31m%d check(s) failed.\033[0m\n' "$errors"; exit 1; fi
