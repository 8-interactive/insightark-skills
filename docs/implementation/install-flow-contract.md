# Multi-Channel Install Flow Contract

This repository has one canonical payload: `skills/`. Every install path
should make that payload available to the user's agent. Only install paths
that execute `install.sh` reliably record installed skills paths in
`~/.insightark.config`.

## Shared State

`install.sh` is the source of truth for registry writes. It calls
`super8_write_install_config` from
`skills/_insightark-shared/scripts/lib/install-config.sh`.

The registry (`~/.insightark.config`, mode `600`) stores:

```text
layout=<direct|per-agent>
base_dir=<expanded base path>
agents=<comma-separated agent ids>
skills_targets=<comma-separated resolved skills folders>
installed_at=<UTC timestamp>
```

`setup-env.sh` and skill runtime credential loading use this registry to find
installed skill directories when it exists. Marketplace and external
skills-manager installs may not run `install.sh`, so skills must also be able
to guide users toward `./setup-env.sh` or a manual env file fallback.

## 1. curl / Tarball

Current flow (see `README.md` → Tarball Install):

```bash
curl -L https://downloads.no8.io/main/releases/skills/insightark-skills-v2-latest.tar.gz \
  -o insightark-skills-v2-latest.tar.gz
tar -xzf insightark-skills-v2-latest.tar.gz
cd insightark-skills
./install.sh
./setup-env.sh
```

Registry handling: `install.sh` writes `~/.insightark.config` after
resolving the target directories, before copying files.

## 2. Codex add marketplace

```bash
codex plugin marketplace add 8-interactive/insightark-skills
codex plugin install insightark-skills@insightark-skills
```

Codex-specific files:

```text
.codex-plugin/plugin.json
.agents/plugins/marketplace.json
```

Do not assume the Codex marketplace install runs `install.sh`. Codex plugin
installation makes skills available through the plugin system; credential
setup is a documented follow-up step (`./setup-env.sh`), not an install hook.

If users want direct skills copied into a specific local skills directory
instead of plugin-managed discovery, use:

```bash
./install.sh --target ~/.agents/skills
./setup-env.sh
```

Registry handling: Codex marketplace installs do not write
`~/.insightark.config`. Direct (`./install.sh`) installs do.

## 3. Claude add marketplace

```bash
claude plugin marketplace add 8-interactive/insightark-skills
claude plugin install insightark-skills@insightark-skills
claude plugin enable insightark-skills@insightark-skills
```

Claude-specific files:

```text
.claude-plugin/plugin.json
.claude-plugin/marketplace.json
```

Claude Code installs marketplace plugins into its own plugin cache and does
not run `install.sh`. Credentials are collected through the plugin's
`userConfig` (`S8_API_URL`, `S8_SESSION_TOKEN` in `.claude-plugin/plugin.json`)
and stored in the system keychain; the plugin's `SessionStart` hook runs
`skills/_insightark-shared/scripts/doctor.sh` to surface credential issues.

Registry handling: Claude marketplace installs do not write
`~/.insightark.config`. Direct (`./install.sh`) installs do.

## Answering the current flow questions

### How should `install.sh` be triggered outside curl?

Use `install.sh` as the canonical installer only for channels that execute
our scripts:

- curl/tarball: call `./install.sh`.
- Manual clone/download: call `./install.sh` directly.
- Codex/Claude/Cursor marketplaces: do not assume install-time script execution.

**Retired:** `npx @8-interactive/insightark-skills` / npm registry install. Customers
use tarball, GitHub mirror, or plugin marketplaces only.

### How should `~/.insightark.config` be recorded outside curl?

Do not write the file independently in each channel when `install.sh` can
run — call `install.sh`, because it already writes the registry through
`super8_write_install_config`.

If an install platform copies files itself and later exposes a known target
path, use `scripts/register-install.sh --target <dir>` as an optional
follow-up. If no follow-up command can run, treat the registry as
unavailable and rely on the env file load order in
`skills/_insightark-shared/scripts/lib/env.sh`.

## Verification matrix

| Channel | Must verify |
| --- | --- |
| curl/tarball | Tarball extracts, `install.sh` copies `skills/`, registry exists, `./setup-env.sh --check` passes. |
| Codex marketplace | `.codex-plugin/plugin.json` resolves `skills` (`./skills/`) to the repo root, `.agents/plugins/marketplace.json` `source.path` resolves to repo root, setup docs do not assume install hooks. |
| Claude marketplace | `.claude-plugin/plugin.json` resolves `skills` (`./skills/`) to the repo root, `.claude-plugin/marketplace.json` plugin `source` resolves to repo root, `SessionStart` hook runs `doctor.sh`. |
