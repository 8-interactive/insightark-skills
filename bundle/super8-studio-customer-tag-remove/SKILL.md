---
name: super8-studio-customer-tag-remove
description: Operate on the Super 8 Studio Developer API to remove one or more tags from one organization-scoped customer.
when_to_use: When a user explicitly asks to remove tags from a specific customer in a specific organization context.
allowed-mcp: false
license: MIT
metadata:
  owner: platform
  version: "1.0.0"
  category: customer-api
  domain: super8-studio
---

# Skill: super8-studio-customer-tag-remove

This skill operates on the Super 8 Studio Developer API.

## Script

- `../_super8-studio-api-shared/scripts/customer_tag_remove.sh`

## CLI

- `--org-id <id>` (optional, falls back to `S8_ORG_ID`)
- `--customer-id <id>` (required)
- `--tag <tag>` (required, repeatable; supply at least one)

## Workflow

1. Resolve organization context through `--org-id` or `S8_ORG_ID`.
2. Require an explicit customer id and one or more explicit tags.
3. Run `customer_tag_remove.sh` and return the acceptance response from the public developer API.

## Guardrails

- Treat this as a write operation.
- Do not infer a customer id or tag list from ambiguous input.
- Return the acceptance result as-is instead of inventing a refreshed customer state.

## When not to use

- The task is conversation browsing or broadcast management rather than customer operations.
- Required customer id, filter, field value, tag, or message content is ambiguous.
- The requested field is outside the supported public customer schema.

## Inputs

- `--org-id` or `S8_ORG_ID` (required).
- Customer ids, search filters, supported profile fields, tags, or message content flags required by the referenced script.

## Outputs

- Customer search results, customer detail payloads, updated customer records, updated tag lists, or message-dispatch confirmations.

## Failure handling

- Do not call write APIs until customer id and intended changes are explicit.
- Surface HTTP 400 or 404 errors with the API message and stop.
- Never infer corrected PII values, tags, or outbound message content.

## Observability

- Record customer id, filter names, mutated field or tag names, content type, and HTTP status. Do not log PII values or full message bodies.
