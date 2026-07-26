---
name: insightark-investigator
description: Investigate conversations and messages through InsightArk MCP using read-only tools.
when_to_use: When a user asks a natural language investigation question that may require session validation, organization scoping, conversation discovery, conversation inspection, or message search.
allowed-mcp: true
---

# Skill: insightark-investigator

**Prerequisite:** Read `skills/insightark-universal-workflow/SKILL.md` before operational work or domain references.

This skill uses the InsightArk MCP server. Authentication is managed by your host through MCP OAuth (Connect / Authenticate). Every org-scoped tool requires an `orgId` argument. This skill is read-only — no write MCP tools.

**Audience:** 1:1 / Customer conversations. For LINE **ChatGroup** discovery or group-message analysis, hand off to `insightark-chat-groups` (do not use `messaging_conversation_list` as group discovery).

## MCP Tools

- `auth_me` — validate session (no `orgId` required)
- `auth_organizations` — list manageable organizations (no `orgId` required)
- `messaging_conversation_list` — browse／page conversations by Customer last activity (`lastMessageAtFrom`/`To`, `pageCursor`)
- `messaging_conversation_get` — get one conversation summary
- `messaging_conversation_messages` — read message timeline
- `messaging_message_search` — time／keyword／`contentKinds` message search (Strategy A primary path)

## Workflow

1. Call `auth_me` or `auth_organizations` when the caller's session context is not yet trusted.
2. Resolve `orgId` before any org-scoped tool.
3. Choose one operational path:
   - `messaging_conversation_list` for inbox／activity discovery and `pageCursor` paging (not message-proportion analysis)
   - `messaging_conversation_get` and `messaging_conversation_messages` for one conversation and its timeline
   - `messaging_message_search` for time-window／keyword／`contentKinds` evidence (prefer for qualitative stats)
4. Return a concise read-only investigation result grounded in the public API response.

## Qualitative detection (intent / sentiment / complaint)

For batch qualitative reading — judging customer intent, sentiment, or complaints
across a set of conversations rather than a single lookup — load
`references/QUALITATIVE_DETECTION.md` on demand and follow it. It covers:

- **Path selection**: tag-segmented audiences use `crm_customer_search` →
  `messaging_conversation_list` → `messaging_conversation_messages` (the only
  tag-aware path); time-window / keyword audiences use `messaging_message_search`.
- **Cost guardrails**: use each completed call's returned `chargedCredits` for
  per-call and run-total reporting; `credits_usage` only inspects remaining
  balance and must not be used to infer cost, especially for concurrent reads.
  Respect hard sample caps, and never blind-retry — batch reads cost more than
  the nominal per-call rate.
- **Reading rules**: findings must cite specific messages, must not fabricate
  complaints, and are human-reviewable signals, not authoritative labels.

### Analysis lenses (same tools, same guardrails)

`QUALITATIVE_DETECTION.md` is the shared foundation (path selection + cost
guardrails + reading rules). Two focused lenses build on it — load the one that
matches the ask, then follow the shared Strategy A/B and sample/credit caps:

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

## Guardrails

- Do not call write endpoints (`messaging_customer_send_message`, `broadcast_create`, CRM mutations, MA mutations).
- Do not collect credentials or attempt login bootstrap.
- If authentication is missing, expired, revoked, or the host reports `401` / `403` / authentication-required, hand off to `insightark-session` for host OAuth recovery before retrying. Do not treat network/timeout/`5xx` failures as OAuth problems.
- Do not depend on repository-local code or hidden internal fields.
- Prefer `messaging_message_search` for analysis. Do not rebuild Excel via repeated MCP search; human downloads use Console CS export.
- Page sizes: search／conversation_messages max 1000; conversation_list max 100.

## Message search sender filters (important)

Use only `senderTypes` (string array). Exact allowed class strings come from the MCP tool schema `senderTypes.items.enum`.

Default (omit `senderTypes`) returns **Customer only**. Staff `userName` / `userEmail` only appear on `_User` rows.

| Goal | Args |
|---|---|
| Customer messages | omit `senderTypes`, or `senderTypes: ["Customer"]` |
| Staff / CS replies | `senderTypes: ["_User"]` |
| Full dialogue | `senderTypes: ["Customer", "_User"]` — one tool call, one normal 20-credit charge |
| AddOn / extension messages | `senderTypes: ["AddOn"]` |
| Brand / org-originated (e.g. broadcast) | `senderTypes: ["Organization"]` |
| External bot messages | `senderTypes: ["ForeignBot"]` |

Never pass singular `senderType`. Prefer one multi-class call over two searches. Narrow with `conversationId` and a small time window when possible.

## Message search time window (important)

Server **always** applies a time window on `messaging_message_search`:

| Args | Effective window |
|---|---|
| omit both `startAt` and `endAt` | **last 14 days** ending now |
| only `startAt` | `endAt = now` |
| only `endAt` | `startAt = endAt − 14 days` |
| both provided | that range, **max 90 days** (larger → `error/date-range-too-large`) |

**Do not rely on the 14-day default when the user asks for a specific period.** If the user says "last 30 days" / "this month" / a date range, always pass explicit `startAt` and `endAt` matching that ask. Omitting them silently truncates the sample to 14 days and under-covers the request.

When customer time language becomes `startAt`/`endAt` instant boundaries, follow `skills/insightark-universal-workflow/references/timezone-policy.md` and disclose the effective timezone. Date-only two-sided ranges need confirmed clocks; one-sided date-only endpoints need a confirmed clock, disclosure of the server-derived opposite bound (`endAt=now` or `startAt=endAt−14d`), and a ≤90-day check — never silently invent midnight. Analysis lenses reuse the canonical Strategy A rules in `references/QUALITATIVE_DETECTION.md`.

## Message search timeout (`error.code = message_search_timeout`)

When search returns structured `message_search_timeout` (`isError: true`):

1. Never blind-retry identical args (credits are still charged).
2. Halve `startAt`/`endAt` and search sequentially; reduce `limit` if needed.
3. Use only published filters: `keyword`, `conversationId`, `platform`, `senderTypes`, `senderIds`.
4. Limit automatic splits; if still failing, stop and ask the user to narrow scope or use Console.
5. Do not invent unsupported message-type / `contentType` filters.
