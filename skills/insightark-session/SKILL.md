---
name: insightark-session
description: Validate InsightArk MCP session context and inspect the authenticated developer identity, manageable organizations, and credit balance.
when_to_use: When a user needs to verify MCP authentication works, inspect the authenticated user, or confirm accessible organizations before deeper investigation.
allowed-mcp: true
---

# Skill: insightark-session

This skill uses the InsightArk MCP server. Authentication uses `_SessionToken` (same credential as the Super 8 Studio Developer API).

## MCP Tools

- `auth.me` — authenticated developer identity and manageable organizations (no `orgId` required)
- `auth.organizations` — list organizations the session can manage (no `orgId` required)
- `credits.usage` — peek Developer API credit balance for an organization (requires `orgId`; does not consume credits)

## Workflow

1. Call `auth.me` to verify the MCP session and inspect the authenticated user.
2. Call `auth.organizations` when the caller also needs manageable organization context.
3. Call `credits.usage` with `orgId` when the user asks how many Developer API credits remain, or after `429 error/credit-exhausted` to report `secondsUntilNextCredit`. This call does not consume credits (only org RPM applies).

## Guardrails

- Stay read-only.
- Do not attempt login, password collection, or TOTP completion.
- After credit exhaustion, use `credits.usage` instead of retrying costly endpoints to probe balance.
