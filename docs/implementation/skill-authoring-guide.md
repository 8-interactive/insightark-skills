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
