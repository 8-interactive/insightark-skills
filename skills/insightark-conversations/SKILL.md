---
name: insightark-conversations
description: Browse conversation lists with organization scope and supported filters via InsightArk MCP.
when_to_use: When a user wants to browse or page inbox-style conversations by organization, customer, platform, inbox state, or Customer last-activity window (lastMessageAtFrom/To) with optional pageCursor.
allowed-mcp: true
---

# Skill: insightark-conversations

**Prerequisite:** Read `skills/insightark-universal-workflow/SKILL.md` before operational work or domain references.

This skill uses the InsightArk MCP server. Authentication is managed by your host through MCP OAuth (Connect / Authenticate). Every org-scoped tool requires an `orgId` argument.

## MCP Tools

- `messaging_conversation_list` — list conversations ordered by latest Customer activity (`lastMessageAt`)
- `messaging_conversation_get` — open one conversation summary (requires `orgId`, `conversationId`)

## Tool usage scenarios

| Tool | Use when | Do not use when |
|---|---|---|
| `messaging_conversation_list` | Inbox triage; “who was active in this period”; page older activity; list a known customer’s conversations | Message-level sentiment／complaint proportions; keyword theme search across the org |
| `messaging_conversation_get` | You already have a `conversationId` and need a summary | Scanning many conversations |

For message bodies, keyword evidence, or org-wide time-window **message** analysis, use `insightark-investigator` / `messaging_message_search` (and `messaging_conversation_messages` for one thread).

## Activity window vs message search window

- **List** `lastMessageAtFrom` / `lastMessageAtTo` filter Customer **`lastMessageAt`** (last activity on the conversation).
- **Search** `startAt` / `endAt` filter message **`createdAt`** (what was said in a period).
- Do **not** pass search’s `startAt`/`endAt` on `messaging_conversation_list`.

### List activity bounds

- Instants MUST include an explicit offset or `Z`. Reject date-only at the tool; follow `skills/insightark-universal-workflow/references/timezone-policy.md` when encoding customer calendar language (confirm clock boundaries; do not invent midnight).
- Only `From` → server sets `To = now`; span must be ≤ **90 days**.
- Only `To` → server sets `From = To − 90 days`.
- Both → span ≤ **90 days**.
- Neither → inbox mode (newest activity first). Customers missing `lastMessageAt` (e.g. brand-outbound-only) are excluded.

### Pagination (`pageCursor`)

- Echo `page.nextPageCursor` as the next call’s `pageCursor`. Do **not** parse or hand-craft cursors.
- `pageCursor` is an opaque keyset continuation hint for `(lastMessageAt, _id)` — **not** an auth or signed token.
- A short returned conversation count does not always mean “no more pages” if hydration skipped rows; trust `nextPageCursor`.

Optional filters: `customerId`, `platform`, `inbox`, `limit` (max **100**). Exact `inbox` tokens come from the MCP tool schema enum.

## Workflow

1. Resolve `orgId` from user context or `auth_organizations`.
2. Call `messaging_conversation_list` with supported filters. For “active that day/week”, pass confirmed `lastMessageAtFrom`/`lastMessageAtTo` instants; page with `pageCursor` when `nextPageCursor` is present.
3. If the user asks to open a specific conversation, call `messaging_conversation_get` with `orgId` + `conversationId` from the list.
4. Return the public conversation list (and optionally one conversation summary) without exposing internal query structure.

## Guardrails

- Stay within the published read-side InsightArk MCP / public schema surface.
- `inbox` must be a published schema value (e.g. unassigned / done / private / bot / spam — confirm against schema).
- `platform` is a Super8 channel id string (e.g. line, facebook); do not invent channels.
- The list is **customer-activity driven**: results are ordered by customer `lastMessageAt` (not full-text relevance).
- This skill covers **1:1 Customer conversations only**. For LINE ChatGroups (find by group name, analyze group messages), use `insightark-chat-groups` — do **not** treat `messaging_conversation_list` with `platform=line` as group discovery.
- Do **not** describe list results as “all historical conversations in the database”: Customers missing `lastMessageAt` are excluded, and there is no full-history inventory mode.
- For **period／year message analysis**, hand off to `insightark-investigator` (or `insightark-chat-groups` for LINE groups). `messaging_conversation_list` filters Customer activity, not message `createdAt`.
- Do not assume a conversation id until it is returned by the API.
- If authentication is missing, expired, revoked, or the host reports `401` / `403` / authentication-required, hand off to `insightark-session` for host OAuth recovery before retrying. Do not treat network/timeout/`5xx` failures as OAuth problems.
