---
name: super8-studio-conversation-detail
description: Operate on the Super 8 Studio Developer API to inspect one conversation and its public message timeline.
when_to_use: When a user already has a conversation id or wants to open a conversation result and optionally read its messages.
allowed-mcp: false
license: MIT
metadata:
  owner: platform
  version: "1.0.0"
  category: conversation-api
  domain: super8-studio
---

# Skill: super8-studio-conversation-detail

This skill operates on the Super 8 Studio Developer API.

## Scripts

- `../_super8-studio-api-shared/scripts/conversation_detail.sh`
- `../_super8-studio-api-shared/scripts/conversation_messages.sh`

## CLI

### conversation_detail.sh

- `--org-id <id>` (optional, falls back to `S8_ORG_ID`)
- `--conversation-id <id>` (required)

### conversation_messages.sh

- `--org-id <id>` (optional, falls back to `S8_ORG_ID`)
- `--conversation-id <id>` (required)
- `--cursor <token>` (optional; forward-pagination token returned by a previous page)
- `--limit <n>` (optional; page size)
- `--order <asc|desc>` (optional; defaults to `desc` on the API — newest first)

## Workflow

1. Resolve organization context through `--org-id` or `S8_ORG_ID`.
2. Run `conversation_detail.sh --conversation-id <id>` for the conversation summary.
3. Run `conversation_messages.sh --conversation-id <id>` when the user asks for the message timeline.

## Guardrails

- Require an explicit conversation id before opening detail routes.
- Prefer `--order desc` when building agent context (recent messages first). With `asc`, the oldest page may include legacy `application/x-template` rows whose `createdAt` is null.
- Keep the output limited to the public developer API response fields.

## When not to use

- The task is customer-profile management rather than conversation or message retrieval.
- Required conversation id, keyword, org id, or time filter is missing for the requested operation.
- The task requires sending or modifying messages.

## Inputs

- `--org-id` or `S8_ORG_ID` (required).
- Conversation, customer, keyword, platform, inbox, pagination, and time-range flags supported by the referenced script.

## Outputs

- Conversation summaries, message timelines, or keyword-search matches from the Developer API.

## Failure handling

- Ask for missing required ids or filters before calling the API.
- Surface HTTP 400 or 404 errors and ask the user to correct input.
- If results are empty, report that plainly; do not fabricate evidence.

## Observability

- Record applied filters, cursor usage, script name, and HTTP status. Do not log full message content in traces.
