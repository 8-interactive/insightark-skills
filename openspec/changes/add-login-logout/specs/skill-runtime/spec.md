## MODIFIED Requirements

### Requirement: Credential resolution and load order

Skills SHALL resolve the session token using the precedence (highest first): a valid login session (`~/.super8-studio.session`) → process environment `S8_SESSION_TOKEN` and `CLAUDE_PLUGIN_OPTION_S8_SESSION_TOKEN` → repository `./.super8-studio.env` → skills-install-directory env files listed in the install registry → user `~/.super8-studio.env`. A login session is "valid" only when it is not past its `expiresAt` AND its recorded `apiUrl` equals the currently-resolved API root; an invalid session SHALL be ignored (with a one-line notice to run `login` again) and resolution SHALL fall through to the next source. When `S8_SESSION_TOKEN` is unset in the process environment but `CLAUDE_PLUGIN_OPTION_S8_SESSION_TOKEN` is set, the value SHALL be mapped. The API URL is NOT a credential and is resolved separately (see "API URL resolution").

#### Scenario: Login session beats the environment token

- **WHEN** a valid login session exists and `S8_SESSION_TOKEN` is also set to a different value
- **THEN** the script uses the login session token

#### Scenario: Expired session falls through

- **WHEN** the login session is past its `expiresAt` and `S8_SESSION_TOKEN` is set
- **THEN** the session is ignored (with a re-login notice) and the environment token is used

#### Scenario: Session for another API environment is ignored

- **WHEN** the session's `apiUrl` differs from the currently-resolved API root
- **THEN** the session is ignored and resolution falls through to the next source

#### Scenario: Environment token used when no session

- **WHEN** there is no login session and `S8_SESSION_TOKEN` is set in the process environment
- **THEN** the script uses the process-environment value

#### Scenario: Plugin option mapping

- **WHEN** `S8_SESSION_TOKEN` is unset but `CLAUDE_PLUGIN_OPTION_S8_SESSION_TOKEN` is set and there is no session
- **THEN** the script uses the plugin option value as `S8_SESSION_TOKEN`

#### Scenario: Missing token produces actionable help

- **WHEN** no token can be resolved from any source
- **THEN** the script prints which sources were checked, the load priority, and how to authenticate (including `login`), and exits non-zero

### Requirement: Organization context resolution

Skills that require organization scope SHALL resolve the org id with the precedence: explicit `--org-id` → login session `orgId` → `S8_ORG_ID` → env files; and SHALL fail with guidance when none is available.

#### Scenario: Explicit org id wins

- **WHEN** a skill is invoked with `--org-id <id>`
- **THEN** that organization id is used regardless of the session `orgId` or `S8_ORG_ID`

#### Scenario: Session org used as default

- **WHEN** no `--org-id` is given and a valid login session has an `orgId`
- **THEN** the session `orgId` is used (over `S8_ORG_ID`)

#### Scenario: Missing org context

- **WHEN** no `--org-id`, no session `orgId`, and `S8_ORG_ID` is unset
- **THEN** the script reports missing organization context and exits non-zero
