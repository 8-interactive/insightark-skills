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
- `messaging_conversation_messages` — read recent messages once you have a group `conversationId`
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
| `messaging_chat_group_list` | User names a LINE group; need `chatGroupId` / `conversationId` | Browsing 1:1 inbox |
| `messaging_chat_group_get` | You already have `chatGroupId` | Searching by display name |
| `messaging_conversation_messages` | Read recent thread after id lock | Org-wide keyword themes |
| `messaging_chat_group_message_search` | Keyword／time analysis **after** id lock | Before resolving which group |

## Workflow

1. Resolve `orgId` from user context or `auth_organizations`.
2. Call `messaging_chat_group_list` with `groupName` (literal substring; regex metacharacters are escaped). Page with `pageCursor` when `nextPageCursor` is present.
3. If multiple hits match, **disambiguate** with the user (name, `platform`, `lastMessageAt`, `memberCount`) before analysis. Optionally call `messaging_chat_group_get` to confirm.
4. Lock either `conversationId` or `chatGroupId` from the chosen row.
5. Analyze:
   - Recent timeline → `messaging_conversation_messages`
   - Keyword／period／sender analysis → `messaging_chat_group_message_search` with exactly one scope id (never both, never neither, never `groupName`)
6. Default search senders are `Group`, `_User`, `Organization`, `AddOn`. Add `ForeignBot` only when explicitly needed.
7. Time window: omit `startAt`/`endAt` → last **14** days; explicit range max **90** days. Pass explicit bounds when the user asks for a specific period.

## Guardrails

- Stay within the published InsightArk MCP surface.
- Do **not** treat `messaging_conversation_list` as LINE group discovery.
- Do **not** pass `groupName` to message search.
- Do not assume a group id until list/get returns it.
- If authentication is missing, expired, revoked, or the host reports `401` / `403` / authentication-required, hand off to `insightark-session` for host OAuth recovery before retrying.
