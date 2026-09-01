---
name: insightark-messaging
description: Author and operate outbound customer messaging through InsightArk MCP — session validation, org scoping, media upload, preview, and send.
when_to_use: When a user wants to compose, preview, or send an outbound message to a customer. For inbox browsing use insightark-conversations; for message search or analysis use insightark-investigator.
allowed-mcp: true
---

# Skill: insightark-messaging

**Prerequisite:** Read `skills/insightark-universal-workflow/SKILL.md` before operational work or domain references.

This skill uses the InsightArk MCP server. Authentication is managed by your host through MCP OAuth (Connect / Authenticate). Every org-scoped tool requires an `orgId` argument. Write operations need explicit user confirmation before calling.

## MCP Tools

- `auth_me` — validate session (no `orgId` required)
- `auth_organizations` — list manageable organizations (no `orgId` required)
- `messaging_message_preview` — **outbound** message-batch preview URL before send／broadcast (costs 2 credits); **not** for reading existing inbox messages
- `media_upload_url` — upload local media for message payloads
- `messaging_customer_send_message` — send outbound messages to a customer

## Workflow

1. Call `auth_me` or `auth_organizations` when session context is not yet trusted.
2. Resolve `orgId` before any org-scoped tool.
3. For inbox browsing, hand off to `insightark-conversations`; for message search, sender class filters, ads inbound / 廣告來源, or analysis, hand off to `insightark-investigator`. Continue while `page.hasMore` is true with `skip = page.skip + page.limit`.
4. Build the outbound payload; optionally use `media_upload_url`. Follow the universal **Rich Preview Gate** (`skills/insightark-universal-workflow/references/rich-preview-gate.md`): preview-required (non-`text/plain` or quick replies) → disclose 2-credit cost → `messaging_message_preview` → approval → `messaging_customer_send_message`; text-only without quick replies → confirmation only (no preview); skip preview only when the user explicitly asks.
5. Return the MCP response as-is.

## Rich / template authoring (load on demand)

When building `application/x-template` or other rich LINE payloads, load `references/TEMPLATE_GUIDELINES.md` and start from `references/examples/messages/`. Ordinary text/image send paths do not need that reference. Broadcast and MA skills hand rich message construction here rather than duplicating schema.

## Example requests

- `Send the text "Your order is on the way" to customer cus_123 in org org_demo_001.`
- `Send image https://cdn.example.com/promo.jpg to customer cus_123 in org org_demo_001.`

## Guardrails

- Treat send as a write operation; confirm inferred customer id or content before dispatch.
- If authentication is missing, expired, revoked, or the host reports `401` / `403` / authentication-required, hand off to `insightark-session` for host OAuth recovery before retrying. Do not treat network/timeout/`5xx` failures as OAuth problems.
- Never call `messaging_message_preview` to read existing conversation history.

## Ads inbound / 廣告來源 (Messenger referral)

When the user asks to find customers who entered from an ad (Console 綠線 / 廣告來源), use insightark-investigator: call messaging_message_search with referralSource: "ADS" and explicit startAt/endAt when they name a period. Do not invent a dedicated ads MCP tool. Do not scan with contentKinds: ["event"] alone when they asked only for ads. keyword does not match ad titles.

This filter matches Facebook / Instagram Messenger ads referral stored as application/x-notify-event (data.referral.source = ADS). LINE native ads are not this Message path; LINE orgs typically return no hits (empty is success).

Hits are message-level (follow + referral ADS MAY duplicate a customer). Obtain Super8 customerId via conversationId → messaging_conversation_get → conversation.customerId. Unique customer count is client-side dedupe of that customerId, not the search result count. Do not treat sender as Super8 customerId. Search hits do not include customerId. Deduped ids MAY go to existing tag tools; batch tagging remains S8N-13155.
