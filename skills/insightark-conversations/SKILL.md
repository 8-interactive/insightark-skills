---
name: insightark-conversations
description: Browse conversation lists with organization scope and supported filters via InsightArk MCP.
when_to_use: When a user wants to find or list conversations by organization, customer, platform, inbox state, time filter, or cursor.
allowed-mcp: true
---

# Skill: insightark-conversations

**Prerequisite:** Read `skills/insightark-universal-workflow/SKILL.md` before operational work or domain references.

This skill uses the InsightArk MCP server. Authentication is managed by your host through MCP OAuth (Connect / Authenticate). Every org-scoped tool requires an `orgId` argument.

## MCP Tools

- `messaging_conversation_list` — list conversations ordered by latest activity (requires `orgId`)
- `messaging_conversation_get` — open one conversation summary (requires `orgId`, `conversationId`)

Optional arguments: `customerId`, `platform`, `inbox`, `limit`. Exact `inbox` tokens come from the MCP tool schema enum.

## Workflow

1. Resolve `orgId` from user context or `auth_organizations`.
2. Call `messaging_conversation_list` with `orgId` and only supported filters such as `customerId`, `platform`, `inbox`, and `limit`.
3. If the user asks to open a specific conversation, call `messaging_conversation_get` with `orgId` + `conversationId` returned from the list.
4. Return the public conversation list (and optionally one conversation summary) without exposing internal query structure.

## Guardrails

- Stay within the published read-side InsightArk MCP / public schema surface.
- `inbox` must be a published schema value (e.g. unassigned / done / private / bot / spam — confirm against schema).
- `platform` is a Super8 channel id string (e.g. line, facebook); do not invent channels.
- The list is **customer-activity driven**: results are ordered by customer `lastMessageAt` (not full-text relevance). Use `messaging_message_search` when the user asks for keyword evidence across messages.
- Do not assume a conversation id until it is returned by the API.
- If authentication is missing, expired, revoked, or the host reports `401` / `403` / authentication-required, hand off to `insightark-session` for host OAuth recovery before retrying. Do not treat network/timeout/`5xx` failures as OAuth problems.
