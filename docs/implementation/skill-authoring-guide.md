# Skill Authoring Guide

Internal reference for adding or changing a skill in this bundle.

## Layout

```text
skills/insightark-example/SKILL.md
skills/insightark-example/scripts/...   # optional, workflow-specific helpers
skills/_insightark-shared/scripts/      # shared runtime (env, http, formatting)
```

Each `skills/<name>/` directory is a self-contained installation unit copied
verbatim by `install.sh` and by plugin installs (Claude Code / Codex). Shared
scripts are referenced via relative paths
(`../_insightark-shared/scripts/...`). Do not add cross-skill relative
imports between two non-shared skills — each skill folder must remain
independently copyable.

## Prefer extending a workflow skill

The bundle intentionally consolidated many narrow, per-endpoint skills into 7
workflow-oriented skills (see the table in `README.md`). Before adding a new
skill folder, check whether the operation belongs inside an existing workflow
skill instead — most InsightArk MCP surface area fits one of the 7.

## Frontmatter contract

```markdown
---
name: insightark-example
description: Explain what this skill does and when an agent should choose it, in enough detail for `validate-skills.sh` (≥40 chars) and for an agent to route correctly without opening the file.
---

# Skill: insightark-example

...
```

`scripts/validate-skills.sh` checks that:

- `name` in frontmatter matches the folder name.
- `description` is present and at least 40 characters.

## MCP-first, script fallback

The primary execution path is the hosted InsightArk MCP server — skills
should describe MCP tool calls first. Where a skill still ships a Node
script fallback (`node <relative-path>.js`), it must use only the Node 18+
standard library — zero npm dependencies (see `AGENTS.md`).

## Adding a new skill checklist

1. Create `skills/insightark-<name>/SKILL.md` with valid frontmatter.
2. If it needs shared helpers, reuse `_insightark-shared/scripts/lib/*` —
   don't duplicate env/http logic.
3. Add the skill to the table in `README.md` (English + 中文).
4. Run `bash scripts/validate-skills.sh` and `node scripts/validate-mcp-skills.js`.
5. Bump the version (see `docs/implementation/plugin-release-process.md`) and
   add a `CHANGELOG.md` entry.
