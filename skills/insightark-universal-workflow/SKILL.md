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

1. **Customer language first** — Explain unresolved business decisions in plain product language: what the setting controls, the supported choices, and the observable delivery effect. Do not lead with internal IDs, schema names, or raw payload fields. For Studio features listed in `references/console-terminology.md`, use Console product labels (and accepted short forms) as the default head terms — for example 群發訊息, 自動旅程, 目標客戶群, 群組對話 — not engineering calques.
2. **Disclose technical detail on request** — If the customer asks for API/schema/ID detail, or already speaks in those terms, provide the non-sensitive mapping. Do not refuse solely because a term is “internal.”
3. **Confirm before writes** — Every create/update/send/start/pause/trigger needs explicit confirmation of the intended business outcome before the write tool call. Confirmation summaries that name Studio features MUST use Console labels from the terminology reference.
4. **Org scope** — All org-scoped tools require `orgId` (except `auth_me` / `auth_organizations`).
5. **Credits / 429** — Before calling a credit-consuming tool, state the documented estimate when useful. After every call, report its actual cost only from that call's returned top-level `chargedCredits`; never infer it from `credits_usage` balance differences, especially across concurrent calls. On `429` / credit exhaustion, do not retry loops that burn more credits; use `credits_usage` only to inspect remaining balance or stop and report. Do not conflate InsightArk MCP credits with Console AI 點數 or messaging quota.

## Conditional references

- **Console product names (zh-TW)** → read `references/console-terminology.md` before capability lists or customer-facing feature naming.
- **Rich / quick-reply content** → read `references/rich-preview-gate.md` before send, broadcast create, or MA validate/create for that step.
- **Any write path** → read `references/write-lifecycle.md` for confirmation and invalidation rules.
- **Instant-valued MCP inputs** → when customer-provided temporal language will be encoded as a specific instant or an interval boundary parsed as an instant, read `references/timezone-policy.md` before assembling or confirming the value.

## Synonym routing

Map customer synonyms to the correct MCP workflows, then continue in Console labels. Do not refuse solely because the customer used a non-Console word. Intentional customer-utterance examples:

<!-- terminology-allow:user-synonym -->
User input: 幫我建立廣播
<!-- /terminology-allow:user-synonym -->

→ route to `insightark-broadcast-manager` / `broadcast_*`; reply using 群發訊息 / 群發.

<!-- terminology-allow:user-synonym -->
User input: 查一下行銷自動化進度
<!-- /terminology-allow:user-synonym -->

→ route to `insightark-ma-automation` / `ma_*`; reply using 自動旅程.

## What this skill does not do

- It does not replace domain skills (`insightark-messaging`, `insightark-ma-automation`, …).
- It does not invent MCP tools or upload contracts beyond `media_upload_url` + presigned PUT.
