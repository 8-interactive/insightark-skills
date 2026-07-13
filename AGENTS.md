# Working in this repo as an AI agent

Guidance for any coding agent (Claude Code, Codex, Cursor, OpenCode, Copilot, …)
making changes here. Read this before editing.

## Golden rule: stay within the change's scope

**Every edit must trace to an explicit task, spec, or the request you were
given. Do not remove or modify adjacent code just because it looks related.**

- Before deleting/altering a flag, function, field, env var, or option,
  confirm something in scope actually calls for it. If not, leave it alone.
- Treat similarly-named things as **distinct concerns** until proven
  otherwise — e.g. `S8_API_URL` (the API endpoint) vs `S8_SESSION_TOKEN` (the
  credential); `install.sh` (writes the skills payload + registry) vs
  `setup-env.sh` (writes credentials + runs doctor).
- If you spot a worthwhile but out-of-scope cleanup, **surface it as a
  separate suggestion** — don't fold it into the current change.
- When unsure about scope, prefer the minimal edit and ask.

## Architecture facts that constrain edits

- **Zero runtime dependencies.** Skill scripts use only the Node 18+ standard
  library (`fetch`, `JSON`, `Date`, `node:*`). Do not add npm dependencies to
  anything that ships in `skills/` — agent skill folders must never carry a
  `node_modules`.
- **Installer is Bash.** `install.sh`, `setup-env.sh`, `uninstall.sh`, and the
  shared support libraries under `skills/_insightark-shared/scripts/lib/*.sh`
  are Bash and target macOS/Linux (no native Windows support today).
- **Skill invocation contract.** `SKILL.md` files invoke scripts via
  `node <relative-path>.js`. Keep that contract if you add or rename a skill.
- **Install registry** (`~/.insightark.config`, mode `600`) records install
  layout and target directories only — written by `install.sh` via
  `super8_write_install_config` in
  `skills/_insightark-shared/scripts/lib/install-config.sh`. It never stores
  credentials.
- **Credentials** live in `.insightark.env` (project, skills-directory, or
  `~/.insightark.env`), written by `setup-env.sh`, resolved by
  `skills/_insightark-shared/scripts/lib/env.sh` in that precedence order,
  falling back to process environment variables.

## Before opening a PR

```bash
npm run validate   # bash scripts/validate-skills.sh + node scripts/validate-mcp-skills.js
```

## Docs

- Internal-only options belong in `--help` output and code comments, **not**
  the README.
- User-facing behavior changes go in the README (EN + 中文) and
  `CHANGELOG.md`.
- `docs/` is dev-only reference material — excluded from the public mirror tree
  and CDN tarball.

## Releasing

Version must match across `skills/_insightark-shared/VERSION` and all platform
plugin manifests (`.claude-plugin`, `.codex-plugin`, `.cursor-plugin`) —
`npm run validate` checks this. Customer distribution is S3 tarball + GitHub
mirror only; **not** npm. See `docs/implementation/plugin-release-process.md`.

Root `package.json` is **private dev tooling** (`npm run validate` in Drone).
It is intentionally absent from `build-release-dir.sh` output.
