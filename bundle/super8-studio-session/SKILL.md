---
name: super8-studio-session
description: Operate on the Super 8 Studio Developer API to validate S8_SESSION_TOKEN and inspect current developer session context.
when_to_use: When a user needs to verify that S8_API_URL and S8_SESSION_TOKEN work, inspect the authenticated user, or confirm accessible organizations before deeper investigation.
allowed-mcp: false
license: MIT
metadata:
  owner: platform
  version: "1.0.0"
  category: agent-foundation
  domain: super8-studio
---

# Skill: super8-studio-session

This skill operates on the Super 8 Studio Developer API.
It uses `S8_API_URL` for the API base URL and `S8_SESSION_TOKEN` for authentication.

## Credentials

Scripts auto-load `~/.super8-studio.env` then `./.super8-studio.env` (repo overrides user). Process environment variables take highest priority.

If credentials are missing, run `./install.sh` then `./setup-env.sh` from the skill bundle (opens Console to create a token and picks a Developer-API-enabled org). Or create `~/.super8-studio.env` from `.super8-studio.env.example`.

## Scripts

- `../_super8-studio-api-shared/scripts/doctor.sh`
- `../_super8-studio-api-shared/scripts/auth_me.sh`
- `../_super8-studio-api-shared/scripts/organizations.sh`

## Workflow

1. Run `doctor.sh` when environment readiness is unknown.
2. Run `auth_me.sh` to inspect the current authenticated session.
3. Run `organizations.sh` when the caller also needs manageable organization context.

## Guardrails

- Stay read-only.
- Do not attempt login, password collection, or TOTP completion.
- Store tokens only in `~/.super8-studio.env` or `./.super8-studio.env`; never commit them to version control.

## When not to use

- The required session or organization context has already been validated by a parent skill.
- The task requires a domain-specific API operation that should be handled by a leaf skill.
- The user is asking for documentation help rather than live API interaction.

## Inputs

- `S8_API_URL` — API base URL loaded from environment or Super 8 Studio env files.
- `S8_SESSION_TOKEN` — developer session token loaded from environment or Super 8 Studio env files.
- `S8_ORG_ID` — optional organization context for org-scoped workflows.

## Outputs

- Environment readiness, authenticated user context, manageable organizations, or resolved `orgId` for downstream skills.

## Failure handling

- If credentials are missing, direct the user to run `./setup-env.sh`; never supply or invent credentials.
- If authentication fails, report the status and stop dependent workflows.
- If organization selection is ambiguous, ask the user to choose explicitly; do not pick silently.

## Observability

- Record the script invoked and HTTP status. Never log or echo `S8_SESSION_TOKEN`.
