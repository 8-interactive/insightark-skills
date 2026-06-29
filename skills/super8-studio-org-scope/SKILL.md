---
name: super8-studio-org-scope
description: Operate on the Super 8 Studio Developer API to list manageable organizations and establish organization context for org-scoped routes.
when_to_use: When a user needs to inspect which organizations are available or select the orgId that downstream conversation and message routes should use.
allowed-mcp: false
---

# Skill: super8-studio-org-scope

This skill operates on the Super 8 Studio Developer API.
It uses `S8_API_URL` for the API base URL, `S8_SESSION_TOKEN` for authentication, and optional `S8_ORG_ID` as default context.

## Scripts

- `node ../_super8-studio-api-shared/scripts/organizations.js`

## Workflow

1. Run `organizations.js` to retrieve the manageable organizations.
2. If `S8_ORG_ID` is already set, treat it as the default org context unless the user asks to change it.
3. If no org context is available, ask the user which returned org should scope later requests.

## Guardrails

- Keep organization selection explicit when more than one org is available.
- Do not invent org ids or infer hidden organization membership.
