---
name: super8-studio-customer-tag-remove
description: Operate on the SUPER 8 Studio Developer API to remove one or more tags from one organization-scoped customer.
when_to_use: When a user explicitly asks to remove tags from a specific customer in a specific organization context.
allowed-mcp: false
---

# Skill: super8-studio-customer-tag-remove

This skill operates on the SUPER 8 Studio Developer API.

## Script

- `node ../_super8-studio-api-shared/scripts/customer_tag_remove.js`

## CLI

- `--org-id <id>` (optional, falls back to `S8_ORG_ID`)
- `--customer-id <id>` (required)
- `--tag <tag>` (required, repeatable; supply at least one)

## Workflow

1. Resolve organization context through `--org-id` or `S8_ORG_ID`.
2. Require an explicit customer id and one or more explicit tags.
3. Run `customer_tag_remove.js` and return the acceptance response from the public developer API.

## Guardrails

- Treat this as a write operation.
- Do not infer a customer id or tag list from ambiguous input.
- Return the acceptance result as-is instead of inventing a refreshed customer state.