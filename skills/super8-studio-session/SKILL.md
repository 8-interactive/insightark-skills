---
name: super8-studio-session
description: Operate on the Super 8 Studio Developer API to validate S8_SESSION_TOKEN and inspect current developer session context.
when_to_use: When a user needs to verify that S8_API_URL and S8_SESSION_TOKEN work, inspect the authenticated user, or confirm accessible organizations before deeper investigation.
allowed-mcp: false
---

# Skill: super8-studio-session

This skill operates on the Super 8 Studio Developer API.
It uses `S8_API_URL` for the API base URL and `S8_SESSION_TOKEN` for authentication.

## Credentials

Scripts auto-load `~/.super8-studio.env` then `./.super8-studio.env` (repo overrides user). Process environment variables take highest priority.

If credentials are missing, run `./install.js` then `./setup-env.js` from the skill bundle (opens Console to create a token and picks a Developer-API-enabled org). Or create `~/.super8-studio.env` from `.super8-studio.env.example`.

## Scripts

- `node ../_super8-studio-api-shared/scripts/doctor.js`
- `node ../_super8-studio-api-shared/scripts/auth_me.js`
- `node ../_super8-studio-api-shared/scripts/organizations.js`

## Workflow

1. Run `doctor.js` when environment readiness is unknown.
2. Run `auth_me.js` to inspect the current authenticated session.
3. Run `organizations.js` when the caller also needs manageable organization context.

## Guardrails

- Stay read-only.
- Do not attempt login, password collection, or TOTP completion.
- Store tokens only in `~/.super8-studio.env` or `./.super8-studio.env`; never commit them to version control.
