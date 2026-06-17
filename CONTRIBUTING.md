# Contributing

## Adding a New Skill

1. Create a new folder under `bundle/` using lowercase kebab-case: `bundle/super8-studio-<name>/`.
2. Add a `SKILL.md` with the required frontmatter and body sections (see `docs/skill-authoring-guide.md`).
3. Add any scripts to `bundle/_super8-studio-api-shared/scripts/` (shared library).
4. Reference scripts from SKILL.md with the relative path `../_super8-studio-api-shared/scripts/<name>.sh`.
5. Add `tests/eval_cases.yaml` and at least two fixtures in `tests/fixtures/`.
6. Run `bash scripts/validate-skills.sh` — all checks must pass before submitting a PR.

## PR Checklist

- [ ] Skill folder uses lowercase kebab-case.
- [ ] `SKILL.md` exists with valid YAML frontmatter.
- [ ] `name` field matches folder name.
- [ ] `description` clearly states what the skill does and when to use it.
- [ ] `license: MIT` present.
- [ ] `metadata` block present with `owner`, `version`, `category`, `domain`.
- [ ] Required body sections present.
- [ ] No secrets, tokens, or customer PII committed.
- [ ] `bash scripts/validate-skills.sh` passes.
- [ ] `CHANGELOG.md` updated.
