---
name: insightark-investigator
description: Investigate conversations and messages through InsightArk MCP using read-only tools.
when_to_use: When a user asks a natural language investigation question that may require session validation, organization scoping, conversation discovery, conversation inspection, message search, or compiling an FAQ / 常見問題 from customer conversations.
allowed-mcp: true
---

# Skill: insightark-investigator

**Prerequisite:** Read `skills/insightark-universal-workflow/SKILL.md` before operational work or domain references.

This skill uses the InsightArk MCP server. Authentication is managed by your host through MCP OAuth (Connect / Authenticate). Every org-scoped tool requires an `orgId` argument. This skill is read-only — no write MCP tools.

**Audience:** Use this skill for 1:1 Customer conversations. For LINE ChatGroup discovery or group-message analysis, hand off to `insightark-chat-groups` (do not use `messaging_conversation_list` for groups).

## MCP Tools

- `auth_me` / `auth_organizations` — validate session or list orgs (no `orgId`)
- `messaging_conversation_list` — browse inbox／activity by Customer `lastMessageAt` (`cursor`)
- `messaging_conversation_get` — get one conversation summary
- `messaging_conversation_messages` — read the recent timeline (not a period corpus)
- `messaging_message_search` — search by period／keyword／tag／`contentKinds`／`referralSource`

## Workflow

1. Call `auth_me`／`auth_organizations` only when the session is not yet trusted; resolve `orgId` before any org-scoped call.
2. Pick a path:
   - Inbox／who was active recently → `messaging_conversation_list`
   - One thread → `messaging_conversation_get` + `messaging_conversation_messages`
   - Period／keyword／theme evidence → `messaging_message_search` (prefer this for qualitative stats)
3. While `page.hasMore` is true: if `truncated === true` and `keptCount < returnedCount`, set next `skip = page.skip + keptCount`; otherwise `skip = page.skip + page.limit`.
4. Answer from returned public fields only — keep it concise, and do not invent internal fields.

## Qualitative / lenses (load on demand)

For batch intent／sentiment／complaint reading, load `references/QUALITATIVE_DETECTION.md`.

| Ask | Load |
| --- | ---- |
| Themes／root cause／how to improve | `references/ROOT_CAUSE_ANALYSIS.md` |
| Opportunities／recurring asks／purchase intent | `references/OPPORTUNITY_DISCOVERY.md` (run as a separate pass from complaints) |
| Per-agent CS reply quality | `references/CS_QUALITY_REVIEW.md` (needs `messaging_message_search` for `_User` identity) |
| FAQ／常見問題 from conversations | `references/FAQ_GENERATION.md` (`senderTypes: ["Customer","_User"]`, `groupBy: "conversation"`) |

## Guardrails

- Do not call write MCP tools. Do not collect credentials or attempt login bootstrap.
- If authentication is missing, expired, revoked, or the host reports `401`／`403`／authentication-required, hand off to `insightark-session` for OAuth recovery. Network／timeout／`5xx` failures are not OAuth problems.
- Prefer `messaging_message_search` for analysis. Do not rebuild Excel via repeated MCP search; full human export uses Console CS export.
- Do not invent hidden or repository-only fields.
- Run `messaging_message_search` serially for a given user／org — it shares a one-at-a-time lock with `messaging_chat_group_message_search` and Console findMessage. Do not call them in parallel. On `message_search_in_progress`, wait and retry once (zero-charge; not a timeout).

## Path pitfalls (important)

These distinctions are easy to miss when reading a single tool schema; choosing the wrong tool produces the wrong answer:

1. **Named period** (“last 30 days”, month／quarter／year): use `messaging_message_search` with explicit `startAt`/`endAt`. Never treat `messaging_conversation_messages` as that period’s corpus (it is recent-only and has no year filter).
2. **`messaging_conversation_list`** returns activity ordered by `lastMessageAt` (customers missing `lastMessageAt` are excluded). It is not a DB census, not message-`createdAt` proportions, and not a silent／no-inbound count — hand those off to `insightark-customer-manager` (`crm_platform_list`, then `crm_customer_search`).
3. **Media／file／event counts** are not engagement or satisfaction metrics.
4. On **`error/date-range-too-large`**, the call fails **before the search runs** (before debit). Split into sequential schema-legal windows from known calendar bounds. Do not discover the max by trial-and-error retries.
5. **Staff attribution:** only `messaging_message_search` enriches `_User` with `userName`／`userEmail`. The timeline tool does not — report 「無法歸屬」 and do not guess. There is no client `includeUserContact` argument.

## Message search decisions

**Senders:** Use only `senderTypes`. Never pass singular `senderType`. Exact allowed class strings come from the MCP tool schema. Prefer one multi-class call over two searches. Super8 automatic outbound → `senderTypes: ["AddOn"]`. Facebook/Instagram third-party DMs → `senderTypes: ["ForeignBot"]`. For broadcast／campaign copy, use `broadcast_list`／`broadcast_get`, not message search.

**Time:** Always pass explicit `startAt`/`endAt` when the user names a period — omitting both falls back to the schema default and under-covers the ask. For date-only or one-sided language, follow `skills/insightark-universal-workflow/references/timezone-policy.md`, confirm clocks, and never invent midnight. Analysis lenses follow `references/QUALITATIVE_DETECTION.md`.

**Tags:** `includeTags` matches **current** holders, not tag history. A multi-value list alone is OR; for 觸發+完成／every listed tag together, pass `includeTagsMode: "all"`.

Who received a tag during a date window is not that combinator — hand off to `insightark-customer-manager` (`crm_customer_search` with `taggedAtFrom` / `taggedAtTo` as `YYYY-MM-DD`).

**Timeout (`message_search_timeout`):** Never blind-retry identical arguments. Narrow the time window or filters first; lower `limit` only after a large page already failed. If it still fails, stop and ask the user or point to Console. Do not invent unsupported `contentType` filters.

**Ads／綠線／廣告來源:** Use `referralSource: "ADS"` (plus explicit dates when the user names a period). Do not invent a separate ads tool; do not scan with only `contentKinds: ["event"]`; `keyword` does not match ad titles. LINE native ads usually return empty (that is success). Hits are message-level — unique customers require deduping `conversationId` → `messaging_conversation_get` → `customerId` (search rows have no `customerId`; `sender` is not the Super8 customer id). When tagging those unique customers, hand off to `insightark-customer-manager` (`crm_customer_tag_batch_add` / `crm_customer_tag_batch_remove` and `crm_system_task_get`). Investigator MUST NOT list or invoke those three tools.

**`fields`:** For analysis, suggest passing only the strictly necessary keys for the ask to save bandwidth. Omit `fields` only when the full default blob is required. Keep `data` whole — do not project dotted paths.

**`limit`:** Prefer the largest schema-legal page size so fewer list calls are needed. Shrink only when the user asks, the host truncates／memory is tight, a timeout forces it, or Gate A/B leads to a smaller scope — not merely to look conservative.

**Gate A:** For corpus／analysis searches with no keyword, call `return: "count"` first when that parameter exists on the schema. If `ceil(count / planned-list-limit) > 5`, ask before listing (if list `limit` is omitted, use the schema default). After Gate A passes or the user approves, still use a large page.

**Gate B:** Apply only when `truncated === true` and `keptCount < returnedCount`: ask if `ceil(count / keptCount) > 5`, and set next `skip = page.skip + keptCount`. If `keptCount === returnedCount` or truncation fields are absent, Gate B does not apply — use `skip = page.skip + page.limit`. Never advance by `page.count`.
