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
- `broadcast_audience_preview` — count a Console-supported dynamic audience (5 credits); sample is optional
- `crm_tag_list` — compare rough organization tag inventory counts
- `crm_customer_group_list`, `crm_customer_group_get`, `crm_customer_group_members_list` — inspect materialized group snapshots
- `broadcast_create` — create an async broadcast task
- `messaging_message_preview` — preview message batch before create (costs 2 credits)
- `media_upload_url` — upload local media for message payloads

## Workflow

1. Call `auth_me` or `auth_organizations` when session context is not yet trusted.
2. Resolve `orgId` before any org-scoped tool.
3. Choose one path:
   - **Tag sizing / create** — use `crm_tag_list` for rough comparison of tag inventory (`name`, `count`, `density`, `lastUsed`). Its `count` / `density` are not platform- or policy-filtered sendable audience totals. For a tag-targeted dynamic audience, always call `broadcast_audience_preview` before claiming the sendable count or calling `broadcast_create`; then present its policy-filtered count, confirm, and pass its top-level `previewRef` and matching top-level `messageTag` (if any) to `broadcast_create`. Supported dynamic conditions are tag include/exclude, gender, one customer group, all-bound, and inbox. Do not combine a group with another filter; do not use time/density tag clauses or Console-absent filters. For rich / `application/x-template` payloads, hand construction to `insightark-messaging` and its `references/TEMPLATE_GUIDELINES.md` (do not copy schema here); optionally `media_upload_url`. Follow the universal **Rich Preview Gate** (`skills/insightark-universal-workflow/references/rich-preview-gate.md`): preview-required → disclose 2-credit cost → `messaging_message_preview` → approval → `broadcast_create`; text-only without quick replies → confirmation only; skip preview only when the user explicitly asks. When customer time language becomes the schedule instant, apply `skills/insightark-universal-workflow/references/timezone-policy.md`.
   - **Tag sizing / create** — use `crm_tag_list` for rough comparison of tag inventory (`name`, `count`, `density`, `lastUsed`). Its `count` / `density` are not platform- or policy-filtered sendable audience totals. For a tag-targeted dynamic audience, always call `broadcast_audience_preview` before claiming the sendable count or calling `broadcast_create`; then present its policy-filtered count, confirm, and pass its top-level `previewRef` and matching top-level `messageTag` (if any) to `broadcast_create`. Supported dynamic conditions are tag include/exclude, gender, one customer group, all-bound, and inbox. Do not combine a group with another filter; do not use time/density tag clauses or Console-absent filters. For rich / `application/x-template` payloads, hand construction to `insightark-messaging` and its `references/TEMPLATE_GUIDELINES.md` (do not copy schema here); optionally `media_upload_url`. Follow the universal **Rich Preview Gate** (`skills/insightark-universal-workflow/references/rich-preview-gate.md`): preview-required → disclose 2-credit cost → `messaging_message_preview` → approval → `broadcast_create`; text-only without quick replies → confirmation only; skip preview only when the user explicitly asks. When customer time language becomes the schedule instant, apply `skills/insightark-universal-workflow/references/timezone-policy.md`.
   - **Get** — `broadcast_get`; use `phase`, `deliveryOutcome`, `attention`, and `failureDiagnostics` rather than treating raw `status: done` as delivery success.
   - `broadcast_create` returns only an asynchronous receipt; inspect a later terminal outcome through get or list.
   - **List** — `broadcast_list`, optionally filtered by `status`, `platform`, `createdFrom`, `createdTo`, terminal `deliveryOutcome`, or server-computable `attention: scheduled_overdue`.
4. Return the MCP response as-is. When reporting a call's actual credit cost, cite only its returned top-level `chargedCredits`; do not calculate it from before/after organization balances.

## Message envelope

For a plain-text message, use the canonical envelope:

`[{ contentType: "text/plain", data: { content: "..." } }]`

For rich templates or quick replies, use `insightark-messaging` and `references/TEMPLATE_GUIDELINES.md`; do not infer their nested fields from this text-only form.

## Status diagnosis

- **Scheduled** — if `attention: scheduled_overdue`, report that it has remained scheduled at least two minutes after `scheduleAt`; this is read-time evidence, not a claimed root cause.
- **Preparing / dispatching** — describe this as audience-resolution work. `dispatching` has no delivery-progress comparison; do not infer a send stall from unchanged counters.
- **Working** — first require `liveProgressAvailable: true`. When asked whether it is progressing, take a snapshot with `broadcast_get` (or a narrowly filtered `broadcast_list`), wait approximately 60 seconds, then read again. If `completed` increased, report both counts and `observedAt` values as evidence of progress. If it did not increase while both snapshots remain working, report `no_progress_observed` as an attention signal only; do not claim a cause. If the phase changed, evaluate the new phase or terminal outcome instead.
- **Terminal** — report `deliveryOutcome`: `delivered`, `done_with_failures`, `no_recipients`, or `delivery_incomplete`. For failures, report `failureDiagnostics.classificationAvailability`, allowlisted aggregate code/category/retryability when present, `unclassifiedFailedCount`, and `taskId` as the support reference. State when classification is unavailable or partial; never expose or infer recipient details, raw provider codes, or provider payloads. An allowlisted normalized code may be looked up in public provider documentation outside this skill.
- **Terminal failure action** — stop and ask for user direction. There is no public resend, draft, cancel, or export lifecycle tool. Do not automatically create a replacement broadcast; require fresh explicit confirmation before any new `broadcast_create`, and cite `taskId` for Super8 Console/support handoff when useful.

Golden reporting examples are maintained in `references/BROADCAST_STATUS_GOLDEN_CASES.md`.

## Example requests

- `Launch a LINE broadcast in org org_demo_001 with text "Hello <%= name %>" to customers cus_123 and cus_456.`
- `Schedule a Facebook broadcast in org org_demo_001 for 2026-05-12T09:00:00+08:00 with image https://cdn.example.com/promo.jpg to customers cus_789.` (default encoding when the customer did not name a timezone; if they specify UTC or another offset, honor that instead)
- `Show status of broadcast 65f0c8a1b2c3d4e5f6a7b8c9 in org org_demo_001.`
- `List the last 20 broadcasts in org org_demo_001 with status working or scheduled.`

## Constrained parameters (situational)

Exact allowed strings come from the MCP tool schema.

- `broadcast_create.platform` — one platform per task (`line` / `facebook` / `instagram` / `whatsapp` per schema enum). Split multi-platform audiences into separate tasks.
- `broadcast_create.scheduleAt` — future RFC 3339 schedule instant with uppercase `T` / `Z`, seconds, optional fractional seconds, and either `Z` or a colonized `+/-HH:MM` offset. Bare datetimes, date-only values, and basic offsets such as `+0800` are rejected. Follow timezone-policy: unspecified wall-clock → Asia/Taipei (`+08:00`); customer-named timezone / `Z` / offset → honor it. Before create, confirm **customer intent**, **MCP input**, and that the system may **return/store** the equivalent UTC instant.
  For a scheduled confirmation, explicitly show: local date/time, effective timezone, and resolved `scheduleAt` ISO instant. For example: `Send at 2026-07-23 09:00 Asia/Taipei (UTC+08:00); MCP scheduleAt: 2026-07-23T09:00:00+08:00.` The server may persist/return canonical UTC via `.toISOString()`: `2026-07-23T09:00:00+08:00` and `2026-07-23T01:00:00.000Z` are the same instant. This normalization does not change the customer's intended Taipei wall-clock time.
  For immediate delivery, confirm that it will send now and **omit** `scheduleAt`; never supply the current time as an immediate-send substitute. A supplied `scheduleAt` must be strictly future or the server rejects the request.
- `broadcast_list.status` — single token or comma-separated list (e.g. `working,done`). Allowed tokens are listed in the tool description; invalid tokens are rejected at runtime (no scalar `enum` on the param).
- `broadcast_create.messageTag` / `broadcast_audience_preview.messageTag` — Facebook/Instagram-only, top-level tag for a genuine qualifying update or event. Use no tag for ordinary messaging, including promotions; never invent a tag to bypass the 24-hour policy. When a user supplies truthful qualifying context, select only a schema-allowed tag, pass that one value to preview and create, present the preview’s policy-filtered count, then obtain normal write confirmation. Never put a tag inside an individual message; LINE, WhatsApp, and other non-Meta broadcasts reject `messageTag`.
- `media_upload_url.purpose` × `contentType` — match purpose to allowed MIME types from the tool description (image purposes → image MIME; `file` → PDF).

## Guardrails

- Treat broadcast create as a write operation at scale; confirm inferred platform, recipients, or content.
- One platform per broadcast task; split multi-platform audiences.
- Do not default `scheduleAt` to `Z` or a bare datetime when the customer omitted a timezone; use `+08:00` per timezone-policy. Omit `scheduleAt` for immediate sends.
- CustomerGroup counts and member pages are snapshots only. A query group's `updatedAt` is its mutable record timestamp, not proof of the exact materialization time. Always call `broadcast_audience_preview` for a group audience before confirmation or create.
- If authentication is missing, expired, revoked, or the host reports `401` / `403` / authentication-required, hand off to `insightark-session` for host OAuth recovery before retrying. Do not treat network/timeout/`5xx` failures as OAuth problems.
