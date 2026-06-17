# Plugin Release Process

## Versioning

This repo uses a single version tracked in `bundle/_super8-studio-api-shared/VERSION`. The `.codex-plugin/plugin.json` version field must match this file.

Version format: `MAJOR.MINOR.PATCH` (SemVer).

- PATCH: bug fixes to scripts or `SKILL.md` wording
- MINOR: new skills added, non-breaking changes to existing skills
- MAJOR: breaking changes to skill names, required CLI flags, or API surface

## Release Checklist

- [ ] `bash scripts/validate-skills.sh` passes with zero failures
- [ ] `bundle/_super8-studio-api-shared/VERSION` is updated
- [ ] `.codex-plugin/plugin.json` version matches `VERSION`
- [ ] `CHANGELOG.md` has an entry for the new version
- [ ] All new skills have at least two eval fixtures and `eval_cases.yaml`

## Tagging

```bash
VERSION=$(cat bundle/_super8-studio-api-shared/VERSION)
git tag -a "v$VERSION" -m "Release $VERSION"
git push origin "v$VERSION"
```

## Distribution

For plugin install via repo address, point the agent runtime at this repository root.
