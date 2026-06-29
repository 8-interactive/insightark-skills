# distribution Specification

## Purpose

Defines how the skills bundle is distributed: published as a public npm package installable via `npx` for any supported agent, released through gated tag-triggered CI, with a controlled artifact allowlist and a private-source / public-artifact split.
## Requirements
### Requirement: Public npm package identity

The bundle SHALL be published to the public npm registry as `@8-interactive/insightark-skills` with `publishConfig.access` set to `public`. The package SHALL declare a `bin` so it is runnable via `npx`. The `bin` command name and the plugin manifest identifiers SHALL be `insightark-skills`, aligned with the unscoped npm package name.

#### Scenario: Public, auth-free resolution

- **WHEN** any user runs `npx @8-interactive/insightark-skills install` without npm authentication or repository access
- **THEN** npm resolves and runs the package's bin

#### Scenario: Access is public

- **WHEN** the package is published
- **THEN** `publishConfig.access` is `public` and the package is installable by anyone

#### Scenario: Identifiers are aligned

- **WHEN** the `package.json` `bin` key and the `name` field of `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `.codex-plugin/plugin.json`, and `.agents/plugins/marketplace.json` are read
- **THEN** each is `insightark-skills`

### Requirement: Client install command for all agents

Clients SHALL install for any supported agent through `npx @8-interactive/insightark-skills install`, including the non-interactive `--agents` form, without requiring the source repository or the plugin marketplace.

#### Scenario: Claude Code client via npx

- **WHEN** a Claude Code user runs `npx @8-interactive/insightark-skills install --agents claude-code`
- **THEN** the skills are installed into the Claude Code skills folder without using the plugin marketplace or accessing the source repo

#### Scenario: Other agents via npx

- **WHEN** a user runs `npx @8-interactive/insightark-skills install --agents cursor,codex`
- **THEN** the skills are installed into each agent's skills folder

### Requirement: Gated, tag-triggered release

Publishing SHALL be performed by CI on a pushed version tag and SHALL be blocked unless `validate`, `test`, and `smoke` all pass on the release commit. Publishing SHALL use a credential scoped to publish under `@8-interactive`.

#### Scenario: Tag triggers a gated publish

- **WHEN** a version tag is pushed and validate + test + smoke all pass
- **THEN** CI publishes the package to public npm

#### Scenario: Failing checks block publish

- **WHEN** any of validate, test, or smoke fails on the release commit
- **THEN** CI does not publish

### Requirement: Published artifact contents

The published package SHALL contain only the runtime files in the `files` allowlist and SHALL NOT include git history, `openspec/`, `test/`, or agent-guidance files. The shipped files SHALL be free of secrets/tokens.

#### Scenario: Artifact excludes development files

- **WHEN** the package is packed for publish
- **THEN** it contains the installer, skills, scripts, hooks, plugin manifests, and docs, and excludes `openspec/`, `test/`, and `.claude`/agent-guidance files

#### Scenario: No secrets shipped

- **WHEN** the package is packed for publish
- **THEN** a secret scan of the shipped files finds no credentials or tokens

### Requirement: Private source, public artifact

The source repository MAY remain private while the published npm artifact is public. Client installation SHALL NOT require access to the source repository.

#### Scenario: Private repo does not block install

- **WHEN** the source repository is private and a client installs via `npx @8-interactive/insightark-skills install`
- **THEN** the install succeeds using only the public npm artifact

