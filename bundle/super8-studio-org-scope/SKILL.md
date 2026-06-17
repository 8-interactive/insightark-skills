---
name: super8-studio-org-scope
description: Operate on the Super 8 Studio Developer API to list manageable organizations and establish organization context for org-scoped routes.
when_to_use: When a user needs to inspect which organizations are available or select the orgId that downstream conversation and message routes should use.
allowed-mcp: false
license: MIT
metadata:
  owner: platform
  version: "1.0.0"
  category: agent-foundation
  domain: super8-studio
---

# Skill: super8-studio-org-scope

This skill operates on the Super 8 Studio Developer API.
It uses `S8_API_URL` for the API base URL, `S8_SESSION_TOKEN` for authentication, and optional `S8_ORG_ID` as default context.

## Scripts

- `../_super8-studio-api-shared/scripts/organizations.sh`

## Workflow

1. Run `organizations.sh` to retrieve the manageable organizations.
2. If `S8_ORG_ID` is already set, treat it as the default org context unless the user asks to change it.
3. If no org context is available, ask the user which returned org should scope later requests.

## Guardrails

- Keep organization selection explicit when more than one org is available.
- Do not invent org ids or infer hidden organization membership.

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
