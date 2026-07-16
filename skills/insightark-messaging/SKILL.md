---
name: insightark-messaging
description: Investigate and operate on messaging through InsightArk MCP — session validation, org scoping, conversations, message search, and outbound send (default preview for rich batches).
when_to_use: When a user wants a single messaging-oriented workflow that can validate MCP readiness, resolve organization scope, browse conversations, inspect one conversation, search messages, or dispatch outbound messages to a customer.
allowed-mcp: true
---

# Skill: insightark-messaging

This skill uses the InsightArk MCP server. Authentication is managed by your host through MCP OAuth (Connect / Authenticate). Every org-scoped tool requires an `orgId` argument. Write operations need explicit user confirmation before calling.

## MCP Tools

- `auth_me` — validate session (no `orgId` required)
- `auth_organizations` — list manageable organizations (no `orgId` required)
- `messaging_conversation_list` — browse conversations
- `messaging_conversation_get` — get one conversation summary
- `messaging_conversation_messages` — read message timeline
- `messaging_message_search` — keyword-driven message search
- `messaging_message_preview` — preview message batch (costs 2 credits)
- `media_upload_url` — upload local media for message payloads
- `messaging_customer_send_message` — send outbound messages to a customer

## Workflow

1. Call `auth_me` or `auth_organizations` when session context is not yet trusted.
2. Resolve `orgId` before any org-scoped tool.
3. Choose one path:
   - **Conversations** — `messaging_conversation_list`
   - **Conversation detail** — `messaging_conversation_get` and `messaging_conversation_messages`
   - **Message search** — `messaging_message_search`
   - **Send** — build payload, optionally `media_upload_url`, then `messaging_message_preview` → confirm → `messaging_customer_send_message` by default for rich / quickReply batches; skip preview only when the user explicitly asks
4. Return the MCP response as-is.

## Rich / template authoring (load on demand)

When building `application/x-template` or other rich LINE payloads, load `references/TEMPLATE_GUIDELINES.md` and start from `references/examples/messages/`. Ordinary text/image send paths do not need that reference. Broadcast and MA skills hand rich message construction here rather than duplicating schema.

## Example requests

- `Validate my InsightArk MCP session and show conversations in org org_demo_001 from the past 24 hours.`
- `Open conversation conv_abc in org org_demo_001 and show the latest messages.`
- `Search messages in org org_demo_001 for "refund" within the past 7 days.`
- `Send the text "Your order is on the way" to customer cus_123 in org org_demo_001.`
- `Send image https://cdn.example.com/promo.jpg to customer cus_123 in org org_demo_001.`

## Guardrails

- Treat send as a write operation; confirm inferred customer id or content before dispatch.
- Read operations stay within published API schemas.
- If authentication is missing, expired, revoked, or the host reports `401` / `403` / authentication-required, hand off to `insightark-session` for host OAuth recovery before retrying. Do not treat network/timeout/`5xx` failures as OAuth problems.
