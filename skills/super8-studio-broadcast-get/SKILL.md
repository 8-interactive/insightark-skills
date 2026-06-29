---
name: super8-studio-broadcast-get
description: Operate on the Super 8 Studio Developer API to fetch the current status, progress counts, and option summary of one broadcast task.
when_to_use: When a user wants to poll one broadcast's status, success / fail counts, or schedule timestamps by id within an explicit organization context.
allowed-mcp: false
---

# Skill: super8-studio-broadcast-get

This skill operates on the Super 8 Studio Developer API.

## Script

- `node ../_super8-studio-api-shared/scripts/broadcast_get.js`

## CLI

- `--org-id <id>` (optional, falls back to `S8_ORG_ID`)
- `--broadcast-id <id>` (required)

## Workflow

1. Resolve organization context through `--org-id` or `S8_ORG_ID`.
2. Require an explicit broadcast id.
3. GET the developer broadcast detail endpoint scoped to the resolved organization.
4. Return the developer API response as-is.

## Response notes

- `options.customerNum` is an integer audience snapshot taken at broadcast creation time. It equals the resolved-customer count for explicit-id selection (recipients.customerIds) and the filter-match count for where-filter selection (recipients.where). For tasks created before this field was populated the value may be null; treat null as "unknown" rather than zero.

## Guardrails

- Read-only operation; do not invoke any other broadcast endpoint as a side effect.
- Do not infer a broadcast id from ambiguous user input.
- Return the API response as-is.
