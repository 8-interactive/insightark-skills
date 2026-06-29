## MODIFIED Requirements

### Requirement: Node-based credential setup

`setup` is **deprecated** in favor of `login`, but SHALL remain functional. It SHALL run as a Node process with no bash dependency, creating or updating the user env file (`~/.super8-studio.env`) with `S8_SESSION_TOKEN` and optional `S8_ORG_ID`, and SHALL print a deprecation notice recommending `login`. Setup SHALL NOT prompt for, accept, or write an API URL: the API environment is fixed at install time (recorded in the registry). Setup SHALL read the registry `channel`/`api_url` to choose which Console to open and which API to query for organizations, and SHALL fall back to production when no registry exists.

#### Scenario: Deprecation notice points to login

- **WHEN** the user runs `setup`
- **THEN** it prints a notice that `setup` is deprecated and recommends `login`, then proceeds

#### Scenario: Setup still writes a token

- **WHEN** the user provides a session token during setup
- **THEN** `~/.super8-studio.env` is created with `S8_SESSION_TOKEN` (and `S8_ORG_ID` if chosen) and contains no `S8_API_URL`

#### Scenario: Login session overrides a setup token

- **WHEN** both a valid login session and a setup-written `S8_SESSION_TOKEN` exist
- **THEN** skills use the login session token

#### Scenario: No API-URL prompt

- **WHEN** setup runs
- **THEN** it does not ask the user to choose or enter an API URL and does not accept an `--api-url` option
