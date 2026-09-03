---
name: insightark-investigator
description: Investigate conversations and messages through InsightArk MCP using read-only tools.
when_to_use: When a user asks a natural language investigation question that may require session validation, organization scoping, conversation discovery, conversation inspection, message search, or compiling an FAQ / 常見問題 from customer conversations.
allowed-mcp: true
---

# Skill: insightark-investigator

**Prerequisite:** Read `skills/insightark-universal-workflow/SKILL.md` before operational work or domain references.

This skill uses the InsightArk MCP server. Authentication is managed by your host through MCP OAuth (Connect / Authenticate). Every org-scoped tool requires an `orgId` argument. This skill is read-only — no write MCP tools.

**Audience:** 1:1 / Customer conversations. For LINE **ChatGroup** discovery or group-message analysis, hand off to `insightark-chat-groups` (do not use `messaging_conversation_list` as group discovery).

## MCP Tools

- `auth_me` — validate session (no `orgId` required)
- `auth_organizations` — list manageable organizations (no `orgId` required)
- `messaging_conversation_list` — browse／page conversations by Customer last activity (`lastMessageAtFrom`/`To`, `cursor`)
- `messaging_conversation_get` — get one conversation summary
- `messaging_conversation_messages` — read message timeline
- `messaging_message_search` — time／keyword／tag／`contentKinds`／`referralSource` message search

## Workflow

1. Call `auth_me` or `auth_organizations` when the caller's session context is not yet trusted.
2. Resolve `orgId` before any org-scoped tool.
3. Choose one operational path:
   - `messaging_conversation_list` for inbox／activity discovery and `cursor` paging (not message-proportion analysis)
   - `messaging_conversation_get` and `messaging_conversation_messages` for one conversation and its timeline
   - `messaging_message_search` for time-window／keyword／`contentKinds` evidence (prefer for qualitative stats); continue while `page.hasMore` is true with `skip = page.skip + page.limit`
4. Return a concise read-only investigation result grounded in the public API response.

## Qualitative detection (intent / sentiment / complaint)

For batch qualitative reading — judging customer intent, sentiment, or complaints
across a set of conversations rather than a single lookup — load
`references/QUALITATIVE_DETECTION.md` on demand and follow it. It covers:

- **Path selection**: time-window, keyword, and tag-segmented audiences use one
  bounded `messaging_message_search` call with its matching filters.
- **Cost guardrails**: call `credits_usage` with optional args omitted to inspect monthly remaining, then after the batch call it again and report `usage.total` (this client today). Do not treat tool JSON as a receipt. `credits_usage` monthly remaining must not be used to infer cost via remaining-value deltas. Respect hard sample caps, and never blind-retry — batch reads cost more than the nominal per-call rate.
- **Reading rules**: findings must cite specific messages, must not fabricate
  complaints, and are human-reviewable signals, not authoritative labels.

### Analysis lenses (same tools, same guardrails)

`QUALITATIVE_DETECTION.md` is the shared foundation (path selection + cost
guardrails + reading rules). `messaging_message_search` is the standard path;
`messaging_conversation_messages` is a recent context peek, not a period corpus.
Focused lenses build on it — load the one that matches the ask, then follow
the shared sample/credit caps:

- **Complaint root cause / theme categorisation** → `references/ROOT_CAUSE_ANALYSIS.md`.
  Use when the ask is not just "how many complaints" but "which themes, why, and
  how to improve", with traceable representative cases.
- **Opportunity discovery / positive intent** → `references/OPPORTUNITY_DISCOVERY.md`.
  Use for product / marketing / service opportunities (suggestions, recurring
  questions, purchase intent, unmet needs). Run it as a **separate scoped pass**
  from complaint analysis — do not share one broad pull for both.
- **CS reply-quality review / per-agent training material** → `references/CS_QUALITY_REVIEW.md`.
  Use to evaluate the **staff responder** (not the customer) and compile
  exemplary / needs-improvement cases per agent. Runs on Strategy A
  (`messaging_message_search`) because staff identity is returned only there.
- **FAQ from customer conversations** → `references/FAQ_GENERATION.md`.
  Use when the ask is to compile / generate / summarize 常見問題 from
  conversations. Search with `senderTypes: ["Customer","_User"]` and
  `groupBy: "conversation"`. Do not use opportunity discovery or CS quality
  review as a substitute.

## Guardrails

- Do not call write endpoints (`messaging_customer_send_message`, `broadcast_create`, CRM mutations, MA mutations).
- Do not collect credentials or attempt login bootstrap.
- If authentication is missing, expired, revoked, or the host reports `401` / `403` / authentication-required, hand off to `insightark-session` for host OAuth recovery before retrying. Do not treat network/timeout/`5xx` failures as OAuth problems.
- Do not depend on repository-local code or hidden internal fields.
- Prefer `messaging_message_search` for analysis. Do not rebuild Excel via repeated MCP search; human downloads use Console CS export.
- Page sizes: search／conversation_messages max 1000; conversation_list max 100.

## Period vs timeline vs list (important)

1. **Time-scoped asks** (year／quarter／month／“last 30 days”) → use **`messaging_message_search`** with explicit `startAt`/`endAt`. Do **not** treat `messaging_conversation_messages` as that period’s corpus.
2. **`messaging_conversation_messages`** is **recent timeline only** (no year filter). It may include messages outside the asked period — never use it as a full-year／full-month sample.
3. **`messaging_conversation_list`** is Customer **activity** discovery ordered by `lastMessageAt`. Customers missing `lastMessageAt` are excluded. It is **not** “all historical conversations in the DB”, and list activity bounds are **not** message `createdAt` windows. NEVER use it as an organization census or silent／no-inbound customer count — hand that off to `insightark-customer-manager` (`crm_platform_list` then per-platform `crm_customer_search`).
4. **Non-text** hits (image／file／video／template／event) often lack analyzable text. Do not treat media／file counts as engagement or satisfaction.
5. **Long ranges:** search max **90 days**. An explicit range greater than 90 days fails with `error/date-range-too-large` **before** monthly credit (RPM may still increment). Split longer periods into ≤90-day windows using known calendar bounds. Do **not** trial-and-error the cap until a charged call succeeds.
6. **Staff identity:** MCP does **not** expose client `includeUserContact`. `messaging_message_search` always enriches `_User` with `userName`／`userEmail` internally — request `_User` via `senderTypes` when you need attribution. `messaging_conversation_messages` does **not** enrich staff identity; if fields are null, report “無法歸屬”, do not guess.

## Message search sender filters (important)

Use only `senderTypes` (string array). Exact allowed class strings come from the MCP tool schema `senderTypes.items.enum`.

Default (omit `senderTypes`) returns **Customer only**. Staff `userName` / `userEmail` only appear on `_User` rows.

| Goal | Args |
|---|---|
| Customer messages | omit `senderTypes`, or `senderTypes: ["Customer"]` |
| Staff / CS replies | `senderTypes: ["_User"]` |
| Full dialogue | `senderTypes: ["Customer", "_User"]` — one tool call, one normal 20-credit charge |
| Super8 automatic outbound (bots, marketing automation, AI Agent, game/coupon modules including coupon and Shopify, and a generic “system” ask for those). Payload `sender` examples (identity, not a filter): `aiBot`, `marketing_automation`, `bot_executor`, `ec_shopify` | `senderTypes: ["AddOn"]` |
| Broadcast / campaign copy | `broadcast_list` / `broadcast_get` — not message search |
| Facebook/Instagram third-party direct-to-customer (Messenger/IG echo); LINE inbound does not use this class | `senderTypes: ["ForeignBot"]` |

Never pass singular `senderType`. Prefer one multi-class call over two searches. Narrow with `conversationId` and a small time window when possible.

## Message search time window (important)

Server **always** applies a time window on `messaging_message_search`:

| Args | Effective window |
|---|---|
| omit both `startAt` and `endAt` | **last 14 days** ending now |
| only `startAt` | `endAt = now` |
| only `endAt` | `startAt = endAt − 14 days` |
| both provided | that range, **max 90 days** (larger → `error/date-range-too-large` without consuming monthly credits) |

Over-range windows fail **before** monthly credit debit. Do not iteratively reduce the range to discover the cap.

**Do not rely on the 14-day default when the user asks for a specific period.** If the user says "last 30 days" / "this month" / a date range, always pass explicit `startAt` and `endAt` matching that ask. Omitting them silently truncates the sample to 14 days and under-covers the request.

When customer time language becomes `startAt`/`endAt` instant boundaries, follow `skills/insightark-universal-workflow/references/timezone-policy.md` and disclose the effective timezone. Date-only two-sided ranges need confirmed clocks; one-sided date-only endpoints need a confirmed clock, disclosure of the server-derived opposite bound (`endAt=now` or `startAt=endAt−14d`), and a ≤90-day check — never silently invent midnight. Analysis lenses reuse the canonical Strategy A rules in `references/QUALITATIVE_DETECTION.md`.

## Message search tag filters (important)

`includeTags` matches **current holders** of `Customer.tag` (not tag history). Omit or `"any"` is **OR** (any listed current tag).

| Goal | Args |
|---|---|
| Any of the listed current tags (default) | `includeTags: ["觸發", "完成"]` — omit `includeTagsMode`, or `includeTagsMode: "any"` |
| Every listed current tag (觸發 **and** 完成 together) | `includeTags: ["觸發", "完成"]` **and** `includeTagsMode: "all"` |

Do **not** treat a multi-value `includeTags` list by itself as AND. Simultaneous-tag / 觸發+完成 funnels MUST pass `includeTagsMode: "all"`.

## Message search timeout (`error.code = message_search_timeout`)

When search returns structured `message_search_timeout` (`isError: true`):

1. Never blind-retry identical args (credits are still charged).
2. Split `startAt`/`endAt` into smaller windows; reduce `limit` if needed.
3. Use only published filters: `keyword`, `includeTags`, `includeTagsMode`, `excludeTags`, `conversationId`, `platform`, `senderTypes`, `senderIds`, `contentKinds`, `referralSource`.
4. Limit automatic splits; if still failing, stop and ask the user to narrow scope or use Console.
5. Do not invent unsupported message-type / `contentType` filters.

## Ads inbound / 廣告來源 (Messenger referral)

Console 綠線 / 廣告來源 / ads inbound maps to `messaging_message_search` with `referralSource: "ADS"` (plus explicit `startAt`/`endAt` when the user names a period). Do not invent a dedicated ads MCP tool. Do not scan with `contentKinds: ["event"]` alone when the user asked only for ads. `keyword` does not match ad titles.

This filter matches Facebook / Instagram Messenger ads referral stored as `application/x-notify-event` (`data.referral.source = ADS`). LINE native ads are not this Message path; LINE orgs typically return no hits (empty is success).

Hits are message-level (follow + referral ADS MAY duplicate a customer). Obtain Super8 `customerId` via `conversationId` → `messaging_conversation_get` → `conversation.customerId`. Unique customer count is client-side dedupe of that `customerId`, not the search result count. Do not treat `sender` as Super8 `customerId`. Search hits do not include `customerId`. Deduped ids MAY go to existing tag tools; batch tagging remains S8N-13155.
