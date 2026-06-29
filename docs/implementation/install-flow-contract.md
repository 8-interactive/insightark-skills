# Multi-Channel Install Flow Contract

This repository has one canonical payload: `skills/`. Every install path should
make that payload available to the user's agent. Only install paths that execute
our scripts should record installed skills paths in `~/.super8-studio.config`.

## Shared State

`installer/install.js` is the source of truth for registry writes. It calls
`super8_write_install_config` from
`skills/_super8-studio-api-shared/scripts/lib/install-config.js`.

The registry stores:

```text
layout=<direct|per-agent>
base_dir=<expanded base path>
agents=<comma-separated agent ids>
skills_targets=<comma-separated resolved skills folders>
installed_at=<UTC timestamp>
```

`the Node setup (super8-studio-api-skills setup)`, `the Node uninstaller`, and runtime credential loading use this registry
to find installed skill directories when it exists. Marketplace and external
skills-manager installs may not run repository scripts, so skills must also be
able to guide users toward `the Node setup (super8-studio-api-skills setup)` or a manual env file fallback.

## 1. curl / Tarball

Current flow:

```bash
curl -LO https://downloads.no8.io/main/releases/skills/super8-studio-api-skills-latest.tar.gz
tar -xzf super8-studio-api-skills-latest.tar.gz
cd super8-studio-api-skills
npx @super8/studio-api-skills install
npx @super8/studio-api-skills setup
```

Recommended bootstrap flow:

1. Download the release tarball.
2. Verify checksum when available.
3. Extract to a temporary or user cache directory.
4. Run `npx @super8/studio-api-skills install` with either interactive prompts or passed-through
   non-interactive options.
5. Run or instruct the user to run `npx @super8/studio-api-skills setup`.

Registry handling: `installer/install.js` writes `~/.super8-studio.config` after resolving
the target directories.

## 2. Codex add marketplace

Codex marketplace installation should install the plugin package, but it should
not silently assume Super 8 credentials are configured.

Codex-specific files:

```text
.codex-plugin/plugin.json
.agents/plugins/marketplace.json
```

Do not assume Codex marketplace install executes `installer/install.js`. Codex plugin
installation makes skills available through the plugin system; credential setup
must be a documented follow-up step or a skill-guided workflow.

If users want direct skills copied into a specific local skills directory
instead of plugin-managed discovery, use:

```bash
npx @super8/studio-api-skills install --target ~/.agents/skills
npx @super8/studio-api-skills setup
```

Registry handling: Codex marketplace installs may not write
`~/.super8-studio.config`. Direct installs do.

## 3. Claude add marketplace

Claude marketplace installation uses Claude's plugin format and marketplace
catalog.

Claude-specific files:

```text
.claude-plugin/plugin.json
.claude-plugin/marketplace.json
```

Claude Code installs marketplace plugins into its plugin cache. Do not assume
the install flow can run `installer/install.js`. Use plugin skills, user-facing setup
instructions, or Claude `userConfig` when a future release supports the exact
credential shape this package needs.

Registry handling: Claude marketplace installs may not write
`~/.super8-studio.config`. Direct installs do.

## 4. Vercel `npx skills add --...`

This path targets the Vercel-style skills installer command:

```bash
npx skills add --...
```

Treat this as an external skills-manager path. The exact source syntax and
lifecycle behavior must be verified against the current CLI before publishing.

Do not assume `npx skills add --...` executes `installer/install.js`, npm lifecycle
scripts, or package binaries unless the CLI documentation explicitly guarantees
that behavior.

If the CLI can run a follow-up command after copying skills, use:

```bash
scripts/register-install.js --target <skills-target>
npx @super8/studio-api-skills setup
```

If it cannot run follow-up commands, rely on `~/.super8-studio.env`, process
environment variables, or a manual `the Node setup (super8-studio-api-skills setup)` run from a downloaded package.

## Answering the Current Flow Questions

### How should `npx @super8/studio-api-skills install` be triggered outside curl?

Use `installer/install.js` as the canonical installer only for channels that execute our
scripts:

- curl/tarball: call `npx @super8/studio-api-skills install`.
- Explicit npm package binary: may call `bash npx @super8/studio-api-skills install` if users invoke it.
- Codex/Claude marketplaces: do not assume install-time script execution.
- Vercel `npx skills add --...`: verify CLI lifecycle before relying on script
  execution.

The adapters should not duplicate target resolution logic.

### How should `~/.super8-studio.config` be recorded outside curl?

Do not write the file independently in each channel when `installer/install.js` can run.
Call `installer/install.js`, because it already writes the registry through
`super8_write_install_config`.

If an install platform copies files itself and later exposes a known target path,
use `scripts/register-install.js --target <dir>` as an optional follow-up. If no
follow-up command can run, treat the registry as unavailable and rely on env
fallbacks.

## Verification Matrix

| Channel | Must verify |
| --- | --- |
| curl/tarball | Tarball extracts, `installer/install.js` copies `skills/`, registry exists, `the Node setup (super8-studio-api-skills setup) --check` runs. |
| Codex marketplace | `.codex-plugin/plugin.json` resolves `../skills/`, `.agents/plugins/marketplace.json` resolves repository root, setup docs do not assume install hooks. |
| Claude marketplace | `.claude-plugin/plugin.json` resolves `../skills/`, `.claude-plugin/marketplace.json` resolves repository root, setup docs do not assume install hooks. |
| Vercel skills add | Package includes all runtime files, docs state CLI lifecycle assumptions, registry is optional unless a follow-up target path is available. |
