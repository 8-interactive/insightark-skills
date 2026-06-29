## Why

API URL is currently a user-configurable value resolved at `setup` time (interactive Production/Custom prompt, `--api-url`, or a CI-baked RELEASE file) and overridable by the `S8_API_URL` environment variable at runtime. This is more surface area than needed: the environment is really a binary choice (production vs. an internal staging endpoint). Making API URL an install-time constant removes a class of misconfiguration (a production user accidentally pointing at staging via a stray env var) and reduces what a user must provide to just a session token.

## What Changes

- Decide the API URL at **install time**, fixed thereafter:
  - `npx … install` → `https://api-next.no8.io` (production, default)
  - `npx … install --staging` → `https://stage-api-next.no8.io` (internal testing; **not documented in README**)
  - `npx … install --api-url <url>` → custom endpoint — a hidden escape hatch for localhost/other environments (**not documented in README**)
- Persist the resolved `channel` and `api_url` in the install registry (`~/.super8-studio.config`).
- **BREAKING**: Runtime API URL is **fixed** — resolved only from the registry, falling back to a built-in production constant when no registry exists (e.g. plugin installs). Skills no longer read `S8_API_URL` from the environment, `.super8-studio.env`, or `CLAUDE_PLUGIN_OPTION_S8_API_URL`.
- **BREAKING**: `setup` no longer asks for or accepts an API URL. It reads the channel from the registry to choose the Console to open and the API to query, and writes only `S8_SESSION_TOKEN` (+ optional `S8_ORG_ID`) — never `S8_API_URL`.
- **BREAKING**: Plugin installs (Claude Code / Codex) are always production. Remove `S8_API_URL` from plugin `userConfig`; keep only `S8_SESSION_TOKEN`.
- Retire the RELEASE file's `api_url` / `console_url` role; the Console base is derived from the channel.
- `--staging` and `--api-url` appear in `install --help`/usage and in code comments, but stay out of the README (internal use only).

## Capabilities

### New Capabilities
<!-- None — this change modifies existing capabilities. -->

### Modified Capabilities
- `skill-runtime`: API URL is resolved from the install registry (or a built-in production fallback), not from the environment or env files. Credential resolution now covers only the session token and org id.
- `skill-installer`: Install resolves and records the API URL/channel (`--staging`, hidden `--api-url`, production default) into the registry.
- `credential-setup`: Setup no longer prompts for or stores an API URL; it derives Console/API targets from the registry channel and writes only the token (+ org).

## Impact

- **Code**: `installer/install.js` (flag parsing + channel/api_url resolution + registry write), `installer/setup.js` (drop API-URL prompt/`--api-url`, read channel from registry, stop writing `S8_API_URL`), `installer/common.js` (channel→api_url/console map), `skills/_super8-studio-api-shared/scripts/lib/install-config.js` (read/write `channel`/`api_url`), `skills/_super8-studio-api-shared/scripts/lib/env.js` (resolve API root from registry + production fallback; stop reading `S8_API_URL`), `doctor.js` (uses resolved root).
- **Manifests**: `.claude-plugin/plugin.json` and `.codex-plugin/plugin.json` `userConfig` — remove `S8_API_URL`.
- **Registry**: `~/.super8-studio.config` gains `channel` and `api_url` keys (existing keys preserved).
- **Docs/Tests**: README stays silent on `--staging`/`--api-url`; CHANGELOG notes BREAKING; env/smoke tests updated for registry-driven API URL.
- **Compatibility**: Existing installs that set `S8_API_URL` (env or `.super8-studio.env`) have it ignored; installs without a registry `api_url` fall back to production. Internal staging testers must re-run `install --staging`.
