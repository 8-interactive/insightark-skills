# Skill Authoring Guide

## Structure

Create one directory per skill:

```text
skills/super8-studio-example/SKILL.md
```

Shared scripts belong in:

```text
skills/_super8-studio-api-shared/scripts/
```

**Constraint — one-plugin rule:** All skills must remain inside a single plugin
installation unit. Shared scripts reference each other via relative paths
(`../_super8-studio-api-shared/scripts/`). When Claude Code (or Codex) installs
a plugin, it copies the entire plugin root to a cache directory. Relative paths
continue to work because the whole tree is copied together.

If you ever split skills into separate plugin packages, these relative paths
will break — each plugin would be cached independently. In that case, migrate
shared logic to a bundled MCP server (`skills/_super8-studio-api-shared/` →
`.mcp.json`) so each plugin can call it over stdio instead of importing shell
scripts directly.

## Frontmatter

Every `SKILL.md` starts with frontmatter:

```yaml
---
name: super8-studio-example
description: Explain what this skill does and when an agent should choose it.
when_to_use: Use when the user asks for the exact workflow this skill supports.
allowed-mcp: false
---
```

The `name` value must match the folder name.

## Body Sections

Recommended sections:

```markdown
# Skill: super8-studio-example

## Credentials

## Scripts

## Workflow

## Guardrails

## Failure handling
```

Write-action skills must state which user confirmation is required before
mutating customer data, sending messages, creating broadcasts, or triggering
automation.
