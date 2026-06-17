---
name: super8-studio-ma-automation
description: Create, publish, pause, inspect, and manually trigger Marketing Automation procedures on the Super 8 Studio Developer API (developer session, org owner/admin). Always validate payload before create. Do not preset or guess any customer business field; ask until all required inputs are explicit. Canonical graph/message shapes follow marketing-automation-front-end (submodule), not ad-hoc JSON.
when_to_use: When a user needs to manage MA journeys or enqueue a manual API trigger for a customer via the Developer API.
allowed-mcp: false
---

# Skill: super8-studio-ma-automation

## Scripts (in `../_super8-studio-api-shared/scripts/`)

| Script | Purpose |
|--------|---------|
| `ma_procedure_preflight.sh` | **Requires `--confirmation-file`.** Local gate before `validate`/`create`: OpenAPI root keys (`orgId`, `templateType`, `name`, `enabled`, `platform`, **`startTime`/`endTime`**, `limits`, `oos`, graph), **`limits.message` + `limits.per_customer` required** (`per_customer` may be **`onceByDay`**), **`oos.enabled === true` ⇒ hour/minute/duration required**, Meta `fbTag`, placeholder scan, `matchTopLevel` deep-equal. Run only **after** customer sign-off. |
| `ma_procedure_validate.sh` | `POST /developer/v1/automation/procedures/validate` — same body as create; **HTTP 2xx** and prints JSON; **exits 0 only if `data.valid === true`**. |
| `ma_procedure_create.sh` | `POST /developer/v1/automation/procedures` — body from `--json-file`. Server runs the same checks as validate; invalid payload returns **400**. |
| `ma_procedure_start.sh` | `POST .../procedures/{id}/start` — publish draft. |
| `ma_procedure_pause.sh` | `PATCH .../procedures/{id}/status` — `--action pause` or `resume`. |
| `ma_procedure_status.sh` | `GET .../procedures/{id}` — status summary and push count. |
| `ma_procedure_trigger.sh` | `POST .../procedures/{id}/trigger` — `--customer-id` required; optional `--type`. **Only when `procedure.status` is `progress` (進行中)** enqueue; drafts / paused / before start window / ended / disabled → **HTTP 400** `error/ma-trigger-not-allowed` and **`data.reasonStatus`** (`editing` \| `pausing` \| `terminated` \| `scheduled` \| `done`, or **`unknown`** if settings missing). Call **`ma_procedure_status.sh`** first to verify. |

### Locate journeys by customer-provided name

Customers usually refer to **`name`**, not **`procedureId`**. For query status / publish(start) / pause / resume / trigger when only the **旅程名稱** is known, use skill **`super8-studio-ma-procedure-locate`** and **`ma_procedure_list.sh`** to resolve **`procedureId`**, confirm with the customer, then invoke the scripts in this skill that accept `--procedure-id`.

### Confirmation file (`--confirmation-file`)

Separate JSON created **after** the customer signs off on the final field table. It ties the agent to an exact approved top-level snapshot so the payload cannot drift silently before API calls.

| Field | Rule |
|-------|------|
| `customerExplicitApproval` | Must be JSON `true` (customer explicitly approved the values about to be submitted). |
| `nodesEdgesCustomerApproved` | Must be `true` (customer confirmed business meaning of `nodes`/`edges`, not only layout). |
| `matchTopLevel` | Object whose key set must match the script rules: always `enabled`, `endTime`, `limits`, `name`, **`oos`** (must **deep-equal** payload `oos`; use `null` only if customer explicitly chose JSON null), `orgId`, `platform`, `startTime`, `templateType`. Also include `fbTag` when `platform` is `facebook`, `instagram`, or `messenger`, **or** when the payload root contains `fbTag`. Each value must be **deep-equal** to the same field on the payload root (`jq` `==`). **`nodes` / `edges`** remain gated by `nodesEdgesCustomerApproved` but are not duplicated in `matchTopLevel`; any change after sign-off requires renewed approval. |

Example (values are illustrative; every value must match the payload after customer approval):

```json
{
  "customerExplicitApproval": true,
  "nodesEdgesCustomerApproved": true,
  "matchTopLevel": {
    "orgId": "ORG_ID_FROM_CUSTOMER",
    "templateType": "all_or_other_value_confirmed_with_customer",
    "name": "JOURNEY_NAME_FROM_CUSTOMER",
    "enabled": true,
    "platform": "line",
    "startTime": "2026-06-01T09:00:00+08:00",
    "endTime": "2026-12-31T23:59:59+08:00",
    "limits": { "message": 1000, "per_customer": 1 },
    "oos": { "enabled": false, "hour": 22, "minute": 0, "duration": 43200 }
  }
}
```

## Hard rules: no presetting business fields

- **Before the customer states each item explicitly**, do not fill, guess, or substitute “usual defaults” for any **business- or behavior-related** field (e.g. do not silent-pick arbitrary root `templateType` keys, invented schedule bounds, `limits`, platform, trigger rules, message copy, `fbTag`, `oos`).
- **Procedure root `templateType`:** required for Developer API persistence and Studio parity; **it is not** “選一張後台現成旅程範本”. **從空白畫布建立**：與 MA Studio 一致時通常為 **`all`** — still require the customer to **explicitly confirm** this value (`all` vs another documented key). Separate from **message node** `messages[].templateType` (e.g. `card`, `imagemap`).
- **Ask and complete the checklist first**, then assemble JSON, then **preflight**, then `validate`, then `create`. If anything is missing, stay in Q&A: list **what is still missing** and ask with minimal follow-ups.
- Only after the customer has confirmed the overall behavior may you add **non-semantic structure placeholders** (e.g. node `id`, canvas `position`, edge `source` / `target`), and label them as wiring-only in your explanation; **do not** use structure to skip unanswered business choices.
- `S8_ORG_ID` in the environment only selects **which org the API call targets**; the **body `orgId` and journey content** still require customer confirmation (often aligned with a manageable org for the token, but if the target org is unstated, ask).
- Before calling `validate` or `create`, show the final payload in a compact field table and get explicit customer approval for every business field.

### Note: `fbTag` server default

If `fbTag` is omitted, the API layer may still apply a default of `NO_TAG`. You must still confirm the **intended** tagging policy in conversation; do not skip the question because the field is optional in the schema.

### Note: “dormancy / sleep” wording

If the customer says “dormancy” or “sleep,” clarify whether they mean **OOS / off-hours (`oos`)**, **per-step delay (`waitTime` or similar)**, or another rule before mapping to fields.

## Pre-create checklist (customer must confirm all rows)

**Do not** run `ma_procedure_validate.sh` or `ma_procedure_create.sh` until `ma_procedure_preflight.sh` succeeds **with** `--confirmation-file`, and **every** row below is explicitly agreed with the customer:

| Area | Customer must provide |
|------|------------------------|
| Organization | Target org (`orgId`, and it must be an org the current developer session can manage). |
| Journey name | `name`. |
| Procedure **`templateType` (payload root)** | Non-empty **procedure-level** string for Studio/editor compatibility (**not** a gallery “existing journey”). **从零 / 空白畫布**： usually **`all`**, aligned with MA Studio defaults; obtain **literal customer confirmation**. Do **not** conflate with **message** `messages[].templateType`. |
| Platform (發送平台) | `platform` — **必填**（如 line、facebook、instagram、whatsapp、livechat）；由客戶指定。 |
| Schedule (旅程期間) | `startTime`, `endTime` — **必填**；具體日期時間與時區（ISO 8601，例如 `2026-06-01T09:00:00+08:00`）；不得用「預設區間」代替客戶表述。 |
| Quotas (訊息則數 / 旅程次數) | `limits.message`（總發送則數上限）與 `limits.per_customer`（每位顧客可進入旅程次數）**皆必填**；皆須為非負整數，**或** `per_customer` 使用字串 **`onceByDay`**（與 Studio：每人每日最多觸發一次）— 須由客戶明確選擇。 |
| Messenger tag | For Meta channels, confirm `fbTag`; **do not** assume `NO_TAG` without asking. |
| Off-hours / OOS (休眠) | **預設關閉**：除非客戶明確要開啟，否則使用 `oos: { "enabled": false, ... }` 或客戶明確選擇的 `null`（僅在客戶說明後）；**若 `enabled: true`**，必須與客戶確認並填寫 `hour`、`minute`、`duration`（秒，與後台 OOS 計算一致）。 |
| Trigger | Full trigger type and rules (e.g. keywords: each rule, match mode `keyword` / `in` / … and `value` list; tags: tag conditions; API: confirm API-driven trigger). |
| Content and steps | Copy or template shape per message node; multi-step journeys need step-by-step customer confirmation. |
| Message step `skipOOS` | Add **only** if the customer explicitly wants that message node to bypass OOS; otherwise **omit** the field (never copy from samples). |
| Switches | `enabled` and whether to publish immediately after create (publish only after explicit customer approval via `start`). |
| Final sign-off | Agent must show final payload table and receive explicit customer approval before API calls. |

Phrases like “same as before” or “you decide” are **not** literal values. Keep asking until every item has a **literal, actionable** answer.

## Mandatory agent workflow

1. Run a **gap check** against this checklist; any gap → **questions only, no API calls**.
2. After the customer fills gaps, write the JSON file (values only from the customer plus meaningless id/coordinates for graph wiring).
3. Show a compact final field table and get explicit customer sign-off.
4. Run **`ma_procedure_preflight.sh --json-file PATH --confirmation-file PATH`**; if it fails, ask follow-up questions and revise only with customer agreement (update `matchTopLevel` after any approved change).
5. Ensure credentials are available (`~/.super8-studio.env`, `./.super8-studio.env`, or process env). Scripts load them automatically. Use `S8_ORG_ID` or the customer-selected org aligned with body `orgId`.
6. Run **`ma_procedure_validate.sh`**; if `data.valid === false`, parse **`data.errors`** (array of `{ path, code, message }`) and **逐條用客戶語言說明缺哪個欄位或哪個規則未滿足**，請客戶補齊後再改 JSON；**不得**為了過驗證擅自改業務意涵。
7. After a successful validate, run **`ma_procedure_create.sh`**; if HTTP **400**，讀取錯誤 envelope：`success: false`，結構化錯誤通常在 **`data.errors`**（與 validate 相同形狀時可同樣對應 `path`）；將 **`path` + `message`** 轉述給客戶要求補齊。Cap at **three** validate-fix rounds, each change explainable to the customer.
8. **Do not** copy names, times, keywords, or copy from sample JSON onto a real customer “to save time.”

**讀取校驗結果（給 agent / 腳本）**

- `POST .../validate`：HTTP **200**，`success: true`，校驗結果在 **`data.valid`** 與 **`data.errors`**。例：`jq -r '.data.errors[]? | "\(.path // "(root)"): \(.message)"' response.json`
- `POST .../procedures`（create）：校驗失敗為 HTTP **400**，`success: false`；多數情況 **`data.errors`** 與上式相同，可同樣用 `path` 對應欄位向客戶追問。

Validate route: handler returns HTTP **200** with `data.valid`; auth or session failures are non-200.

## Prerequisite knowledge (summary)

- **Graph**: `nodes[]` + `edges[]` are the editor graph; `transformToProcedure` derives runtime `trigger` / `start` / `steps` from edges. Missing `message.data` (and similar) can break the console editor.
- **Message**: `text/plain` needs `data.content`; `application/x-template` needs `data.templateType` and related fields.

## Example JSON (shape only)

The block below illustrates **structure only**. **Do not** copy `orgId`, root `templateType`, schedule, `limits`, triggers, or body copy before the customer confirms each field — for scratch builds the root `templateType` is typically **`all`**, explicitly approved.

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
- Preflight requires `--confirmation-file`; if you change the payload after customer sign-off, you must refresh `matchTopLevel` (and get renewed approval when business meaning changes).
- Do not paste internal Mongo procedure documents; use only the public Developer request shape.
