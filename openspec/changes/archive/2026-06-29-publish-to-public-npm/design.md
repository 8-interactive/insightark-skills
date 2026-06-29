## Context

The bundle is a zero-dependency Node package with a `bin` (`insightark-skills` → `scripts/super8-skills-cli.js`) and a `files` allowlist (`.claude-plugin/`, `.codex-plugin/`, `hooks/`, `skills/`, `docs/`, `installer/`, `scripts/`, README/SECURITY/CHANGELOG). `publishConfig.access` is currently `restricted` and the name is `@super8/studio-api-skills`, which mismatches the GitHub org/repo (`8-interactive/insightark-skills`). Two client install paths exist: the Claude Code / Codex plugin marketplace (git-repo based, `source: "./"`) and `npx <package>`.

Constraints settled during exploration: source repo stays private for now; the `npx … install` command must be public; both agent families must work; clients do **not** need the managed-plugin experience (skills-installed-and-usable is enough).

## Goals / Non-Goals

**Goals:**
- A public, auth-free `npx @8-interactive/insightark-skills install` for every supported agent.
- Keep the source repo private; expose only the published runtime artifact.
- Automated, gated publish on version tag.

**Non-Goals:**
- No public mirror repo and no managed-plugin marketplace path for clients (not needed — clients use `npx … install --agents`).
- No change to installer/runtime/setup behavior.
- No rename of the `bin` command or plugin manifest identifiers (deferred).
- No private/scoped-restricted npm (the package is public).

## Decisions

### D1: Public npm is the distribution channel
Publish `@8-interactive/insightark-skills` to public npm; `npx @8-interactive/insightark-skills install` is the single client entry point for all agents.
- **Why**: It is the only channel that gives a public, auth-free install while keeping the source repo private — npm cleanly separates the published artifact from the source. `npx`-from-GitHub and the plugin marketplace both require exposing the private repo or issuing client credentials.
- **Alternatives**: `npx github:…` (rejected — needs repo access); tarball URL (rejected — ugly command, manual version discovery); private scoped npm (rejected — clients would need tokens).

### D2: Rename npm name only; defer bin/plugin identifiers
Change `package.json` `name` to `@8-interactive/insightark-skills`. Leave `bin` (`insightark-skills`) and `.claude-plugin`/`.codex-plugin`/marketplace identifiers unchanged.
- **Why**: Aligns the public command with the org/repo and resolves the `@super8` mismatch with minimal churn. `npx @scope/name` runs the package's single `bin` regardless of the bin's name, so the rename is invisible to clients.
- **Trade-off**: A globally-installed CLI would still be named `insightark-skills`; documented as a known minor inconsistency, to be aligned later if desired.

### D3: Publish is gated and tag-triggered
A CI job publishes on a pushed version tag, only after `npm run validate`, `npm test`, and `npm run smoke` pass on the release commit. Uses an `NPM_TOKEN` repo secret with publish rights to `@8-interactive`.
- **Why**: Prevents shipping a broken or untested bundle; tags make releases explicit and versioned.
- **Alternatives**: Publish on every push to `main` (rejected — too easy to ship accidental/unversioned releases); manual local `npm publish` (rejected — unreproducible, easy to forget the gate).

### D4: Clients (all agents) install via npx; marketplace path parked
README directs Claude Code / Codex clients to `npx @8-interactive/insightark-skills install --agents claude-code|codex`. The plugin-marketplace sections are retained but marked as available when the repo is public.
- **Why**: The marketplace is git-repo based; a private repo blocks external clients, and clients do not need managed-plugin features. One npx path covers everyone.

### D5: Published artifact = runtime only, secret-scanned
The `files` allowlist already excludes `openspec/`, `test/`, `AGENTS.md`, `CLAUDE.md`, and git history. Before release, scan the shipped files for secrets/tokens.
- **Why**: Public npm exposes every shipped file. The bundle only calls the documented Developer API, so its scripts are safe to publish, but a scan guards against accidental inclusion.

## Risks / Trade-offs

- **First publish ships the wrong version** → If published before PR #2/#3 merge to `main`, clients get the old bash bundle. Mitigation: gate the first release on those merges; tag only from the Node `main`.
- **Public exposure of skill scripts** → All shipped `.js` become world-readable. Mitigation: secret scan in the release gate; the bundle is API-client code with no embedded credentials.
- **`NPM_TOKEN` leakage** → A publish token in CI is sensitive. Mitigation: use a granular automation token scoped to publish for `@8-interactive`; store as a masked CI secret; never echo it.
- **Name/bin inconsistency confusion** → Package `@8-interactive/insightark-skills` vs bin `insightark-skills`. Mitigation: document; only visible on global installs, not via `npx`.
- **Version drift across manifests** → `validate` already enforces version sync between `package.json`, both plugin manifests, and the bundle `VERSION`; keep that check in the release gate.

## Migration Plan

1. Merge PR #2 (Node re-platform) and #3 (fix-api-url-at-install) to `main`.
2. Set `package.json` `name` → `@8-interactive/insightark-skills`, `publishConfig.access` → `public`.
3. Update README (EN + 中文), CHANGELOG, and openspec references to the new npx command; steer Claude/Codex clients to `npx … install --agents`.
4. Add the CI publish-on-tag job (validate + test + smoke gate; `NPM_TOKEN`).
5. Verify `npm pack` contents (allowlist) and run a secret scan.
6. Tag the release; CI publishes; verify `npx @8-interactive/insightark-skills@<version> install` end to end.
7. **Rollback**: `npm deprecate` the bad version (npm forbids true unpublish after 72h / for widely-used versions) and publish a fixed patch; revert config changes if abandoning.

## Open Questions

- Version policy for the first public release: keep `1.0.0` (current) or start at `0.x` to signal early access? Leaning: bump to a fresh `1.0.0` only once `main` carries the Node bundle, since the published package is effectively the first real distribution.
