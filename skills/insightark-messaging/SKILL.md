---
name: insightark-messaging
description: Investigate and operate on messaging through InsightArk MCP — session validation, org scoping, conversations, message search, and outbound send (default preview for rich batches).
when_to_use: When a user wants a single messaging-oriented workflow that can validate MCP readiness, resolve organization scope, browse conversations, inspect one conversation, search messages, or dispatch outbound messages to a customer.
allowed-mcp: true
---

# Skill: insightark-messaging

This skill uses the InsightArk MCP server. Authentication uses `_SessionToken`. Every org-scoped tool requires an `orgId` argument. Write operations need explicit user confirmation before calling.

## MCP Tools

- `auth.me` — validate session (no `orgId` required)
- `auth.organizations` — list manageable organizations (no `orgId` required)
- `messaging.conversation.list` — browse conversations
- `messaging.conversation.get` — get one conversation summary
- `messaging.conversation.messages` — read message timeline
- `messaging.message.search` — keyword-driven message search
- `messaging.message.preview` — preview message batch (costs 2 credits)
- `media.uploadUrl` — upload local media for message payloads
- `messaging.customer.sendMessage` — send outbound messages to a customer

## Workflow

1. Call `auth.me` or `auth.organizations` when session context is not yet trusted.
2. Resolve `orgId` before any org-scoped tool.
3. Choose one path:
   - **Conversations** — `messaging.conversation.list`
   - **Conversation detail** — `messaging.conversation.get` and `messaging.conversation.messages`
   - **Message search** — `messaging.message.search`
   - **Send** — build payload, optionally `media.uploadUrl`, then `messaging.message.preview` → confirm → `messaging.customer.sendMessage` by default for rich / quickReply batches; skip preview only when the user explicitly asks
4. Return the MCP response as-is.

## Example requests

- `Validate my Developer API session and show conversations in org org_demo_001 from the past 24 hours.`
- `Open conversation conv_abc in org org_demo_001 and show the latest messages.`
- `Search messages in org org_demo_001 for "refund" within the past 7 days.`
- `Send the text "Your order is on the way" to customer cus_123 in org org_demo_001.`
- `Send image https://cdn.example.com/promo.jpg to customer cus_123 in org org_demo_001.`

## Guardrails

- Treat send as a write operation; confirm inferred customer id or content before dispatch.
- Read operations stay within published API schemas.
