---
name: super8-studio-customer-update
description: Operate on the Super 8 Studio Developer API to update supported public customer profile fields for one organization-scoped customer.
when_to_use: When a user explicitly asks to change supported customer profile fields such as display name, email, language, or other documented public customer attributes.
allowed-mcp: false
---

# Skill: super8-studio-customer-update

This skill operates on the Super 8 Studio Developer API.

## Script

- `node ../_super8-studio-api-shared/scripts/customer_update.js`

## CLI

- `--org-id <id>` (optional, falls back to `S8_ORG_ID`)
- `--customer-id <id>` (required)
- `--display-name <value>` (optional)
- `--cell-phone <value>` (optional)
- `--email <value>` (optional)
- `--birthday <ISO 8601>` (optional)
- `--gender <value>` (optional)
- `--language <value>` (optional)
- `--nation <value>` (optional)
- `--location <value>` (optional)
- `--address <value>` (optional)
- `--about <value>` (optional)

Supply at least one field flag. Each flag mutates that single public field; only the fields explicitly passed are sent in the update body.

## Workflow

1. Resolve organization context through `--org-id` or `S8_ORG_ID`.
2. Require an explicit customer id and explicit field values before calling the update route.
3. Pass only supported public fields such as `displayName`, `cellPhone`, `email`, `birthday`, `gender`, `language`, `nation`, `location`, `address`, `about`, and `customField1-3`.
4. Return the updated public customer detail payload from the developer API response.

## Guardrails

- Treat this as a write operation.
- Do not use internal mutation operators or undocumented customer fields.
- Do not perform the write unless the target customer id and updated values are explicit.