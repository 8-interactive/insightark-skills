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
8. **Search cost and coverage:** each search call costs **20** credits and spans at most **90 days**. For a longer period, split into ≤90-day windows. For multi-call analysis, keep the same explicit `startAt`/`endAt`, disclose the estimate (approximately `windows × pages × 20`, plus list／get／optional timeline peeks), and report the actual coverage; do not infer complete organization-wide coverage from one full page.
9. **Staff identity:** MCP does **not** expose a client `includeUserContact` argument. Group search **always** enriches `_User` rows with `userName`／`userEmail` internally. `messaging_conversation_messages` does **not** enrich staff identity — if those fields are null there, say “無法歸屬／identity unavailable”, do **not** guess the sender.

## Workflow

1. Resolve `orgId` from user context or `auth_organizations`.
2. **Org-wide／cross-group analysis:** call `messaging_chat_group_message_search` with `orgId`, explicit time bounds when the user names a period, and optional `keyword`／`senderTypes`／`contentKinds`.
3. **Named group:** call `messaging_chat_group_list` with `groupName` (literal substring; regex metacharacters are escaped). Continue while `page.hasMore` is true by echoing `page.nextCursor` as `cursor`. Do **not** parse or hand-craft cursors.
4. If multiple list hits match, **disambiguate** with the user (name, `platform`, `lastMessageAt`, `memberCount`) before analysis. Optionally call `messaging_chat_group_get` to confirm.
5. Lock either `conversationId` or `chatGroupId` from the chosen row (not both).
6. Analyze the locked room:
   - Recent peek only → `messaging_conversation_messages`
   - Keyword／**period**／sender／content analysis → `messaging_chat_group_message_search` with exactly one scope id
7. Default search senders are `Group`, `_User`, `AddOn`. `AddOn` is Super8 automatic outbound (bots, marketing automation, AI Agent, game/coupon modules). Add `ForeignBot` only when explicitly needed: Facebook/Instagram third-party direct-to-customer only (Messenger/IG echo). LINE inbound does not use this class.
8. Time window: omit `startAt`/`endAt` → last **14** days; explicit range max **90** days. Pass explicit bounds when the user asks for a specific period; split longer ranges into ≤90-day windows. Continue `messaging_chat_group_message_search` while `page.hasMore` is true with `skip = page.skip + page.limit`.

## Guardrails

- Stay within the published InsightArk MCP surface.
- Do not assume a group id until list/get returns it (for named-room work).
- `message_search_in_progress` means you already have another message search in
  this organization (including Console) in progress. It is zero-charge: wait
  for completion, then retry once; do not send parallel retries or treat it as
  a timeout.
- If authentication is missing, expired, revoked, or the host reports `401` / `403` / authentication-required, hand off to `insightark-session` for host OAuth recovery before retrying.
