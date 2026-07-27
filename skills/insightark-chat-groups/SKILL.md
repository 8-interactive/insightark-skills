---
name: insightark-chat-groups
description: Discover LINE ChatGroups by name and analyze group conversation messages via InsightArk MCP.
when_to_use: When a user asks to find a LINE group by name, open a group room, or analyze／search messages inside a ChatGroup (not 1:1 Customer inbox).
allowed-mcp: true
---

# Skill: insightark-chat-groups

**Prerequisite:** Read `skills/insightark-universal-workflow/SKILL.md` before operational work or domain references.

This skill uses the InsightArk MCP server. Authentication is managed by your host through MCP OAuth (Connect / Authenticate). Every org-scoped tool requires an `orgId` argument. This skill is read-only — no write MCP tools.

## MCP Tools

- `auth_me` — validate session (no `orgId` required)
- `auth_organizations` — list manageable organizations (no `orgId` required)
- `messaging_chat_group_list` — discover ChatGroups by optional literal `groupName` substring; page with `pageCursor`
- `messaging_chat_group_get` — lock a ChatGroup by `chatGroupId` (Mongo `_id`) and read `conversationId`
- `messaging_conversation_messages` — read **recent** messages once you have a group `conversationId` (no year／period filter)
- `messaging_chat_group_message_search` — keyword／time／senderTypes search **inside one group** (exactly one of `conversationId` or `chatGroupId`)

## Do not use for group discovery

| Wrong path | Why |
|---|---|
| `messaging_conversation_list` (even with `platform=line`) | Customer 1:1 inbox only — does **not** list ChatGroups |
| `messaging_message_search` | Customer-join path; default sender is Customer; not group-safe |
| `groupName` on `messaging_chat_group_message_search` | Undeclared — name discovery belongs on **list** only |

## Tool usage scenarios

| Tool | Use when | Do not use when |
|---|---|---|
| `messaging_chat_group_list` | User names a LINE group; need `chatGroupId` / `conversationId` | Claiming “all historical groups in the DB” |
| `messaging_chat_group_get` | You already have `chatGroupId` | Searching by display name |
| `messaging_conversation_messages` | Quick recent-thread peek after id lock | Any year／month／quarter／period analysis |
| `messaging_chat_group_message_search` | Keyword／**period**／sender analysis after id lock | Before resolving which group |

## Analysis rules (important)

1. **Time-scoped asks** (a year, quarter, month, “last 30 days”, date range) → use **only** `messaging_chat_group_message_search` with explicit `startAt`/`endAt`. Do **not** use `messaging_conversation_messages` as that period’s corpus.
2. **`messaging_conversation_messages`** returns the **most recent** messages only — no year filter. It may mix older／newer windows; never treat it as “all of 2026” (or any named period).
3. **`messaging_chat_group_list`** returns discoverable groups that have usable `lastMessageAt`. It is **not** “every ChatGroup ever stored”. Groups missing `lastMessageAt` are excluded. Do not claim the list is a full historical inventory.
4. **Non-text** rows (image／file／video／template／event) often expose only type／filename. Do **not** treat file or media counts as engagement or satisfaction.
5. **Multi-window cost:** search span max **90 days**. For a longer period, split into ≤90-day windows. Before running, estimate credits ≈ `groups × windows × 20` (+ list／get／optional timeline peeks) and disclose the estimate.
6. **Staff identity:** MCP does **not** expose a client `includeUserContact` argument (same as 1:1 `messaging_message_search`). Group search **always** enriches `_User` rows with `userName`／`userEmail` internally. Use search when you need per-agent attribution. `messaging_conversation_messages` does **not** enrich staff identity — if those fields are null there, say “無法歸屬／identity unavailable”, do **not** guess the sender.

## Workflow

1. Resolve `orgId` from user context or `auth_organizations`.
2. Call `messaging_chat_group_list` with `groupName` (literal substring; regex metacharacters are escaped). Page with `pageCursor` when `nextPageCursor` is present.
3. If multiple hits match, **disambiguate** with the user (name, `platform`, `lastMessageAt`, `memberCount`) before analysis. Optionally call `messaging_chat_group_get` to confirm.
4. Lock either `conversationId` or `chatGroupId` from the chosen row.
5. Analyze:
   - Recent peek only → `messaging_conversation_messages`
   - Keyword／**period**／sender analysis → `messaging_chat_group_message_search` with exactly one scope id (never both, never neither, never `groupName`)
6. Default search senders are `Group`, `_User`, `Organization`, `AddOn`. Add `ForeignBot` only when explicitly needed. Defaults already include `_User`, so staff identity fields are available without an extra client flag.
7. Time window: omit `startAt`/`endAt` → last **14** days; explicit range max **90** days. Pass explicit bounds when the user asks for a specific period; split longer ranges into sequential ≤90-day searches.

## Guardrails

- Stay within the published InsightArk MCP surface.
- Do **not** treat `messaging_conversation_list` as LINE group discovery.
- Do **not** pass `groupName` to message search.
- Do not assume a group id until list/get returns it.
- `message_search_in_progress` means you already have another message search in
  this organization (including Console) in progress. It is zero-charge: wait
  for completion, then retry once; do not send parallel retries or treat it as
  a timeout.
- If authentication is missing, expired, revoked, or the host reports `401` / `403` / authentication-required, hand off to `insightark-session` for host OAuth recovery before retrying.
