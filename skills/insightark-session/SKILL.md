---
name: insightark-session
description: Validate InsightArk MCP session context and inspect the authenticated developer identity, manageable organizations, and credit balance.
when_to_use: When a user needs to verify MCP authentication works, inspect the authenticated user, or confirm accessible organizations before deeper investigation. Also use when another InsightArk skill fails because MCP authentication is missing, expired, or required.
allowed-mcp: true
---

# Skill: insightark-session

This skill uses the InsightArk MCP server. Authentication is managed by your host through MCP OAuth (Connect / Authenticate).

## MCP Tools

- `auth_me` — authenticated developer identity and manageable organizations (no `orgId` required)
- `auth_organizations` — list organizations the session can manage (no `orgId` required)
- `credits_usage` — peek InsightArk MCP credit balance for an organization (requires `orgId`; does not consume credits)

## Workflow

1. Call `auth_me` to verify the MCP session and inspect the authenticated user.
2. If `auth_me` succeeds, call `auth_organizations` when the caller also needs manageable organization context.
3. Call `credits_usage` with `orgId` when the user asks how many InsightArk MCP credits remain, or after `429 error/credit-exhausted` to report `secondsUntilNextCredit`. This call does not consume credits (only org RPM applies).

## OAuth recovery (when MCP needs authentication)

If `auth_me` fails because authentication is missing, expired, revoked, or the host reports `401` / `403` / authentication-required for the bundled `insightark` MCP server, **do not** ask for a SessionToken, run setup scripts, or manually add the MCP URL/client id. Direct the user to the host-specific recovery action below, wait for OAuth to complete, then call `auth_me` again.

Do **not** treat network errors, timeouts, MCP unavailable, or `5xx` responses as OAuth failures — diagnose connectivity / host MCP availability first rather than Reauthorize.

| Host | Recovery action |
|---|---|
| Claude Code | Run `/mcp` and Connect / Re-authenticate the plugin-registered `insightark` server |
| Cursor | Open **Customize → Tools & MCP** and Connect / Re-authenticate `insightark` |
| Codex CLI | Run `codex mcp login insightark` for the already plugin-registered server (no new `mcp add`) |
| ChatGPT desktop (Codex in App) | Use the App/plugin UI **Connect** or **Reauthorize** for `insightark`; Codex CLI is not required |

After the user completes host OAuth, retry `auth_me` before continuing other InsightArk work.

## Guardrails

- Stay read-only.
- Do not attempt password collection or TOTP completion in chat.
- Do not paste, export, or request InsightArk MCP session tokens.
- After credit exhaustion, use `credits_usage` instead of retrying costly endpoints to probe balance.
