# Contributing

## Skill Layout

Canonical cross-agent skills live under `bundle/`.

```text
bundle/<skill-name>/SKILL.md
bundle/_super8-studio-api-shared/scripts/
```

The underscore-prefixed shared directory is runtime support, not a triggerable
skill. Do not point plugin manifests at `claude-code/`; that directory is only
for Claude Code-specific overrides.

## Skill Rules

- Folder names and frontmatter `name` values must match.
- Every skill must include a clear `description`.
- Read-only skills must stay read-only.
- Write-action skills must require explicit confirmation before API mutation or
  outbound messaging.
- Shared shell helpers belong in `_super8-studio-api-shared/scripts/`.

## Validation

Run this before opening a PR or publishing a package:

```bash
bash scripts/validate-skills.sh
```

If the change affects install behavior, test at least one direct install target:

```bash
./install.sh --target /tmp/super8-skills-test
./setup-env.sh --check
```
