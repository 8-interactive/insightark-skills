# Contributing

> Using an AI agent (Claude Code, Codex, Cursor, …) to make changes? Read
> [AGENTS.md](AGENTS.md) first. Core rule: **every edit must trace to the
> change's scope — never remove or modify adjacent code nobody asked you to
> touch.**

## Skill Layout

Canonical cross-agent skills live under `skills/`.

```text
skills/<skill-name>/SKILL.md
skills/_super8-studio-api-shared/scripts/
```

The underscore-prefixed shared directory is runtime support, not a triggerable
skill. Skill scripts are Node (`.js`) and run with `node <path>` — zero
dependencies, no bash required.

## Skill Rules

- Folder names and frontmatter `name` values must match.
- Every skill must include a clear `description`.
- Read-only skills must stay read-only.
- Write-action skills must require explicit confirmation before API mutation or
  outbound messaging.
- Shared Node helpers belong in `_super8-studio-api-shared/scripts/` (libs in `scripts/lib/`).

## Validation

Run these before opening a PR or publishing a package:

```bash
npm run validate          # node scripts/validate-skills.js
npm test                  # node test/env-precedence.test.js
```

If the change affects install behavior, test at least one direct install target:

```bash
node scripts/super8-skills-cli.js install --target /tmp/super8-skills-test
node scripts/super8-skills-cli.js setup --check
```
