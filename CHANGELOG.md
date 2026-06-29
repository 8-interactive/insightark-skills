# Changelog

## Unreleased

- **BREAKING (package identity)**: Rename the npm package from
  `@super8/studio-api-skills` to `@8-interactive/insightark-skills` and publish
  it to **public** npm (`publishConfig.access: public`). Install with
  `npx @8-interactive/insightark-skills install` for any agent. The `bin`
  command name and plugin manifest identifiers are unchanged for now.
- Add a tag-triggered CI release job that publishes to npm only after
  `validate` + `test` + `smoke` pass.
- Claude Code / Codex clients install via `npx … install --agents
  claude-code|codex`; the plugin-marketplace path returns when the repo is public.

- **BREAKING**: Re-platform the entire skill bundle from bash to Node (zero
  dependencies, Node 18+). All `.sh` scripts are replaced by `.js`; `curl`,
  `jq`, and `date` are no longer required. Skills, install, credential setup,
  and the doctor health check now run on macOS, Linux, and **native Windows**.
- **BREAKING**: Skill invocation contract changed — `SKILL.md` files now run
  `node <path>` instead of a `.sh` script. Existing bash installs must be
  re-installed.
- Add a pure-Node `npx` installer with a simplified flow: choose location
  (global `~` or repo) → choose coding agent(s) → confirm → install. The
  advanced shared-folder mode remains available via `--target`.
- The `~/.super8-studio.config` install-registry format is preserved.
- **BREAKING**: The API URL is now fixed at install time and recorded in the
  install registry (`channel` + `api_url`). `npx … install` selects production
  by default; internal `--staging` / `--api-url` options select other
  endpoints. Skills no longer read `S8_API_URL` from the environment,
  `.super8-studio.env`, or plugin options — it is resolved from the registry
  (or a built-in production fallback for plugin installs).
- **BREAKING**: `setup` no longer prompts for or stores an API URL; it derives
  the Console/API from the registry channel and writes only the session token
  (+ optional org). Plugin installs are always production; `S8_API_URL` is
  removed from plugin `userConfig`. Internal staging testers must re-run
  `install --staging`.

## 1.0.0

- Add canonical skill bundle installer for direct skills installation.
- Add shared runtime scripts for Super 8 Studio Developer API workflows.
- Add plugin, marketplace, npm, and validation metadata for multi-channel
  installation readiness.
