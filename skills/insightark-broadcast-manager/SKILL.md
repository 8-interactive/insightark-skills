---
name: insightark-broadcast-manager
description: Investigate and operate on broadcast tasks through InsightArk MCP — session validation, org scoping, broadcast create (default preview for rich batches), get, and list.
when_to_use: When a user wants a single broadcast-oriented workflow that can validate MCP readiness, resolve organization scope, launch a broadcast, inspect one broadcast's progress, or browse recent broadcasts.
allowed-mcp: true
---

# Skill: insightark-broadcast-manager

This skill uses the InsightArk MCP server. Authentication uses `_SessionToken`. Every org-scoped tool requires an `orgId` argument. Write operations need explicit user confirmation before calling.

## MCP Tools

- `auth.me` — validate session (no `orgId` required)
- `auth.organizations` — list manageable organizations (no `orgId` required)
- `broadcast.list` — browse recent broadcast tasks
- `broadcast.get` — get one broadcast's status and progress
- `broadcast.create` — create an async broadcast task
- `messaging.message.preview` — preview message batch before create (costs 2 credits)
- `media.uploadUrl` — upload local media for message payloads

## Workflow

1. Call `auth.me` or `auth.organizations` when session context is not yet trusted.
2. Resolve `orgId` before any org-scoped tool.
3. Choose one path:
   - **Create** — build payload, optionally `media.uploadUrl`, then `messaging.message.preview` → confirm → `broadcast.create` by default for rich / quickReply batches; skip preview only when the user explicitly asks
   - **Get** — `broadcast.get`; compare `options.customerNum` to running `success` / `fail`
   - **List** — `broadcast.list`, optionally filtered by `status`
4. Return the MCP response as-is.

## Example requests

- `Launch a LINE broadcast in org org_demo_001 with text "Hello <%= name %>" to customers cus_123 and cus_456.`
- `Schedule a Facebook broadcast in org org_demo_001 for 2026-05-12T09:00:00Z with image https://cdn.example.com/promo.jpg to customers cus_789.`
- `Show status of broadcast 65f0c8a1b2c3d4e5f6a7b8c9 in org org_demo_001.`
- `List the last 20 broadcasts in org org_demo_001 with status working or scheduled.`

## Guardrails

- Treat broadcast create as a write operation at scale; confirm inferred platform, recipients, or content.
- One platform per broadcast task; split multi-platform audiences.
