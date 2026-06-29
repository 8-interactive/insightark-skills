---
name: super8-studio-broadcast-list
description: Operate on the SUPER 8 Studio Developer API to list an organization's broadcast tasks newest first with forward-only cursor pagination.
when_to_use: When a user wants to browse recent broadcasts in one organization, optionally filtered by status, or to walk the full broadcast history forward via cursor.
allowed-mcp: false
---

# Skill: super8-studio-broadcast-list

This skill operates on the SUPER 8 Studio Developer API.

## Script

- `node ../_super8-studio-api-shared/scripts/broadcast_list.js`

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
