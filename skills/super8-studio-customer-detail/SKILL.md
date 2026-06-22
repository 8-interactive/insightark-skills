---
name: super8-studio-customer-detail
description: Operate on the Super 8 Studio Developer API to inspect one organization-scoped customer detail record.
when_to_use: When a user already has a customer id and wants the public developer-facing customer detail payload for that organization.
allowed-mcp: false
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