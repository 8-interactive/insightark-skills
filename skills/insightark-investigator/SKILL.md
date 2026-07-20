---
name: insightark-investigator
description: Investigate conversations and messages through InsightArk MCP using read-only tools.
when_to_use: When a user asks a natural language investigation question that may require session validation, organization scoping, conversation discovery, conversation inspection, or message search.
allowed-mcp: true
---

# Skill: insightark-investigator

This skill uses the InsightArk MCP server. Authentication is managed by your host through MCP OAuth (Connect / Authenticate). Every org-scoped tool requires an `orgId` argument. This skill is read-only — no write MCP tools.

## MCP Tools

- `auth_me` — validate session (no `orgId` required)
- `auth_organizations` — list manageable organizations (no `orgId` required)
- `messaging_conversation_list` — browse conversations
- `messaging_conversation_get` — get one conversation summary
- `messaging_conversation_messages` — read message timeline
- `messaging_message_search` — keyword-driven message search

## Workflow

1. Call `auth_me` or `auth_organizations` when the caller's session context is not yet trusted.
2. Resolve `orgId` before any org-scoped tool.
3. Choose one operational path:
   - `messaging_conversation_list` for discovery and pagination
   - `messaging_conversation_get` and `messaging_conversation_messages` for one conversation and its timeline
   - `messaging_message_search` for keyword-oriented evidence lookup
4. Return a concise read-only investigation result grounded in the public API response.

## Guardrails

- Do not call write endpoints (`messaging_customer_send_message`, `broadcast_create`, CRM mutations, MA mutations).
- Do not collect credentials or attempt login bootstrap.
- If authentication is missing, expired, revoked, or the host reports `401` / `403` / authentication-required, hand off to `insightark-session` for host OAuth recovery before retrying. Do not treat network/timeout/`5xx` failures as OAuth problems.
- Do not depend on repository-local code or hidden internal fields.
- Prefer `messaging_message_search` for analysis. Do not rebuild Excel via repeated MCP search; human downloads use Console CS export.
- Page sizes: search／conversation_messages max 1000; conversation_list max 100.

## Message search sender filters (important)

Default search (omit `senderType` / `senderTypes`) returns **Customer only**. Staff `userName` / `userEmail` only appear on `_User` rows.

| Goal | Args |
|---|---|
| Customer messages | `senderType: "Customer"` (or omit) |
| Staff / CS replies | `senderType: "_User"` |
| Full dialogue | `senderTypes: ["Customer", "_User"]` (one call; do not pass both `senderType` and `senderTypes`) |

Prefer `senderTypes` for customer+staff so you do not pay two search credits. Narrow with `conversationId` and a small time window when possible.

## Message search timeout (`error.code = message_search_timeout`)

When search returns structured `message_search_timeout` (`isError: true`):

1. Never blind-retry identical args (credits are still charged).
2. Halve `startAt`/`endAt` and search sequentially; reduce `limit` if needed.
3. Use only published filters: `keyword`, `conversationId`, `platform`, `senderType` / `senderTypes`, `senderIds`.
4. Limit automatic splits; if still failing, stop and ask the user to narrow scope or use Console.
5. Do not invent unsupported message-type / `contentType` filters.
