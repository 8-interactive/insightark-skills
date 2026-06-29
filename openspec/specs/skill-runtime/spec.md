# skill-runtime Specification

## Purpose

Defines how Super 8 Studio skills execute as Node scripts: the invocation contract, credential resolution and load order, organization context, API request and error handling, and JSON output.

## Requirements

### Requirement: Node-based skill execution

Every skill command SHALL be implemented as a Node script (`.js`) executed with `node <path>`, requiring no bash, WSL, `curl`, or `jq`. Scripts SHALL use only the Node 18+ standard library (`fetch`, `JSON`, `Date`, `node:fs`, `node:path`, `node:os`, `node:readline`) and SHALL NOT depend on any installed `node_modules`.

#### Scenario: Skill runs on native Windows

- **WHEN** a coding agent invokes `node ../_super8-studio-api-shared/scripts/customer_detail.js --customer-id <id>` on native Windows with no bash available
- **THEN** the script executes successfully and returns the API result

#### Scenario: No external CLI tools required

- **WHEN** a skill script runs on a machine without `curl`, `jq`, or GNU `date`
- **THEN** the script completes without error using Node stdlib equivalents

#### Scenario: No node_modules shipped

- **WHEN** the skill bundle is installed into an agent skill folder
- **THEN** the installed directory contains no `node_modules` directory

### Requirement: Skill invocation contract

Each `SKILL.md` SHALL instruct the agent to run the skill's Node script via `node <relative-path>` rather than naming a `.sh` file.

#### Scenario: SKILL.md references the Node runner

- **WHEN** an agent reads a skill's `SKILL.md`
- **THEN** the documented command runs the script with `node` and the correct relative path to a `.js` file

### Requirement: Credential resolution and load order

Skills SHALL resolve credentials (`S8_API_URL`, `S8_SESSION_TOKEN`, optional `S8_ORG_ID`) using the precedence: process environment and `CLAUDE_PLUGIN_OPTION_S8_*` mappings (highest) → repository `./.super8-studio.env` → skills-install-directory env files listed in the install registry → user `~/.super8-studio.env` (lowest). When `S8_*` is unset in the process environment but the corresponding `CLAUDE_PLUGIN_OPTION_S8_*` is set, the value SHALL be mapped to `S8_*`.

#### Scenario: Process environment wins

- **WHEN** `S8_API_URL` is set in the process environment and a different value exists in `~/.super8-studio.env`
- **THEN** the script uses the process-environment value

#### Scenario: Plugin option mapping

- **WHEN** `S8_SESSION_TOKEN` is unset but `CLAUDE_PLUGIN_OPTION_S8_SESSION_TOKEN` is set
- **THEN** the script uses the plugin option value as `S8_SESSION_TOKEN`

#### Scenario: Repo env file overrides user env file

- **WHEN** both `./.super8-studio.env` and `~/.super8-studio.env` define `S8_ORG_ID` and no process value is set
- **THEN** the repository file value takes precedence

#### Scenario: Missing credentials produce actionable help

- **WHEN** neither `S8_API_URL` nor `S8_SESSION_TOKEN` can be resolved from any source
- **THEN** the script prints which sources were checked, the load priority, and how to configure credentials, and exits non-zero

### Requirement: Organization context resolution

Skills that require organization scope SHALL accept an explicit `--org-id`, fall back to `S8_ORG_ID`, and fail with guidance when neither is available.

#### Scenario: Explicit org id

- **WHEN** a skill is invoked with `--org-id <id>`
- **THEN** that organization id is used regardless of `S8_ORG_ID`

#### Scenario: Missing org context

- **WHEN** an org-scoped skill is invoked without `--org-id` and `S8_ORG_ID` is unset
- **THEN** the script reports missing organization context and exits non-zero

### Requirement: API request and error handling

Skills SHALL call the Developer API with `fetch`, sending the `_SessionToken` header, and SHALL map non-success responses to clear messages and non-zero exit codes, echoing the response body. 401 SHALL explain that the session is invalid/expired, and 429 SHALL explain rate limiting.

#### Scenario: Successful request

- **WHEN** the API returns a 2xx response
- **THEN** the script prints the JSON payload and exits zero

#### Scenario: Unauthorized

- **WHEN** the API returns 401
- **THEN** the script prints that the session is invalid or expired with token-renewal guidance and exits non-zero

#### Scenario: Rate limited

- **WHEN** the API returns 429
- **THEN** the script prints a rate-limit message and exits non-zero

#### Scenario: Other failures

- **WHEN** the API returns any other non-2xx status
- **THEN** the script prints the status and response body and exits non-zero

### Requirement: JSON output

Skills SHALL print API responses as formatted JSON to stdout using Node stdlib, with no dependency on `jq`.

#### Scenario: Formatted payload

- **WHEN** a skill receives a JSON response body
- **THEN** it prints human-readable formatted JSON to stdout
