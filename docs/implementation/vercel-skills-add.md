# Vercel Skills Add Distribution

This path targets the Vercel-style skills installer command:

```bash
npx skills add --...
```

The exact flags and package source syntax must be verified against the current
`skills` CLI release before publishing. This repository should treat that CLI
as an external installer, not as a shell hook we control.

## Compatibility Target

The package should expose a plain Agent Skills payload and avoid assuming
install-time code execution.

Canonical payload:

```text
skills/
├── _super8-studio-api-shared/
└── super8-studio-*/SKILL.md
```

Package metadata:

```text
package.json
.codex-plugin/plugin.json
.claude-plugin/plugin.json
.agents/plugins/marketplace.json
.claude-plugin/marketplace.json
```

## Expected Installation Model

Assume `npx skills add --...` copies skill directories into a target skills
location. Do not assume it will run `install.sh`, npm `postinstall`, package
`bin`, or any custom lifecycle hook unless the CLI documentation explicitly
guarantees that behavior.

If the CLI supports selecting a source subdirectory, point it at `skills/`.
If the CLI expects package-root skills, publish a package variant or generated
artifact where the package root contains the expected skills layout.

## Registry Implication

Because this path may not run repository scripts, `~/.super8-studio.config`
should be optional for skills discovered through `npx skills add --...`.

Skills should continue to work through the runtime environment load order:

1. Process environment variables.
2. Project `.super8-studio.env`.
3. Skills-directory `.super8-studio.env` when the install path is known.
4. User fallback `~/.super8-studio.env`.

If the CLI exposes a post-install command or prints a follow-up command, use one
of these:

```bash
./setup-env.sh
```

or, if files were copied by the CLI and only registry metadata is missing:

```bash
scripts/register-install.sh --target <skills-target>
./setup-env.sh
```

## Open Questions Before Public Release

Verify with the actual `skills` CLI:

- What source formats does `npx skills add --...` accept: npm package, Git URL,
  tarball, local path, or subdirectory?
- Does it copy a single skill, multiple skills, or an entire skills directory?
- Where does it install skills for Codex, Claude, Cursor, and other clients?
- Does it execute npm lifecycle scripts, package binaries, or declared install
  hooks?
- Can it install shared support directories such as
  `_super8-studio-api-shared/`?
- Can it preserve executable bits for `*.sh` scripts?

Until these are confirmed, document this as a compatibility target rather than
the primary installation path.
