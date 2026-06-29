## Why

Clients need a public, one-line install (`npx … install`) for every supported agent, while the source repository stays private for now. Publishing the bundle to public npm decouples the public distribution artifact from the private source, so clients install without npm auth or repo access. Because clients do not need the managed-plugin experience (they only need the skills installed), a single public npm package covers every agent — no public mirror repo is required.

## What Changes

- Publish the bundle to **public npm** as `@8-interactive/insightark-skills` (the `@8-interactive` org already exists).
- **BREAKING (package identity)**: Rename the npm package from `@super8/studio-api-skills` to `@8-interactive/insightark-skills`. Only the npm `name` changes — the `bin` name (`super8-studio-api-skills`) and the plugin manifest identifiers stay as-is for now.
- Set `publishConfig.access` from `restricted` to `public`.
- Add a CI publish-on-tag job that runs `npm publish`, gated by `validate` + `test` + `smoke` (no publish if any fails).
- Update all client-facing `npx` commands (README EN + 中文, CHANGELOG) to `@8-interactive/insightark-skills`.
- Steer Claude Code / Codex clients to `npx … install --agents claude-code|codex` (skills copied into their folders) instead of the private-repo plugin marketplace. Keep the marketplace sections noted for when the repo becomes public ("暫時").
- Document that the published artifact contains only the runtime `files` (no git history, `openspec/`, or `test/`) and must be scanned for secrets before release.

## Capabilities

### New Capabilities
- `distribution`: How the bundle is published and how clients install it — public npm package identity, the supported client install command(s), the release gate (validate/test/smoke on tag), published-artifact contents, and the private-source / public-artifact boundary.

### Modified Capabilities
<!-- None. Installer/runtime/setup behavior is unchanged; this is packaging + release only. -->

## Impact

- **Config**: `package.json` (`name`, `publishConfig.access`); new CI workflow job for publish-on-tag (uses an `NPM_TOKEN` secret).
- **Docs**: README (EN + 中文) npx commands + Claude/Codex client steering; `CHANGELOG.md`.
- **Release prerequisites**: PR #2 (Node re-platform) and #3 (fix-api-url-at-install) must be merged to `main` before the first publish so the published version is the Node bundle, not the old bash one.
- **Access/security**: `@8-interactive` npm org membership for the publisher; `NPM_TOKEN` in CI secrets; public npm exposes all shipped skill scripts (the bundle only calls the documented Developer API).
- **No behavior change** to the installer, runtime, or setup beyond the package name surfaced in commands.
