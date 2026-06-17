---
name: super8-studio-customer-detail
description: Operate on the Super 8 Studio Developer API to inspect one organization-scoped customer detail record.
when_to_use: When a user already has a customer id and wants the public developer-facing customer detail payload for that organization.
allowed-mcp: false
license: MIT
metadata:
  owner: platform
  version: "1.0.0"
  category: customer-api
  domain: super8-studio
---

# Skill: super8-studio-customer-detail

This skill operates on the Super 8 Studio Developer API.

## Script

- `../_super8-studio-api-shared/scripts/customer_detail.sh`

## Workflow

1. Resolve organization context through `--org-id` or `S8_ORG_ID`.
2. Require an explicit customer id and run `customer_detail.sh --customer-id <id>`.
3. Return only the public customer detail payload from the developer API response.

## Guardrails

- Require an explicit customer id before calling the detail route.
- Keep the output limited to the public developer customer schema.

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
