---
name: insightark-universal-workflow
description: Shared InsightArk policy for customer-facing guidance, rich-message preview, and write lifecycle. Non-operational prerequisite for every InsightArk workflow skill.
when_to_use: Always load this policy before any InsightArk operational workflow (messaging, broadcast, MA, CRM writes, or investigation that may lead to writes).
allowed-mcp: true
role: policy
---

# Skill: insightark-universal-workflow

This is a **policy** skill, not an operational workflow. It does not own a write tool list. Every InsightArk workflow skill requires the agent to read this file before tools or domain references.

## Mandatory core (always)

1. **Customer language first** — Explain unresolved business decisions in plain product language: what the setting controls, the supported choices, and the observable delivery effect. Do not lead with internal IDs, schema names, or raw payload fields.
2. **Disclose technical detail on request** — If the customer asks for API/schema/ID detail, or already speaks in those terms, provide the non-sensitive mapping. Do not refuse solely because a term is “internal.”
3. **Confirm before writes** — Every create/update/send/start/pause/trigger needs explicit confirmation of the intended business outcome before the write tool call.
4. **Org scope** — All org-scoped tools require `orgId` (except `auth_me` / `auth_organizations`).
5. **Credits / 429** — Before calling a credit-consuming tool, state the known cost when documented. On `429` / credit exhaustion, do not retry loops that burn more credits; use `credits_usage` or stop and report.

## Conditional references

- **Rich / quick-reply content** → read `references/rich-preview-gate.md` before send, broadcast create, or MA validate/create for that step.
- **Any write path** → read `references/write-lifecycle.md` for confirmation and invalidation rules.
- **Scheduling write fields** (`broadcast_create.scheduleAt`, MA `startTime` / `endTime`) → read `references/timezone-policy.md` before assembling or confirming those values.

## What this skill does not do

- It does not replace domain skills (`insightark-messaging`, `insightark-ma-automation`, …).
- It does not invent MCP tools or upload contracts beyond `media_upload_url` + presigned PUT.
