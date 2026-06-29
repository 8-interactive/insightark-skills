# credential-setup Specification

## Purpose

Defines how SUPER 8 Studio credential setup runs as a Node process, how credential load priority is communicated, and how a doctor health check verifies configured credentials.

## Requirements

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

### Requirement: Credential load-priority guidance

Setup SHALL explain the session-token load priority and, when relevant, point to process-environment configuration as the highest-priority alternative. It SHALL make clear that the API URL is fixed at install time and is not configured here.

#### Scenario: Priority explained

- **WHEN** setup reports where the token is read from
- **THEN** it lists the order: process environment / plugin options (highest) → repo env file → skills-install-dir env → user env file

#### Scenario: API URL noted as install-fixed

- **WHEN** setup describes configuration
- **THEN** it indicates the API URL is determined at install time, not by setup or environment variables

### Requirement: Doctor health check

A doctor health check SHALL verify that the configured token works by making an authenticated call to the Developer API at the resolved API root, reporting success or a clear failure reason, and exiting non-zero on failure. It SHALL print the resolved API root and whether it came from the install registry or the production fallback. It SHALL run on Node without bash, `curl`, or `jq`.

#### Scenario: Healthy configuration

- **WHEN** doctor runs with a valid token and a resolvable API root
- **THEN** it reports a successful authenticated check, prints the API root, and exits zero

#### Scenario: Invalid session detected

- **WHEN** doctor runs with an expired or invalid session token
- **THEN** it reports the session is invalid with renewal guidance and exits non-zero

#### Scenario: Missing token detected

- **WHEN** doctor runs with no resolvable token
- **THEN** it reports which sources were checked and how to configure the token, and exits non-zero
