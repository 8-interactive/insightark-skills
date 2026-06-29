# credential-setup Specification

## Purpose

Defines how Super 8 Studio credential setup runs as a Node process, how credential load priority is communicated, and how a doctor health check verifies configured credentials.

## Requirements

### Requirement: Node-based credential setup

Credential setup SHALL run as a Node process with no bash dependency, creating or updating the user env file (`~/.super8-studio.env`) with `S8_API_URL`, `S8_SESSION_TOKEN`, and optional `S8_ORG_ID`.

#### Scenario: Setup on native Windows

- **WHEN** a user runs credential setup on native Windows
- **THEN** it writes `~/.super8-studio.env` without invoking bash

#### Scenario: Env file written

- **WHEN** the user provides API URL and session token during setup
- **THEN** `~/.super8-studio.env` is created with those values

### Requirement: Credential load-priority guidance

Setup SHALL explain the credential load priority and, when relevant, point to process-environment configuration as the highest-priority alternative.

#### Scenario: Priority explained

- **WHEN** setup reports where credentials are read from
- **THEN** it lists the order: process environment / plugin options (highest) → repo env file → skills-install-dir env → user env file

### Requirement: Doctor health check

A doctor health check SHALL verify that configured credentials work by making an authenticated call to the Developer API, reporting success or a clear failure reason, and exiting non-zero on failure. It SHALL run on Node without bash, `curl`, or `jq`.

#### Scenario: Healthy configuration

- **WHEN** doctor runs with valid `S8_API_URL` and `S8_SESSION_TOKEN`
- **THEN** it reports a successful authenticated check and exits zero

#### Scenario: Invalid session detected

- **WHEN** doctor runs with an expired or invalid session token
- **THEN** it reports the session is invalid with renewal guidance and exits non-zero

#### Scenario: Missing credentials detected

- **WHEN** doctor runs with no resolvable credentials
- **THEN** it reports which sources were checked and how to configure credentials, and exits non-zero
