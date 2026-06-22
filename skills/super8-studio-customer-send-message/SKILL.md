---
name: super8-studio-customer-send-message
description: Operate on the Super 8 Studio Developer API to send outbound text, image, or video messages to one organization-scoped customer.
when_to_use: When a user explicitly asks to send a message with explicit content to a specific customer in a specific organization context.
allowed-mcp: false
---

# Skill: super8-studio-customer-send-message

This skill operates on the Super 8 Studio Developer API.

## Script

- `../_super8-studio-api-shared/scripts/customer_send_message.sh`

## CLI

- `--org-id <id>` (optional, falls back to `S8_ORG_ID`)
- `--customer-id <id>` (required)
- `--text "<content>"` (repeatable; appends a text/plain message)
- `--image <url>` (repeatable; appends an application/x-image message)
- `--video <url>` (repeatable; appends an application/x-video message)
- `--reply-token <token>` (optional; LINE only)
- `--inbox-to-done` (boolean flag; defaults to off)
- `--message-tag <CONFIRMED_EVENT_UPDATE|POST_PURCHASE_UPDATE|ACCOUNT_UPDATE|HUMAN_AGENT>` (Facebook / Instagram; attached to every message in the batch). The value must be exactly one of these four canonical English enum strings; localized labels (e.g. `活動更新`) are rejected by the API with `400 error/invalid-message-tag`.
- `--wa-template-id <id>` (WhatsApp; attached to every message in the batch). The value must be a WhatsApp template id registered for the customer's organization, not a human-readable / localized template name. Unresolvable ids are rejected by the API with `400 error/invalid-wa-template-id`.

The dispatched batch preserves the order in which `--text`, `--image`, and `--video` flags appear on the command line.

## Workflow

1. Resolve organization context through `--org-id` or `S8_ORG_ID`.
2. Require an explicit customer id and at least one message flag.
3. Build the batch in command-line order, attach per-batch `messageTag` / `waTemplateId` if provided.
4. POST the batch to the customer message send endpoint.
5. Return the developer API response as-is, including `messages[*].messageId`, `messages[*].contentType`, and `deliveryMode`.

## Guardrails

- Treat this as a write operation that can trigger real platform messages and incur cost.
- Do not infer a customer id from ambiguous user input.
- Do not invent message text or media URLs from ambiguous user input.
- If any required field had to be inferred from non-explicit user phrasing, confirm with the user before dispatching.
- Do not infer `--message-tag` or `--wa-template-id` from localized labels, UI copy, or natural-language descriptions. The API enforces the canonical English enum / id form; localized strings are rejected with `400 error/invalid-message-tag` or `400 error/invalid-wa-template-id`. If the user gave a localized label such as `活動更新`, confirm which of the four English enum values they intended before dispatching.
- Return the API response as-is instead of re-rendering or summarizing the dispatched messages.
