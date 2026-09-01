---
name: insightark-session
description: Validate InsightArk MCP session context and inspect the authenticated developer identity, manageable organizations, and credit balance.
when_to_use: When a user needs to verify MCP authentication works, inspect the authenticated user, or confirm accessible organizations before deeper investigation. Also use when another InsightArk skill fails because MCP authentication is missing, expired, or required.
allowed-mcp: true
---

# Skill: insightark-session

**Prerequisite:** Read `skills/insightark-universal-workflow/SKILL.md` before operational work or domain references.

This skill uses the InsightArk MCP server. Authentication is managed by the agent through MCP OAuth during plugin installation or reauthorization.

## MCP Tools

- `auth_me` — authenticated developer identity and manageable organizations (no `orgId` required)
- `auth_organizations` — list organizations the session can manage (no `orgId` required)
- `credits_usage` — peek InsightArk MCP monthly remaining **and** the calling user's today breakdown (`today.total`, `today.tools`, `today.clients`) for an organization (requires `orgId`; does not consume credits)

## Workflow

1. Call `auth_me` to verify the MCP session and inspect the authenticated user.
2. If `auth_me` succeeds, call `auth_organizations` when the caller also needs manageable organization context.
3. Call `credits_usage` with `orgId` when the user asks how many InsightArk MCP credits remain this month, or who / which tools / which client used credits today. For remaining-only questions, report monthly `remaining` / `used`. For today spend, report `today.tools` and `today.clients` from that result. Do not invent a today total from remaining deltas, and do not claim per-call receipts from `credits_usage`. Treat `today.clients[].label` as a self-reported app name, not verified host identity. After `429 error/credit-exhausted`, use `credits_usage` to report remaining. This call does not consume credits (only org RPM applies).

## OAuth recovery (when MCP needs authentication)

If `auth_me` fails because authentication is missing, expired, revoked, or the agent reports `401` / `403` / authentication-required for the bundled `insightark` MCP server, **do not** ask for a SessionToken, run setup scripts, manually add the MCP URL/client id, or use standalone MCP login commands. Direct the user to the agent-specific recovery action below, wait for OAuth to complete, then call `auth_me` again.

Do **not** treat network errors, timeouts, MCP unavailable, or `5xx` responses as OAuth failures — diagnose connectivity / agent MCP availability first rather than reauthorize.

| Agent | Recovery action |
|---|---|
| ChatGPT desktop / Codex | Uninstall the InsightArk plugin, then install it again from the marketplace. Installation starts OAuth automatically. |
| Claude Code | Uninstall the InsightArk plugin, then install it again. Installation starts OAuth automatically. |
| Cursor | Open the InsightArk plugin details page → **MCPs** → select `insightark` → **Environments** → **Logout** → return to the details page and select **Authenticate** next to `insightark`. |
| Google Antigravity | Open **Settings → Customizations**, locate the `insightark` MCP server, and select **Authenticate**. If the server is stale, refresh it before retrying OAuth. |

After the user completes OAuth, retry `auth_me` before continuing other InsightArk work.

## Guardrails

- Stay read-only.
- Do not attempt password collection or TOTP completion in chat.
- Do not paste, export, or request InsightArk MCP session tokens.
- After credit exhaustion, use `credits_usage` instead of retrying costly endpoints to probe balance.
