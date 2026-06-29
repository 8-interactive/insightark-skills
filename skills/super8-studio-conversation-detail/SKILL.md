---
name: super8-studio-conversation-detail
description: Operate on the SUPER 8 Studio Developer API to inspect one conversation and its public message timeline.
when_to_use: When a user already has a conversation id or wants to open a conversation result and optionally read its messages.
allowed-mcp: false
---

# Skill: super8-studio-conversation-detail

This skill operates on the SUPER 8 Studio Developer API.

## Scripts

- `node ../_super8-studio-api-shared/scripts/conversation_detail.js`
- `node ../_super8-studio-api-shared/scripts/conversation_messages.js`

## CLI

### conversation_detail.js

- `--org-id <id>` (optional, falls back to `S8_ORG_ID`)
- `--conversation-id <id>` (required)

### conversation_messages.js

- `--org-id <id>` (optional, falls back to `S8_ORG_ID`)
- `--conversation-id <id>` (required)
- `--cursor <token>` (optional; forward-pagination token returned by a previous page)
- `--limit <n>` (optional; page size)
- `--order <asc|desc>` (optional; defaults to `desc` on the API — newest first)

## Workflow

1. Resolve organization context through `--org-id` or `S8_ORG_ID`.
2. Run `conversation_detail.js --conversation-id <id>` for the conversation summary.
3. Run `conversation_messages.js --conversation-id <id>` when the user asks for the message timeline.

## Guardrails

- Require an explicit conversation id before opening detail routes.
- Prefer `--order desc` when building agent context (recent messages first). With `asc`, the oldest page may include legacy `application/x-template` rows whose `createdAt` is null.
- Keep the output limited to the public developer API response fields.
