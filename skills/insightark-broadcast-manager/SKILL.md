---
name: insightark-broadcast-manager
description: Investigate and operate on broadcast tasks through InsightArk MCP — session validation, org scoping, broadcast create (default preview for rich batches), get, and list.
when_to_use: When a user wants a single broadcast-oriented workflow that can validate MCP readiness, resolve organization scope, launch a broadcast, inspect one broadcast's progress, or browse recent broadcasts.
allowed-mcp: true
---

# Skill: insightark-broadcast-manager

**Prerequisite:** Read `skills/insightark-universal-workflow/SKILL.md` before operational work or domain references.

This skill uses the InsightArk MCP server. Authentication is managed by your host through MCP OAuth (Connect / Authenticate). Every org-scoped tool requires an `orgId` argument. Write operations need explicit user confirmation before calling.

## MCP Tools

- `auth_me` — validate session (no `orgId` required)
- `auth_organizations` — list manageable organizations (no `orgId` required)
- `broadcast_list` — browse recent broadcast tasks
- `broadcast_get` — get one broadcast's status and progress
- `broadcast_create` — create an async broadcast task
- `messaging_message_preview` — preview message batch before create (costs 2 credits)
- `media_upload_url` — upload local media for message payloads

## Workflow

1. Call `auth_me` or `auth_organizations` when session context is not yet trusted.
2. Resolve `orgId` before any org-scoped tool.
3. Choose one path:
   - **Create** — for rich / `application/x-template` payloads, hand construction to `insightark-messaging` and its `references/TEMPLATE_GUIDELINES.md` (do not copy schema here); optionally `media_upload_url`. Follow the universal **Rich Preview Gate** (`skills/insightark-universal-workflow/references/rich-preview-gate.md`): preview-required → disclose 2-credit cost → `messaging_message_preview` → approval → `broadcast_create`; text-only without quick replies → confirmation only; skip preview only when the user explicitly asks. When setting `scheduleAt`, follow `skills/insightark-universal-workflow/references/timezone-policy.md`.
   - **Get** — `broadcast_get`; compare `options.customerNum` to running `success` / `fail`
   - **List** — `broadcast_list`, optionally filtered by `status`
4. Return the MCP response as-is.

## Example requests

- `Launch a LINE broadcast in org org_demo_001 with text "Hello <%= name %>" to customers cus_123 and cus_456.`
- `Schedule a Facebook broadcast in org org_demo_001 for 2026-05-12T09:00:00+08:00 with image https://cdn.example.com/promo.jpg to customers cus_789.` (default encoding when the customer did not name a timezone; if they specify UTC or another offset, honor that instead)
- `Show status of broadcast 65f0c8a1b2c3d4e5f6a7b8c9 in org org_demo_001.`
- `List the last 20 broadcasts in org org_demo_001 with status working or scheduled.`

## Constrained parameters (situational)

Exact allowed strings come from the MCP tool schema.

- `broadcast_create.platform` — one platform per task (`line` / `facebook` / `instagram` / `whatsapp` per schema enum). Split multi-platform audiences into separate tasks.
- `broadcast_create.scheduleAt` — ISO 8601. Follow timezone-policy: unspecified wall-clock → Asia/Taipei (`+08:00`); customer-named timezone / `Z` / offset → honor it. Before create, confirm **customer intent**, **MCP input**, and that the system may **return/store** the equivalent UTC instant.
- `broadcast_list.status` — single token or comma-separated list (e.g. `working,done`). Allowed tokens are listed in the tool description; invalid tokens are rejected at runtime (no scalar `enum` on the param).
- `broadcast_create.messageTag` — useful for Facebook/Instagram when Meta’s 24h messaging window requires a tag. Schema lists allowed tag values. Do not invent server rejection for tags on other platforms unless the published schema/runtime already enforces it.
- `media_upload_url.purpose` × `contentType` — match purpose to allowed MIME types from the tool description (image purposes → image MIME; `file` → PDF).

## Guardrails

- Treat broadcast create as a write operation at scale; confirm inferred platform, recipients, or content.
- One platform per broadcast task; split multi-platform audiences.
- Do not default `scheduleAt` to `Z` or a bare datetime when the customer omitted a timezone; use `+08:00` per timezone-policy (agent policy — broadcast API may still accept bare datetimes).
- If authentication is missing, expired, revoked, or the host reports `401` / `403` / authentication-required, hand off to `insightark-session` for host OAuth recovery before retrying. Do not treat network/timeout/`5xx` failures as OAuth problems.
