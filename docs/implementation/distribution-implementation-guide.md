# Distribution Implementation Guide

This guide records the current distribution decisions for the SUPER 8 Studio
InsightArk Skills repository. Use it as the implementation reference when
adding, changing, or validating install paths.

## Goal

Support more distribution paths without forking the actual skills.

The canonical payload is always:

```text
skills/
├── _insightark-shared/
└── insightark-*/SKILL.md
```

All distribution layers must expose this same `skills/` content. Do not
create separate copies of skills for Codex, Claude, Vercel, or curl unless a
platform forces a generated package artifact.

## Current Decision

Use one public repository with multiple platform-specific metadata layers.

```text
.
├── skills/                          # Canonical Agent Skills payload
├── .codex-plugin/plugin.json        # Codex plugin manifest
├── .agents/plugins/marketplace.json # Codex repo marketplace catalog
├── .claude-plugin/plugin.json       # Claude plugin manifest
├── .claude-plugin/marketplace.json  # Claude marketplace catalog
├── .cursor-plugin/plugin.json       # Cursor plugin manifest
├── package.json                     # Private dev tooling only (npm run validate); NOT customer distribution
├── install.sh                       # Direct installer
├── setup-env.sh                     # Credential setup
├── uninstall.sh                     # Direct uninstall
├── installer/common.sh              # Shared bash helpers for install/uninstall
└── scripts/
    ├── register-install.sh          # Optional registry helper
    ├── validate-skills.sh           # Release validation
    └── validate-mcp-skills.js       # MCP skill content validation
```

Codex and Claude have separate plugin formats. Keep both manifests in the
same repo, but do not try to make one manifest serve both platforms.

## Customer vs maintainer artifacts

| Artifact | In public mirror tree? | Purpose |
| --- | --- | --- |
| `skills/`, plugin manifests, `install.sh`, MCP JSON | Yes | Customer install |
| `package.json` | **No** | Monorepo dev only (`npm run validate`) |
| `scripts/build-release-dir.sh`, `publish-to-github.sh`, `gen-mcp-from-release.sh` | **No** | CI only |
| `.github/workflows/` | **No** | Retired (Drone in monorepo is CI) |

Do **not** treat `npm pack` contents as a customer distribution contract.
`validate-release-tree.sh` is the authoritative check for mirror contents.

## Distribution Matrix

| Path | Purpose | Required files | Runs `install.sh`? | Writes `~/.insightark.config`? |
| --- | --- | --- | --- | --- |
| curl / tarball | Full direct install | `install.sh`, `setup-env.sh`, `skills/`, `installer/` | Yes | Yes |
| GitHub mirror clone | Manual / Cursor local repo | Same as tarball (public mirror tree) | Optional (`./install.sh`) | If `install.sh` used |
| Codex marketplace | Codex plugin discovery/install | `.codex-plugin/plugin.json`, `.agents/plugins/marketplace.json`, `skills/` | No | No |
| Claude marketplace | Claude plugin discovery/install | `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `skills/` | No | No |
| Cursor local repo | Cursor plugin install | `.cursor-plugin/plugin.json`, `skills/`, `mcp.json` | No | No |

**Retired:** `npm install` / `npx @8-interactive/insightark-skills` — not a
supported customer path. See `plugin-release-process.md`.

Important: marketplace installs are plugin discovery/install flows, not
shell installer flows. Do not document them as install hooks unless the
target platform explicitly documents install-time script execution.

## Registry Contract

`~/.insightark.config` is the direct installer registry. It is written by
`install.sh` through:

```text
skills/_insightark-shared/scripts/lib/install-config.sh
```

Registry shape:

```text
layout=<direct|per-agent>
base_dir=<expanded base path>
agents=<comma-separated agent ids>
skills_targets=<comma-separated resolved skills folders>
installed_at=<UTC timestamp>
```

Use the registry when the install path can execute our scripts. If an
external installer only copies files, the registry may not exist. Skills
must still guide users to credential setup through `setup-env.sh`,
`~/.insightark.env`, project `.insightark.env`, or process environment
variables.

When an external installer already copied `skills/` and exposes a known
target directory, run:

```bash
scripts/register-install.sh --target <skills-dir>
./setup-env.sh
```

Do not duplicate registry-writing logic in each distribution path.

## Platform Notes

### Codex

Files:

```text
.codex-plugin/plugin.json
.agents/plugins/marketplace.json
```

Rules:

- `.codex-plugin/plugin.json` must point `skills` to `./skills/` (resolved
  relative to the repo root).
- `.agents/plugins/marketplace.json` should point `source.path` to `./` for
  this repo-root plugin layout.
- Codex lifecycle hooks are agent-loop hooks, not marketplace install hooks.
- Credential setup is a follow-up workflow (`./setup-env.sh`), not
  guaranteed install-time code.

### Claude

Files:

```text
.claude-plugin/plugin.json
.claude-plugin/marketplace.json
hooks/hooks.json
```

Rules:

- `.claude-plugin/plugin.json` must point `skills` to `./skills/` (resolved
  relative to the repo root).
- `.claude-plugin/marketplace.json` should point `source` to `./` for this
  repo-root plugin layout.
- Claude installs marketplace plugins into a plugin cache. Do not rely on
  paths outside the installed plugin package — use `${CLAUDE_PLUGIN_ROOT}`
  (see `hooks/hooks.json`).
- Claude's `SessionStart` hook runs
  `skills/_insightark-shared/scripts/doctor.sh --soft-fail`; this is a
  platform lifecycle hook, not proof that marketplace install can run
  arbitrary setup scripts. Credentials come from `plugin.json`'s
  `userConfig` (`S8_API_URL`, `S8_SESSION_TOKEN`) stored in the system
  keychain.

## File Responsibilities

| File | Responsibility |
| --- | --- |
| `skills/` | Single source of truth for skills and shared runtime. |
| `install.sh` | Copy `skills/` to selected direct-install targets and write registry. |
| `setup-env.sh` | Configure Developer API credentials and run doctor. |
| `uninstall.sh` | Remove direct-installed bundle dirs using registry or selected targets. |
| `scripts/register-install.sh` | Optional follow-up registry writer when another tool copied files. |
| `scripts/validate-skills.sh` | Static validation for all distribution metadata and skill frontmatter. |
| `scripts/validate-mcp-skills.js` | Validates MCP-facing skill content against the hosted MCP tool catalog. |
| `.codex-plugin/plugin.json` | Codex plugin manifest. |
| `.agents/plugins/marketplace.json` | Codex repo marketplace catalog. |
| `.claude-plugin/plugin.json` | Claude plugin manifest. |
| `.claude-plugin/marketplace.json` | Claude marketplace catalog. |
| `.cursor-plugin/plugin.json` | Cursor plugin manifest. |
| `package.json` | **Maintainer only** — private dev scripts; excluded from mirror tree. |
| `scripts/publish-to-github.sh` | Sync mirror tree to GitHub (Drone CI; not in customer bundle). |

## Adding a New Distribution Path

1. Keep `skills/` unchanged unless the skill itself changes.
2. Add platform-specific metadata in a platform-specific directory.
3. Do not make the new path responsible for credential setup unless the
   platform documents a secure config or install-time flow.
4. If the path can execute scripts, delegate to `install.sh` or
   `scripts/register-install.sh`; do not reimplement registry writes.
5. Update `scripts/validate-skills.sh` so the new contract is checked.
6. Update README (EN + 中文) and release docs with the exact support status.
7. Run validation:

```bash
bash scripts/validate-skills.sh
```

## Release Checklist

Before publishing (see also
`docs/implementation/plugin-release-process.md`):

- `npm run validate` passes (`bash scripts/validate-skills.sh` +
  `node scripts/validate-mcp-skills.js`).
- Versions match across (`validate-skills.sh` enforces these four):
  - `skills/_insightark-shared/VERSION`
  - `.codex-plugin/plugin.json`
  - `.claude-plugin/plugin.json`
  - `.cursor-plugin/plugin.json`
- `bash scripts/validate-release-tree.sh --dir <mirror-tree>` passes for staging and production fixtures.
- Public mirror tree does **not** include `package.json`, npm publish metadata, or CI-only scripts.
- Direct tarball install is tested with a temporary `HOME`.
- Codex marketplace discovery is tested.
- Claude marketplace discovery is tested.
- No docs claim marketplace install hooks unless verified from official
  platform documentation.
- No screenshots, fixtures, or docs contain real tokens or customer PII.

## Known Open Questions

- Whether Codex or Claude should use platform-native secure configuration
  for `S8_SESSION_TOKEN` instead of `.insightark.env` in marketplace
  installs (Claude already does, via `userConfig` + system keychain; Codex
  does not yet).
- Whether assets and screenshots are required for public marketplace
  listing.
