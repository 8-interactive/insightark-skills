## MODIFIED Requirements

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
