# Working in this repo as an AI agent

Guidance for any coding agent (Claude Code, Codex, Cursor, OpenCode, Copilot, …)
making changes here. Read this before editing.

## Golden rule: stay within the change's scope

**Every edit must trace to an explicit task, spec, or the request you were given.
Do not remove or modify adjacent code just because it looks related.**

- Before deleting/altering a flag, function, field, env var, or option, confirm
  something in scope actually calls for it. If not, leave it alone.
- Treat similarly-named things as **distinct concerns** until proven otherwise —
  e.g. `--api-url` (the API endpoint) vs `--console-url` (where setup opens a
  browser to create a token); `S8_API_URL` vs `S8_SESSION_TOKEN`.
- If you spot a worthwhile but out-of-scope cleanup, **surface it as a separate
  suggestion** — don't fold it into the current change.
- When unsure about scope, prefer the minimal edit and ask.

> Why this rule exists: a change scoped to `--api-url` once also silently dropped
> `setup`'s unrelated `--console-url`, breaking an escape hatch nobody asked to
> remove. Scope creep like this is hard to catch in review.

## Architecture facts that constrain edits

- **Zero runtime dependencies.** Skill scripts and the installer use only the
  Node 18+ standard library (`fetch`, `JSON`, `Date`, `node:*`). Do not add npm
  dependencies to anything that ships in `skills/` — agent skill folders must
  never carry a `node_modules`.
- **No bash.** Everything runs cross-platform on macOS, Linux, and native
  Windows. Use `node:path`/`node:os`, never shell-isms or hardcoded `/`.
- **Skill invocation contract.** `SKILL.md` files invoke scripts via
  `node <relative-path>.js`. Keep that contract if you add or rename a skill.
- **Install registry** (`~/.super8-studio.config`) is the source of truth for
  install targets and the fixed API environment (`channel`, `api_url`). The API
  URL is decided at install time, not by `setup` or environment variables.

## Before opening a PR

Run all three (all must be green):

```bash
npm run validate   # package/skills/manifest/install-contract checks
npm test           # env-precedence + API-URL resolution
npm run smoke      # install / uninstall / runtime (live doctor if creds set)
```

CI runs these on ubuntu/macos/**windows** × node 18 & 20; keep the matrix green.

## Docs

- Internal-only options (e.g. `install --staging`, `--api-url`) belong in
  `--help` and code comments, **not** the README.
- User-facing behavior changes go in the README (EN + 中文) and `CHANGELOG.md`.
