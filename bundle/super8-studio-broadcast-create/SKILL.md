---
name: super8-studio-broadcast-create
description: Operate on the Super 8 Studio Developer API to create an asynchronous broadcast that dispatches a message batch to many customers selected by either an explicit id list or a customer-search filter.
when_to_use: When a user explicitly asks to launch a broadcast with explicit recipient selection and explicit message content.
allowed-mcp: false
license: MIT
metadata:
  owner: platform
  version: "1.0.0"
  category: broadcast-api
  domain: super8-studio
---

# Skill: super8-studio-broadcast-create

This skill operates on the Super 8 Studio Developer API.

## Script

- `../_super8-studio-api-shared/scripts/broadcast_create.sh`

## CLI

- `--org-id <id>` (optional, falls back to `S8_ORG_ID`)
- `--platform <line|facebook|instagram|whatsapp>` (required; one broadcast task targets exactly one platform)
- `--customer-id <id>` (repeatable; supplies an explicit recipient list, capped at 10000)
  - OR
- `--where-file <path>` (JSON file containing a customer-search filter shape)
- `--text "<content>"` (repeatable; appends a text/plain message)
- `--image <url>` (repeatable; appends an application/x-image message)
- `--video <url>` (repeatable; appends an application/x-video message)
- `--schedule-at <ISO 8601>` (optional; defers dispatch until that time when in the future)
- `--inbox-to-done` (boolean flag; defaults to off)
- `--message-tag <CONFIRMED_EVENT_UPDATE|POST_PURCHASE_UPDATE|ACCOUNT_UPDATE|HUMAN_AGENT>` (Facebook / Instagram; applied to every message). The value must be exactly one of these four canonical English enum strings; localized labels (e.g. `活動更新`) are rejected by the API with `400 error/invalid-message-tag`.
- `--wa-template-id <id>` (WhatsApp; applied to every message). The value must be a WhatsApp template id registered for the target organization, not a human-readable / localized template name. Unresolvable ids are rejected by the API with `400 error/invalid-wa-template-id`.

`--customer-id` and `--where-file` are mutually exclusive. Messages are dispatched in command-line order. Every `--customer-id` in the list must belong to `--platform`; mixed-platform recipient lists are rejected by the API.

## Workflow

1. Resolve organization context through `--org-id` or `S8_ORG_ID`.
2. Require an explicit `--platform` value (one of `line`, `facebook`, `instagram`, `whatsapp`).
3. Require an explicit recipient input (customer ids or a filter file) and at least one message flag.
4. Build the recipients selector and the message batch.
5. POST the broadcast creation request to the developer broadcast endpoint.
6. Return the developer API response as-is, including `taskId` and `status`.

## Guardrails

- Treat this as a write operation that triggers real platform messages to many recipients at scale and can incur substantial platform cost.
- A single broadcast task targets exactly one platform. If the requested audience spans multiple platforms, split the dispatch into one broadcast per platform before calling.
- Do not infer the platform from ambiguous user input; confirm with the user when the recipient list could plausibly span more than one channel.
- Do not infer recipient ids from ambiguous user input.
- Do not invent message content from ambiguous user input.
- Do not synthesize a `where` filter from vague language; if the user has not provided an explicit filter shape, confirm with them before dispatching.
- If any required field had to be inferred, confirm with the user before dispatching.
- Do not infer `--message-tag` or `--wa-template-id` from localized labels, UI copy, or natural-language descriptions. The API enforces the canonical English enum / id form; localized strings are rejected with `400 error/invalid-message-tag` or `400 error/invalid-wa-template-id`. If the user gave a localized label such as `活動更新`, confirm which of the four English enum values they intended before dispatching.
- Return the API response as-is instead of re-rendering or summarizing the dispatched batch.

## When not to use

- The task belongs to one-customer messaging or read-only customer/conversation investigation.
- Required org, platform, recipients, task id, or message content is missing.
- A requested audience spans multiple platforms; split per platform first.

## Inputs

- `--org-id` or `S8_ORG_ID` (required).
- Broadcast task id for lookup, or platform, recipient source, content flags, schedule, and platform policy fields for creation.

## Outputs

- Broadcast creation task id and initial status, broadcast progress details, or paginated broadcast lists.

## Failure handling

- Ask for explicit required fields before creation; never infer platform, recipients, or content.
- Surface HTTP 400 or 404 errors and do not retry with guessed corrections.
- Treat create as high-impact because it can send real platform messages at scale.

## Observability

- Record platform, task id, recipient source, applied filters, and HTTP status. Do not log full recipient lists or message bodies.
