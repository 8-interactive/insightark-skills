# PR Review: #8 — Rebrand to SUPER 8 Studio InsightArk Skills

**Reviewed**: 2026-06-29
**Author**: Paul Lyu
**Branch**: feat/branding-insightark → main
**Decision**: APPROVE (HIGH findings fixed in-review, commit 3af0635)

## Summary

Brand rebrand + identifier alignment + OpenSpec formalization. 83 files, mostly mechanical brand-string replacement and OpenSpec docs. Re-review after rebasing onto v0.5.2 (which merged the login/logout feature, #9) surfaced four stale strings the rebase missed — now fixed. No behavior change; release gate green.

## Findings

### CRITICAL
None.

### HIGH
- **installer/install.js (x2), installer/setup.js** — user-facing prompts told users to run `super8-studio-api-skills login`, but the bin was renamed to `insightark-skills`, so the suggested command no longer exists. These lines were new code introduced by the login/logout merge (#9) and did not textually conflict during rebase, so they slipped through. **Fixed** → `insightark-skills login`.

### MEDIUM
- **skills/_super8-studio-api-shared/scripts/lib/env.js** — error text "Missing Super 8 Studio API session token" used the old brand casing + dropped-"API" naming. **Fixed** → "Missing SUPER 8 Studio session token".

### LOW
- Internal identifiers (`super8-studio-*` skill folders, `_super8-studio-api-shared`, `S8_*` env vars, `.super8-studio.*` config files) remain unchanged — intentional per the change's Non-Goals (stable internal ids, not user-facing).

## Validation Results

| Check | Result |
|---|---|
| validate | Pass |
| test | Pass |
| smoke | Pass |
| Conflict markers | None |
| Stale identifiers in shipped code | None after fix |

## Files Reviewed

Focus: conflict-resolved JS (install.js, uninstall.js, super8-skills-cli.js, env.js, validate-skills.js, register-install.js, setup.js), manifests (package.json, plugin/marketplace JSON), legal (LICENSE, NOTICE), OpenSpec change + specs. Remaining files are mechanical brand-string replacements (SKILL.md, docs, README, Introduction.html) and OpenSpec tooling scaffolds.
