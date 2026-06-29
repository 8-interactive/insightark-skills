## ADDED Requirements

### Requirement: API URL resolution

Skills SHALL resolve the API root (`S8_API_ROOT`) from the install registry's `api_url` value when present, and otherwise fall back to a built-in production constant (`https://api-next.no8.io`). The API URL SHALL NOT be read from the `S8_API_URL` environment variable, from any `.super8-studio.env` file, or from `CLAUDE_PLUGIN_OPTION_S8_API_URL`. A trailing slash on the resolved URL SHALL be stripped.

#### Scenario: Registry api_url is used

- **WHEN** `~/.super8-studio.config` records `api_url=https://stage-api-next.no8.io` and a skill runs
- **THEN** the skill calls that endpoint as the API root

#### Scenario: Production fallback without a registry

- **WHEN** no install registry exists (for example a plugin install) and a skill runs
- **THEN** the skill uses the built-in production endpoint `https://api-next.no8.io`

#### Scenario: Environment variable cannot override the fixed URL

- **WHEN** `S8_API_URL` is set in the process environment to a different value than the registry `api_url`
- **THEN** the skill ignores the environment variable and uses the registry `api_url`

## MODIFIED Requirements

### Requirement: Credential resolution and load order

Skills SHALL resolve credentials — `S8_SESSION_TOKEN` and optional `S8_ORG_ID` — using the precedence: process environment and `CLAUDE_PLUGIN_OPTION_S8_*` mappings (highest) → repository `./.super8-studio.env` → skills-install-directory env files listed in the install registry → user `~/.super8-studio.env` (lowest). When `S8_SESSION_TOKEN` or `S8_ORG_ID` is unset in the process environment but the corresponding `CLAUDE_PLUGIN_OPTION_S8_*` is set, the value SHALL be mapped. The API URL is NOT a credential and is resolved separately (see "API URL resolution").

#### Scenario: Process environment wins for the token

- **WHEN** `S8_SESSION_TOKEN` is set in the process environment and a different value exists in `~/.super8-studio.env`
- **THEN** the script uses the process-environment value

#### Scenario: Plugin option mapping

- **WHEN** `S8_SESSION_TOKEN` is unset but `CLAUDE_PLUGIN_OPTION_S8_SESSION_TOKEN` is set
- **THEN** the script uses the plugin option value as `S8_SESSION_TOKEN`

#### Scenario: Repo env file overrides user env file

- **WHEN** both `./.super8-studio.env` and `~/.super8-studio.env` define `S8_ORG_ID` and no process value is set
- **THEN** the repository file value takes precedence

#### Scenario: S8_API_URL in an env file is ignored

- **WHEN** `~/.super8-studio.env` contains `S8_API_URL`
- **THEN** the script does not use it for the API root (the registry or production fallback is used instead)

#### Scenario: Missing token produces actionable help

- **WHEN** `S8_SESSION_TOKEN` cannot be resolved from any source
- **THEN** the script prints which sources were checked, the load priority, and how to configure the token, and exits non-zero
