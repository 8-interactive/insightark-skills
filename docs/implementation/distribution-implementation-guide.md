# Distribution Implementation Guide

This guide records the current distribution decisions for the SUPER 8 Studio
InsightArk Skills repository. Use it as the implementation reference when adding,
changing, or validating install paths.

## Goal

Support more distribution paths without forking the actual skills.

The canonical payload is always:

```text
skills/
├── _super8-studio-api-shared/
└── super8-studio-*/SKILL.md
```

All distribution layers must expose this same `skills/` content. Do not create
separate copies of skills for Codex, Claude, Vercel, or curl unless a platform
forces a generated package artifact.

## Current Decision

Use one public repository with multiple platform-specific metadata layers.

```text
.
├── skills/                         # Canonical Agent Skills payload
├── .codex-plugin/plugin.json       # Codex plugin manifest
├── .agents/plugins/marketplace.json # Codex repo marketplace catalog
├── .claude-plugin/plugin.json      # Claude plugin manifest
├── .claude-plugin/marketplace.json # Claude marketplace catalog
├── package.json                    # npm / Vercel skills-add package metadata
├── install.sh                      # Direct installer
├── setup-env.sh                    # Credential setup
├── uninstall.sh                    # Direct uninstall
└── scripts/
    ├── register-install.sh         # Optional registry helper
    ├── super8-skills-cli.js        # Package CLI adapter
    └── validate-skills.sh          # Release validation
```

Codex and Claude have separate plugin formats. Keep both manifests in the same
repo, but do not try to make one manifest serve both platforms.

## Distribution Matrix

| Path | Purpose | Required files | Runs `install.sh`? | Writes `~/.super8-studio.config`? |
| --- | --- | --- | --- | --- |
| curl / tarball | Full direct install | `install.sh`, `setup-env.sh`, `skills/`, `installer/` | Yes | Yes |
| Codex marketplace | Codex plugin discovery/install | `.codex-plugin/plugin.json`, `.agents/plugins/marketplace.json`, `skills/` | Do not assume | Do not assume |
| Claude marketplace | Claude plugin discovery/install | `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `skills/` | Do not assume | Do not assume |
| Vercel `npx skills add --...` | External skills manager compatibility | `package.json`, `skills/`, docs | Unknown until CLI verified | Optional only if a follow-up target path is available |

Important: marketplace installs are plugin discovery/install flows, not shell
installer flows. Do not document them as install hooks unless the target
platform explicitly documents install-time script execution.

## Registry Contract

`~/.super8-studio.config` is the direct installer registry. It is written by
`install.sh` through:

```text
skills/_super8-studio-api-shared/scripts/lib/install-config.sh
```

Registry shape:

```text
layout=<direct|per-agent>
base_dir=<expanded base path>
agents=<comma-separated agent ids>
skills_targets=<comma-separated resolved skills folders>
installed_at=<UTC timestamp>
```

Use the registry when the install path can execute our scripts. If an external
installer only copies files, the registry may not exist. Skills must still guide
users to credential setup through `setup-env.sh`, `~/.super8-studio.env`,
project `.super8-studio.env`, or process environment variables.

When an external installer already copied `skills/` and exposes a known target
directory, run:

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

- `.codex-plugin/plugin.json` must point `skills` to `../skills/`.
- `.agents/plugins/marketplace.json` should point `source.path` to `./` for
  this repo-root plugin layout.
- Codex lifecycle hooks are agent-loop hooks, not marketplace install hooks.
- Credential setup is a follow-up workflow, not guaranteed install-time code.

### Claude

Files:

```text
.claude-plugin/plugin.json
.claude-plugin/marketplace.json
```

Rules:

- `.claude-plugin/plugin.json` must point `skills` to `../skills/`.
- `.claude-plugin/marketplace.json` should point `source` to `./` for this
  repo-root plugin layout.
- Claude installs marketplace plugins into a plugin cache. Do not rely on
  paths outside the installed plugin package.
- Claude hooks are platform lifecycle hooks, not proof that marketplace install
  can run arbitrary setup scripts.

### Vercel `npx skills add --...`

Treat this as an external skills-manager compatibility target.

Before publishing this path, verify the current `skills` CLI behavior:

- Accepted source formats: npm package, Git URL, tarball, local path, or
  subdirectory.
- Whether it installs one skill, many skills, or a directory of skills.
- Whether it preserves `_super8-studio-api-shared/`.
- Whether it preserves executable bits on shell scripts.
- Whether it runs npm lifecycle scripts, package binaries, or install hooks.
- Where it installs skills for each supported client.

Until these are verified, docs should say that registry setup is optional and
depends on whether the CLI exposes a follow-up target path.

## File Responsibilities

| File | Responsibility |
| --- | --- |
| `skills/` | Single source of truth for skills and shared runtime. |
| `install.sh` | Copy `skills/` to selected direct-install targets and write registry. |
| `setup-env.sh` | Configure Developer API credentials and run doctor. |
| `uninstall.sh` | Remove direct-installed bundle dirs using registry or selected targets. |
| `scripts/register-install.sh` | Optional follow-up registry writer when another tool copied files. |
| `scripts/validate-skills.sh` | Static validation for all distribution metadata and skill frontmatter. |
| `.codex-plugin/plugin.json` | Codex plugin manifest. |
| `.agents/plugins/marketplace.json` | Codex repo marketplace catalog. |
| `.claude-plugin/plugin.json` | Claude plugin manifest. |
| `.claude-plugin/marketplace.json` | Claude marketplace catalog. |
| `package.json` | npm package metadata for Vercel/skills-add compatibility experiments. |
| `docs/implementation/vercel-skills-add.md` | Current assumptions and open questions for `npx skills add --...`. |

## Adding a New Distribution Path

1. Keep `skills/` unchanged unless the skill itself changes.
2. Add platform-specific metadata in a platform-specific directory.
3. Do not make the new path responsible for credential setup unless the platform
   documents a secure config or install-time flow.
4. If the path can execute scripts, delegate to `install.sh` or
   `scripts/register-install.sh`; do not reimplement registry writes.
5. Update `scripts/validate-skills.sh` so the new contract is checked.
6. Update README and release docs with the exact support status.
7. Run validation:

```bash
bash scripts/validate-skills.sh
```

## Release Checklist

Before publishing:

- `bash scripts/validate-skills.sh` passes.
- Versions match across:
  - `skills/_super8-studio-api-shared/VERSION`
  - `.codex-plugin/plugin.json`
  - `.claude-plugin/plugin.json`
  - `.claude-plugin/marketplace.json`
  - `package.json`
- Direct tarball install is tested with a temporary `HOME`.
- Codex marketplace discovery is tested.
- Claude marketplace discovery is tested.
- `npx skills add --...` behavior is tested against the current CLI.
- No docs claim marketplace install hooks unless verified from official
  platform documentation.
- No screenshots, fixtures, or docs contain real tokens or customer PII.

## Known Open Questions

- Exact Vercel `npx skills add --...` source syntax.
- Whether Vercel skills-add can install a multi-skill bundle with a shared
  underscore-prefixed runtime directory.
- Whether Vercel skills-add preserves executable bits.
- Whether Codex or Claude should use platform-native secure configuration for
  `S8_SESSION_TOKEN` instead of `.super8-studio.env` in marketplace installs.
- Whether assets and screenshots are required for public marketplace listing.
