---
name: insightark-chat-groups
description: Discover LINE ChatGroups by name and analyze group conversation messages via InsightArk MCP.
when_to_use: When a user asks to find a LINE group by name, open a group room, or analyze／search messages inside ChatGroups (single room or organization-wide — not 1:1 Customer inbox).
allowed-mcp: true
---

# Skill: insightark-chat-groups

**Customer language:** This workflow operates Console **群組對話** (LINE ChatGroups). Prefer 群組對話 in customer-facing speech; MCP tool ids remain `messaging_chat_group_*`.

**Prerequisite:** Read `skills/insightark-universal-workflow/SKILL.md` before operational work or domain references.

This skill uses the InsightArk MCP server. Authentication is managed by your host through MCP OAuth (Connect / Authenticate). Every org-scoped tool requires an `orgId` argument. This skill is read-only — no write MCP tools.

## MCP Tools

- `auth_me` — validate session (no `orgId` required)
- `auth_organizations` — list manageable organizations (no `orgId` required)
- `messaging_chat_group_list` — discover ChatGroups by optional literal `groupName` substring
- `messaging_chat_group_get` — lock a ChatGroup by `chatGroupId` (Mongo `_id`) and read `conversationId`
- `messaging_conversation_messages` — read **recent** messages once you have a group `conversationId` (no year／period filter)
- `messaging_chat_group_message_search` — keyword／time／senderTypes／contentKinds search over ChatGroup messages (**organization-wide by default**; optionally narrow with exactly one of `conversationId` or `chatGroupId`)

## Tool usage scenarios

| Tool | Use when |
|---|---|
| `messaging_chat_group_list` | User names a LINE group; need `chatGroupId` / `conversationId` |
| `messaging_chat_group_get` | You already have `chatGroupId` |
| `messaging_conversation_messages` | Quick recent-thread peek after id lock |
| `messaging_chat_group_message_search` | Org-wide／cross-group period／keyword／content analysis, or single-room analysis after id lock |

For LINE ChatGroups, use the routes above. `messaging_conversation_list` and `messaging_message_search` cover Customer 1:1 conversations.

## Analysis rules (important)

1. **Organization-wide or cross-group asks** (all groups, monthly themes, org sweeps) → call `messaging_chat_group_message_search` **without** `conversationId`／`chatGroupId`. Do **not** enumerate groups solely to issue one search per group when org-wide scope satisfies the ask.
2. **Named single-group asks** → resolve via list/get, then pass exactly one of `conversationId` or `chatGroupId`.
3. **Time-scoped asks** (a year, quarter, month, “last 30 days”, date range) → use **only** `messaging_chat_group_message_search` with explicit `startAt`/`endAt`. Do **not** use `messaging_conversation_messages` as that period’s corpus.
4. **`contentKinds`** — use the public kinds (`text`, `template`, `image`, `file`, `event`), not raw MIME types. Include-only; when present with `keyword`, MIME selection overrides the keyword text/template default while keyword still matches `data.content`.
5. **`messaging_conversation_messages`** returns the **most recent** messages only — no year filter. Never treat it as “all of 2026” (or any named period).
6. **`messaging_chat_group_list`** returns discoverable groups that have usable `lastMessageAt`. It is **not** “every ChatGroup ever stored”. Org-wide search uses Message `isGroup: true` and MAY include rooms absent from the current list page／filter. Do not claim the list is a full historical inventory.
7. **Non-text** rows (image／file／video／template／event) often expose only type／filename. Do **not** treat file or media counts as engagement or satisfaction.
8. **Search coverage:** On `error/date-range-too-large`, split into sequential schema-legal windows. Keep the same explicit `startAt`/`endAt` across pages and report actual coverage — do not infer complete organization-wide coverage from one full page. If the user asks about usage, hand off to `insightark-session` (`credits_usage`); do not treat tool JSON as a receipt; MUST NOT claim other tools return `chargedCredits`.
9. **Staff attribution:** Group search enriches `_User` identity; `messaging_conversation_messages` does not — report 「無法歸屬」 and do not guess. There is no client `includeUserContact` argument.

## Workflow

1. Resolve `orgId` from context or `auth_organizations`.
2. For org-wide／cross-group analysis, call `messaging_chat_group_message_search` without scope ids, and pass explicit dates when the user names a period.
3. For a named group, call `messaging_chat_group_list` with a literal `groupName` substring. Continue paging only by setting `cursor` to `page.nextCursor` — do not hand-craft cursors. If several hits match, disambiguate with the user; optionally confirm with `messaging_chat_group_get`.
4. Lock exactly one of `conversationId` or `chatGroupId`.
5. For a recent peek, use `messaging_conversation_messages`. For period／keyword／sender／content analysis, call `messaging_chat_group_message_search` with that one scope id.
6. Default search senders are `Group`, `_User`, `AddOn` (Super8 automatic outbound: bots, marketing automation, AI Agent, game/coupon modules); add `ForeignBot` only when needed (Facebook/Instagram third-party direct-to-customer; Messenger／IG echo; not LINE inbound).
7. While `page.hasMore` is true: if `truncated === true` and `keptCount < returnedCount`, set `skip = page.skip + keptCount`; otherwise `skip = page.skip + page.limit`.

## Fields, limit, and gates

**`fields`:** For analysis, pass only the keys needed for the ask. Omit `fields` only when the full default is required. Keep `data` whole.

**`limit`:** Prefer the largest schema-legal page size. Shrink only for user request, truncation／memory, timeout, or Gate scope reduction — not merely to look conservative.

**Gate A:** For no-keyword corpus／analysis, call `return: "count"` first when that parameter exists on the schema. If `ceil(count / planned-list-limit) > 5`, ask before listing (omitted list `limit` uses the schema default). After approval, still use a large page.

**Gate B:** Apply only when `truncated === true` and `keptCount < returnedCount`: ask if `ceil(count / keptCount) > 5`, and set `skip = page.skip + keptCount`. Otherwise use `skip = page.skip + page.limit`. Never advance by `page.count`.

## Guardrails

- Stay within the published InsightArk MCP surface.
- Do not assume a group id until list/get returns it (for named-room work).
- Run `messaging_chat_group_message_search` serially for a given user／org — it shares a one-at-a-time lock with `messaging_message_search` and Console findMessage. Do not call them in parallel. On `message_search_in_progress`, wait and retry once (zero-charge; not a timeout).
- If authentication is missing, expired, revoked, or the host reports `401` / `403` / authentication-required, hand off to `insightark-session` for host OAuth recovery before retrying.
