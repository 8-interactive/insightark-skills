---
name: insightark-ma-automation
description: Create, publish, pause, inspect, and manually trigger Marketing Automation procedures via InsightArk MCP (developer session, org owner/admin). Always validate payload before create. Do not preset or guess any customer business field; ask until all required inputs are explicit. Canonical graph/message shapes follow marketing-automation-front-end (submodule), not ad-hoc JSON.
when_to_use: When a user needs to manage MA journeys or enqueue a manual API trigger for a customer via the Developer API.
allowed-mcp: true
---

# Skill: insightark-ma-automation

This skill uses the InsightArk MCP server. Authentication uses `_SessionToken`. Every org-scoped tool requires an `orgId` argument. Write operations need explicit user confirmation before calling.

## MCP Tools

- `ma.procedure.list` — list marketing automation procedures (requires `orgId`; optional `name`, `skip`, `limit`)
- `ma.procedure.get` — get procedure status summary (requires `orgId`, `procedureId`)
- `ma.procedure.validate` — validate a journey definition without persisting (requires `orgId`, `payload`)
- `ma.procedure.create` — create and publish a procedure (requires `orgId`, `payload`)
- `ma.procedure.start` — publish a draft procedure (requires `orgId`, `procedureId`)
- `ma.procedure.pause` — pause or resume a procedure (requires `orgId`, `procedureId`; optional `action`: `pause` | `resume`)
- `ma.procedure.trigger` — manually trigger a procedure for a customer (requires `orgId`, `procedureId`, `customerId`)

### Locate journeys by customer-provided name

Customers usually refer to **`name`**, not **`procedureId`**. For query status / publish(start) / pause / resume / trigger when only the **旅程名稱** is known, resolve `procedureId` via `ma.procedure.list` (optionally filtering by `name`), confirm the chosen procedure with the user, then invoke the id-scoped tools above.

## Hard rules: no presetting business fields

- **Before the customer states each item explicitly**, do not fill, guess, or substitute "usual defaults" for any **business- or behavior-related** field (e.g. do not silent-pick arbitrary root `templateType` keys, invented schedule bounds, `limits`, platform, trigger rules, message copy, `fbTag`, `oos`).
- **Procedure root `templateType`:** required for Developer API persistence and Studio parity; **it is not** "選一張後台現成旅程範本". **從空白畫布建立**：與 MA Studio 一致時通常為 **`all`** — still require the customer to **explicitly confirm** this value (`all` vs another documented key). Separate from **message node** `messages[].templateType` (e.g. `card`, `imagemap`).
- **Ask and complete the checklist first**, then assemble JSON, then `ma.procedure.validate`, then `ma.procedure.create`. If anything is missing, stay in Q&A: list **what is still missing** and ask with minimal follow-ups.
- Only after the customer has confirmed the overall behavior may you add **non-semantic structure placeholders** (e.g. node `id`, canvas `position`, edge `source` / `target`), and label them as wiring-only in your explanation; **do not** use structure to skip unanswered business choices.
- Body `orgId` and journey content still require customer confirmation even when org context is known from session.
- Before calling `validate` or `create`, show the final payload in a compact field table and get explicit customer approval for every business field.

### Note: `fbTag` server default

If `fbTag` is omitted, the API layer may still apply a default of `NO_TAG`. You must still confirm the **intended** tagging policy in conversation; do not skip the question because the field is optional in the schema.

### Note: "dormancy / sleep" wording

If the customer says "dormancy" or "sleep," clarify whether they mean **OOS / off-hours (`oos`)**, **per-step delay (`waitTime` or similar)**, or another rule before mapping to fields.

## Pre-create checklist (customer must confirm all rows)

**Do not** call `ma.procedure.validate` or `ma.procedure.create` until **every** row below is explicitly agreed with the customer:

| Area | Customer must provide |
|------|------------------------|
| Organization | Target `orgId` (must be manageable by the current session). |
| Journey name | `name`. |
| Procedure **`templateType` (payload root)** | Non-empty **procedure-level** string for Studio/editor compatibility. **从零 / 空白畫布**： usually **`all`**, aligned with MA Studio defaults; obtain **literal customer confirmation**. |
| Platform (發送平台) | `platform` — **必填**（如 line、facebook、instagram、whatsapp、livechat）；由客戶指定。 |
| Schedule (旅程期間) | `startTime`, `endTime` — **必填**；具體日期時間與時區（ISO 8601）；不得用「預設區間」代替客戶表述。 |
| Quotas (訊息則數 / 旅程次數) | `limits.message` 與 `limits.per_customer` **皆必填**；皆須為非負整數，**或** `per_customer` 使用字串 **`onceByDay`** — 須由客戶明確選擇。 |
| Messenger tag | For Meta channels, confirm `fbTag`; **do not** assume `NO_TAG` without asking. |
| Off-hours / OOS (休眠) | **預設關閉**：除非客戶明確要開啟，否則使用 `oos: { "enabled": false, ... }`；**若 `enabled: true`**，必須與客戶確認並填寫 `hour`、`minute`、`duration`（秒）。 |
| Trigger | Full trigger type and rules. |
| Content and steps | Copy or template shape per message node; multi-step journeys need step-by-step customer confirmation. |
| Message step `skipOOS` | Add **only** if the customer explicitly wants that message node to bypass OOS; otherwise **omit** the field. |
| Switches | `enabled` and whether to publish immediately after create (publish only after explicit customer approval via `ma.procedure.start`). |
| Final sign-off | Show final payload table and receive explicit customer approval before API calls. |

Phrases like "same as before" or "you decide" are **not** literal values. Keep asking until every item has a **literal, actionable** answer.

## Mandatory agent workflow

1. Run a **gap check** against this checklist; any gap → **questions only, no MCP calls**.
2. After the customer fills gaps, write the JSON payload (values only from the customer plus meaningless id/coordinates for graph wiring).
3. Show a compact final field table and get explicit customer sign-off.
4. Call `ma.procedure.validate` with `orgId` and `payload`; if `valid === false`, parse `errors` (array of `{ path, code, message }`) and **逐條用客戶語言說明缺哪個欄位或哪個規則未滿足**，請客戶補齊後再改 JSON.
5. After successful validate, confirm with the user, then call `ma.procedure.create` with `orgId` and `payload`; if HTTP **400**, read `data.errors` and relay `path` + `message` to the customer. Cap at **three** validate-fix rounds, each change explainable to the customer.
6. **Do not** copy names, times, keywords, or copy from sample JSON onto a real customer "to save time."

**Trigger guardrail:** call `ma.procedure.get` first to verify `status` is `progress` before `ma.procedure.trigger`. Drafts, paused, before start window, ended, or disabled procedures return HTTP 400 `error/ma-trigger-not-allowed`.

## Prerequisite knowledge (summary)

- **Graph**: `nodes[]` + `edges[]` are the editor graph; `transformToProcedure` derives runtime `trigger` / `start` / `steps` from edges. Missing `message.data` (and similar) can break the console editor.
- **Message**: `text/plain` needs `data.content`; `application/x-template` needs `data.templateType` and related fields.

## Example JSON (shape only)

The block below illustrates **structure only**. **Do not** copy `orgId`, root `templateType`, schedule, `limits`, triggers, or body copy before the customer confirms each field.

```json
{
  "orgId": "<REQUIRED_FROM_CUSTOMER>",
  "templateType": "<REQUIRED_FROM_CUSTOMER root field; scratch builds often explicitly confirm all>",
  "name": "<REQUIRED_FROM_CUSTOMER>",
  "enabled": "<REQUIRED_FROM_CUSTOMER_BOOLEAN>",
  "platform": "<REQUIRED_FROM_CUSTOMER>",
  "startTime": "<REQUIRED_FROM_CUSTOMER_ISO8601_WITH_TIMEZONE>",
  "endTime": "<REQUIRED_FROM_CUSTOMER_ISO8601_WITH_TIMEZONE>",
  "limits": { "message": "<REQUIRED_FROM_CUSTOMER_NONNEG_INT>", "per_customer": "<REQUIRED_FROM_CUSTOMER_NONNEG_INT>" },
  "fbTag": "<REQUIRED_FROM_CUSTOMER_OR_EXPLICIT_NULL_POLICY>",
  "oos": "<REQUIRED_FROM_CUSTOMER_OBJECT_OR_DISABLED_POLICY>",
  "nodes": [
    { "id": "s1", "type": "start", "position": { "x": 0, "y": 0 } },
    {
      "id": "t1",
      "type": "trigger",
      "data": "<REQUIRED_FROM_CUSTOMER_TRIGGER_RULES>",
      "position": { "x": 120, "y": 0 }
    },
    {
      "id": "m1",
      "type": "message",
      "data": {
        "name": "<REQUIRED_FROM_CUSTOMER_STEP_NAME>",
        "waitTime": "<REQUIRED_FROM_CUSTOMER_OR_ZERO_CONFIRMED>",
        "messages": [
          {
            "index": 0,
            "contentType": "<REQUIRED_FROM_CUSTOMER_CONTENT_TYPE>",
            "data": "<REQUIRED_FROM_CUSTOMER_MESSAGE_PAYLOAD>"
          }
        ]
      },
      "position": { "x": 240, "y": 0 }
    },
    { "id": "e1", "type": "end", "position": { "x": 360, "y": 0 } }
  ],
  "edges": [
    { "source": "s1", "target": "t1" },
    { "source": "t1", "target": "m1" },
    { "source": "m1", "target": "e1" }
  ]
}
```

## Field reference (create / validate body)

| Field | Role |
|--------|------|
| `orgId` | Target org (customer-specified; must match session authority). |
| `templateType` (root) | Procedure-level Studio field (customer-confirmed); **scratch / blank canvas** usually **`all`**. Separate from **`messages[].templateType`**. |
| `type` | Procedure type; often derived server-side — ask if the customer or template requires an explicit value. |
| `name` | Display name from the customer. |
| `enabled` | Whether the customer wants it enabled. |
| `platform` | Channel confirmed by the customer. |
| `startTime` / `endTime` | Schedule bounds confirmed by the customer. |
| `limits` | Total / per-customer caps; when set, **`message` and `per_customer` must be non-negative integers**. |
| `fbTag` | Meta-related tag policy (customer-confirmed). |
| `oos` | Off-hours / OOS settings confirmed by the customer. |
| `nodes` / `edges` | Graph shape; business content from the customer; ids/positions may be wiring-only. |

## Guardrails

- Routes require organization owner/admin; **business fields in the body must come from explicit customer input**, not silent presets.
- If you change the payload after customer sign-off, get renewed approval when business meaning changes.
- Do not paste internal Mongo procedure documents; use only the public Developer request shape.
