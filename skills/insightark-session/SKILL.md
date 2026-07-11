---
name: insightark-session
description: Validate InsightArk MCP session context and inspect the authenticated developer identity, manageable organizations, and credit balance.
when_to_use: When a user needs to verify MCP authentication works, inspect the authenticated user, or confirm accessible organizations before deeper investigation.
allowed-mcp: true
---

# Skill: insightark-session

This skill uses the InsightArk MCP server. Authentication uses `_SessionToken` (same credential as the Super 8 Studio InsightArk MCP).

## MCP Tools

- `auth_me` — authenticated developer identity and manageable organizations (no `orgId` required)
- `auth_organizations` — list organizations the session can manage (no `orgId` required)
- `credits_usage` — peek InsightArk MCP credit balance for an organization (requires `orgId`; does not consume credits)

## Workflow

1. Call `auth_me` to verify the MCP session and inspect the authenticated user.
2. Call `auth_organizations` when the caller also needs manageable organization context.
3. Call `credits_usage` with `orgId` when the user asks how many InsightArk MCP credits remain, or after `429 error/credit-exhausted` to report `secondsUntilNextCredit`. This call does not consume credits (only org RPM applies).

## Guardrails

- Stay read-only.
- Do not attempt login, password collection, or TOTP completion.
- After credit exhaustion, use `credits_usage` instead of retrying costly endpoints to probe balance.
