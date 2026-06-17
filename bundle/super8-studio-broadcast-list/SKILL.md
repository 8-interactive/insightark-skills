---
name: super8-studio-broadcast-list
description: Operate on the Super 8 Studio Developer API to list an organization's broadcast tasks newest first with forward-only cursor pagination.
when_to_use: When a user wants to browse recent broadcasts in one organization, optionally filtered by status, or to walk the full broadcast history forward via cursor.
allowed-mcp: false
license: MIT
metadata:
  owner: platform
  version: "1.0.0"
  category: broadcast-api
  domain: super8-studio
---

# Skill: super8-studio-broadcast-list

This skill operates on the Super 8 Studio Developer API.

## Script

- `../_super8-studio-api-shared/scripts/broadcast_list.sh`

## CLI

- `--org-id <id>` (optional, falls back to `S8_ORG_ID`)
- `--limit <int>` (optional; defaults to the API default; max 100)
- `--cursor <opaque>` (optional; cursor returned by a previous list response)
- `--status <comma-separated>` (optional; e.g. `working,done,scheduled`)

## Workflow

1. Resolve organization context through `--org-id` or `S8_ORG_ID`.
2. GET the developer broadcast list endpoint scoped to the resolved organization with the supplied pagination and status filter.
3. Return the developer API response as-is.

## Guardrails

- Read-only operation.
- Do not invent status values; only forward the user's explicit filter.
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
