---
name: insightark-conversations
description: Browse conversation lists with organization scope and supported filters via InsightArk MCP.
when_to_use: When a user wants to find or list conversations by organization, customer, platform, inbox state, time filter, or cursor.
allowed-mcp: true
---

# Skill: insightark-conversations

This skill uses the InsightArk MCP server. Authentication uses `_SessionToken`. Every org-scoped tool requires an `orgId` argument.

## MCP Tools

- `messaging_conversation_list` — list conversations ordered by latest activity (requires `orgId`)
- `messaging_conversation_get` — open one conversation summary (requires `orgId`, `conversationId`)

Optional arguments: `customerId`, `platform`, `inbox` (`unassigned`, `done`, `private`, `bot`, `spam`), `limit`.

## Workflow

1. Resolve `orgId` from user context or `auth_organizations`.
2. Call `messaging_conversation_list` with `orgId` and only supported filters such as `customerId`, `platform`, `inbox`, and `limit`.
3. If the user asks to open a specific conversation, call `messaging_conversation_get` with `orgId` + `conversationId` returned from the list.
4. Return the public conversation list (and optionally one conversation summary) without exposing internal query structure.

## Guardrails

- Stay within the published read-side developer API surface.
- The list is **customer-activity driven**: results are ordered by customer `lastMessageAt` (not full-text relevance). Use `messaging_message_search` when the user asks for keyword evidence across messages.
- Do not assume a conversation id until it is returned by the API.
