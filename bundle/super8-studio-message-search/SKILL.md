---
name: super8-studio-message-search
description: Operate on the Super 8 Studio Developer API to search messages across conversations using supported filters.
when_to_use: When a user needs keyword-driven evidence, conversation-scoped search, or platform-filtered message lookup inside an organization.
allowed-mcp: false
license: MIT
metadata:
  owner: platform
  version: "1.0.0"
  category: conversation-api
  domain: super8-studio
---

# Skill: super8-studio-message-search

This skill operates on the Super 8 Studio Developer API.

## Script

- `../_super8-studio-api-shared/scripts/message_search.sh`

## CLI

Required:

- `--keyword <text>` (repeatable; multiple values are sent as an array)

Optional filters:

- `--org-id <id>` (falls back to `S8_ORG_ID`)
- `--conversation-id <id>` (omit for organization-wide search)
- `--platform <channel>` (`line`, `facebook`, `instagram`, `whatsapp`, `livechat`, ...)
- `--start-at <ISO 8601>` (when omitted with `--keyword`, the server applies a rolling 14-day default ending at the current time)
- `--end-at <ISO 8601>` (custom window upper bound; explicit ranges may span at most 90 days)
- `--sender-type <type>` (repeatable; omit to use server default `Customer`)
- `--sender-id <userObjectId>` (repeatable; narrows `_User` senders to specific org member ids; pair with `--sender-type _User`)
- `--limit <n>` (page size, default 20, maximum 100 on the API)
- `--skip <n>` (offset-style pagination, default 0)

## Sender defaults and overrides

- When `--sender-type` is omitted, the API searches **Customer messages only**, matching the Console message-search default intent.
- To include other sources, pass one or more `--sender-type` values:
  - `Customer`
  - `_User`
  - `AddOn`
  - `Organization`
  - `ForeignBot`
- To mirror Console behavior such as "Customer or a specific agent", pass both types and the agent ids:

```bash
message_search.sh \
  --keyword hi \
  --sender-type Customer \
  --sender-type _User \
  --sender-id lAVR5e42Lx
```

## Org-wide vs conversation-scoped search

- **Organization-wide**: omit `--conversation-id`. The API searches matching messages across all conversations in the organization (subject to `startAt` / `endAt`, `platform`, sender filters, and keyword filters).
- **Conversation-scoped**: pass `--conversation-id <id>`. The same keyword filter is applied only inside that conversation.

Both modes return full `DeveloperMessage` objects (including `data.content`), not message ids only. Use `super8-studio-conversation-detail` when you need surrounding timeline context before or after a hit.

## Workflow

1. Resolve organization context through `--org-id` or `S8_ORG_ID`.
2. Run `message_search.sh` with at least one `--keyword` and any supported filters.
3. Return the public search results and note when no evidence matches.

## Guardrails

- Stay read-only.
- Keyword search matches `data.content` on `text/plain` and `application/x-template` messages only; image, video, broadcast (`application/x-broadcast`), and other content types are not keyword-indexed.
- When the caller needs a wider window (up to 90 days), pass explicit `--start-at` / `--end-at`; ranges longer than 90 days are rejected by the API.
- For discovery by recent activity (not keyword), use `super8-studio-conversations` instead of message search.

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
