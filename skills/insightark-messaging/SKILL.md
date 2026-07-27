---
name: insightark-messaging
description: Investigate and operate on messaging through InsightArk MCP — session validation, org scoping, conversations, message search, and outbound send (default preview for rich batches).
when_to_use: When a user wants a single messaging-oriented workflow that can validate MCP readiness, resolve organization scope, browse conversations, inspect one conversation, search messages, or dispatch outbound messages to a customer.
allowed-mcp: true
---

# Skill: insightark-messaging

**Prerequisite:** Read `skills/insightark-universal-workflow/SKILL.md` before operational work or domain references.

This skill uses the InsightArk MCP server. Authentication is managed by your host through MCP OAuth (Connect / Authenticate). Every org-scoped tool requires an `orgId` argument. Write operations need explicit user confirmation before calling.

## MCP Tools

- `auth_me` — validate session (no `orgId` required)
- `auth_organizations` — list manageable organizations (no `orgId` required)
- `messaging_conversation_list` — browse／page conversations by Customer last activity
- `messaging_conversation_get` — get one conversation summary
- `messaging_conversation_messages` — read one conversation’s recent timeline
- `messaging_message_search` — org-wide message search by time／literal keyword／Customer tags／`contentKinds`
- `messaging_message_preview` — **outbound** message-batch preview URL before send／broadcast (costs 2 credits); **not** for reading existing inbox messages
- `media_upload_url` — upload local media for message payloads
- `messaging_customer_send_message` — send outbound messages to a customer

## Tool usage scenarios

| Tool | Use when | Do not use when |
|---|---|---|
| `messaging_conversation_list` | Inbox／“active in this period” conversation lists; `pageCursor` paging | Message sentiment％／keyword corpus across the org |
| `messaging_conversation_get` | Known `conversationId` summary | Bulk scan |
| `messaging_conversation_messages` | Full recent thread for one conversation (e.g. single-customer deep dive) | Org-wide theme search |
| `messaging_message_search` | Time-window or tag-scoped corpus, literal-keyword evidence | As a substitute for inbox activity lists (use list) |
| `messaging_message_preview` | Rich／template outbound preview before send or broadcast | Previewing or fetching **existing** conversation messages |
| `messaging_customer_send_message` | Confirmed outbound send | Analysis reads |

**Activity window (list)** `lastMessageAtFrom`/`lastMessageAtTo` = Customer `lastMessageAt` (Customers missing `lastMessageAt` are excluded).  
**Message window (search)** `startAt`/`endAt` = message `createdAt`. Do not mix parameter names across tools.

Echo list `page.nextPageCursor` as `pageCursor`; do not parse or hand-craft cursors (opaque keyset hint, not an auth token).

## Workflow

1. Call `auth_me` or `auth_organizations` when session context is not yet trusted.
2. Resolve `orgId` before any org-scoped tool.
3. Choose one path:
   - **Conversations** — `messaging_conversation_list`
   - **Conversation detail** — `messaging_conversation_get` and `messaging_conversation_messages`
   - **Message search** — `messaging_message_search`
   - **Send** — build payload; optionally `media_upload_url`. Follow the universal **Rich Preview Gate** (`skills/insightark-universal-workflow/references/rich-preview-gate.md`): preview-required (non-`text/plain` or quick replies) → disclose 2-credit cost → `messaging_message_preview` → approval → `messaging_customer_send_message`; text-only without quick replies → confirmation only (no preview); skip preview only when the user explicitly asks
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
- Prefer analysis via `messaging_message_search`. Do not reconstruct full-month Excel via repeated MCP calls; for human download use Console CS export.
- `messaging_message_search` / `messaging_conversation_messages` accept `limit` up to 1000; `messaging_conversation_list` remains max 100.
- Never call `messaging_message_preview` to read existing conversation history.

## Period vs timeline (important)

1. **Time-scoped asks** → `messaging_message_search` with explicit `startAt`/`endAt` only. Do not use `messaging_conversation_messages` as the period corpus.
2. **`messaging_conversation_messages`** = recent thread peek only (no year filter).
3. **`messaging_conversation_list`** = Customer activity inbox (excludes missing `lastMessageAt`); not a full historical inventory; activity bounds ≠ message `createdAt`.
4. Non-text／media rows are not engagement scores.
5. Ranges over 90 days need sequential ≤90-day search windows; estimate credits before running.
6. Staff `userName`／`userEmail` come from `messaging_message_search` (always enriched internally; no client `includeUserContact` param). Timeline reads do not enrich staff identity — do not guess senders.

## Message search sender filters (important)

Use only `senderTypes` (string array). Exact allowed class strings come from the MCP tool schema `senderTypes.items.enum`.

Default (omit `senderTypes`) returns **Customer only**. Staff fields (`userName` / `userEmail`) only appear on `_User` rows — request staff senders explicitly.

| Goal | Args |
|---|---|
| Customer messages | omit `senderTypes`, or `senderTypes: ["Customer"]` |
| Staff / CS replies | `senderTypes: ["_User"]` |
| Full dialogue (customer + staff) | `senderTypes: ["Customer", "_User"]` — one tool call, interleaved by `createdAt`, one normal 20-credit charge |
| AddOn / extension messages | `senderTypes: ["AddOn"]` |
| Brand / org-originated (e.g. broadcast) | `senderTypes: ["Organization"]` |
| External bot messages | `senderTypes: ["ForeignBot"]` |

- Never pass singular `senderType` (removed from the MCP schema).
- Prefer one multi-class `senderTypes` call over two searches (one call / one 20-credit charge vs two charges).
- Time window is always applied: omit `startAt`/`endAt` → last **14 days**; only `startAt` → `endAt = now`; only `endAt` → `startAt = endAt − 14 days`; both provided → max **90 days**. When the user asks for a specific period, always pass matching `startAt`/`endAt` — do not rely on the 14-day default.
- When customer time language becomes `startAt`/`endAt` instant boundaries, follow `skills/insightark-universal-workflow/references/timezone-policy.md` and disclose the effective timezone. Date-only two-sided ranges need confirmed clocks; one-sided date-only endpoints need a confirmed clock plus disclosure of the server-derived opposite bound, and must stay ≤ 90 days — never silently invent midnight.
- Still narrow with `conversationId` and a tight `startAt`/`endAt` when possible.

### Optional Customer tags

- `includeTags: ["VIP", "Refund"]` means the Customer has **any** listed tag (OR).
- `excludeTags` removes Customers with any listed tag. When both are supplied,
  inclusion and exclusion both apply.
- `crm_customer_search.includeTags` also uses OR semantics; do not invent an
  all-tags meaning for either tool.

### Optional `contentKinds` (include-only)

Pass `contentKinds` as an array of kind tokens when you need a content-type filter. Exact MIME mapping:

| Kind | `contentType` values |
|---|---|
| `text` | `text/plain` |
| `template` | `application/x-template` |
| `image` | `application/x-image`, `application/x-image-set` |
| `file` | `application/x-file` |
| `event` | `application/x-notify-event` |

- Sentiment／complaint on customer text: prefer `contentKinds: ["text"]` (excludes notify-event noise).
- CS／template review: include `template` when needed.
- Join／follow investigation: include `event`.
- `application/x-video` and `application/x-audio` are **not** part of `image` or `file`; omit `contentKinds` if you need them.
- When `contentKinds` is set it overrides the keyword-path default text+template restriction.

## Message search timeout (`error.code = message_search_timeout`)

When `messaging_message_search` fails with structured tool error `code: message_search_timeout` (CallToolResult `isError: true`):

1. Do **not** retry with the exact same parameters (timeout still consumes the tool's credit cost; there is no refund).
2. Prefer splitting `startAt`/`endAt` in half and searching sequentially.
3. Reduce `limit` when helpful.
4. Add supported filters only: `keyword`, `includeTags`, `excludeTags`, `conversationId`, `platform`, `senderTypes`, `senderIds`.
5. Cap automatic split/retry attempts (e.g. a few halvings); if still timing out, stop and tell the user the range is too large — suggest more filters or Console search.
6. Supported filters include published schema fields such as `keyword`, `includeTags`, `excludeTags`, `conversationId`, `platform`, `senderTypes`, `senderIds`, and `contentKinds`. Do **not** invent unpublished filters.

## Message search busy (`error.code = message_search_in_progress`)

This means **you already have another message search running in this organization**
(possibly from Console). It is retryable and returns zero charged credits: wait
for the earlier search to finish, then retry once. Do not treat it as a timeout,
do not split the query, and do not issue parallel retries.
