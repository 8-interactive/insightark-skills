---
name: super8-studio-conversations
description: Operate on the Super 8 Studio Developer API to browse conversation lists with organization scope, cursors, and supported filters.
when_to_use: When a user wants to find or list conversations by organization, customer, platform, inbox state, time filter, or cursor.
allowed-mcp: false
---

# Skill: super8-studio-conversations

This skill operates on the Super 8 Studio Developer API.

## Script

- `node ../_super8-studio-api-shared/scripts/conversations.js`

## CLI

- `--org-id <id>` (optional, falls back to `S8_ORG_ID`)
- `--customer-id <id>` (optional; filters to one customer)
- `--platform <channel>` (optional; filters by channel — accepted values are defined by the developer conversation list API)
- `--inbox <state>` (optional; filters customers whose `inbox` array contains the value — `unassigned`, `done`, `private`, `bot`, or `spam`)
- `--start-at <ISO 8601>` (optional; lower bound for the chosen time field)
- `--end-at <ISO 8601>` (optional; upper bound for the chosen time field)
- `--time-field <lastMessageAt|lastInboundAt>` (optional; required when `--start-at` or `--end-at` is provided)
- `--cursor <token>` (optional; forward-pagination token returned by a previous page)
- `--limit <n>` (optional; page size)

## Workflow

1. Ensure organization context is available through `--org-id` or `S8_ORG_ID`.
2. Pass only supported filters such as `customerId`, `platform`, `inbox`, `startAt`, `endAt`, `timeField`, `cursor`, and `limit`.
3. Return the public conversation list and page metadata without exposing internal query structure.

## Guardrails

- Stay within the published read-side developer API surface.
- The list is **customer-activity driven**: results are ordered by customer `lastMessageAt` (not full-text relevance). Use `super8-studio-message-search` when the user asks for keyword evidence across messages.
- Do not assume a conversation id until it is returned by the API.
