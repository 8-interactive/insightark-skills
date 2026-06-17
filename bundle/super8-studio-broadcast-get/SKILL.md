---
name: super8-studio-broadcast-get
description: Operate on the Super 8 Studio Developer API to fetch the current status, progress counts, and option summary of one broadcast task.
when_to_use: When a user wants to poll one broadcast's status, success / fail counts, or schedule timestamps by id within an explicit organization context.
allowed-mcp: false
license: MIT
metadata:
  owner: platform
  version: "1.0.0"
  category: broadcast-api
  domain: super8-studio
---

# Skill: super8-studio-broadcast-get

This skill operates on the Super 8 Studio Developer API.

## Script

- `../_super8-studio-api-shared/scripts/broadcast_get.sh`

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
