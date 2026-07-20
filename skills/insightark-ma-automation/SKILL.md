---
name: insightark-ma-automation
description: Create draft Marketing Automation procedures, then publish/start, pause, inspect status, and manually trigger via InsightArk MCP (developer session, org owner/admin). Always validate payload before create. Do not preset or guess any customer business field; ask until all required inputs are explicit. Canonical graph/message shapes follow marketing-automation-front-end (submodule), not ad-hoc JSON. Create alone does not publish.
when_to_use: When a user needs to manage MA journeys or enqueue a manual API trigger for a customer via InsightArk MCP.
allowed-mcp: true
---

# Skill: insightark-ma-automation

This skill uses the InsightArk MCP server. Authentication is managed by your host through MCP OAuth (Connect / Authenticate). Every org-scoped tool requires an `orgId` argument. Write operations need explicit user confirmation before calling.

## MCP Tools

- `ma_procedure_list` — list marketing automation procedures (requires `orgId`; optional `name`, `skip`, `limit`)
- `ma_procedure_get` — get procedure **status summary** only (requires `orgId`, `procedureId`); does **not** return `editor.nodes` / `editor.edges`
- `ma_procedure_validate` — validate a journey definition without persisting (requires `orgId`, `payload`)
- `ma_procedure_create` — create a **draft** procedure (requires `orgId`, `payload`); does **not** publish
- `ma_procedure_start` — **publish/start** a draft procedure (requires `orgId`, `procedureId`)
- `ma_procedure_pause` — pause or resume a procedure (requires `orgId`, `procedureId`; optional `action`: `pause` | `resume`)
- `ma_procedure_trigger` — manually trigger a procedure for a customer (requires `orgId`, `procedureId`, `customerId`)

There is currently **no** MCP tool to fetch a full Studio graph, update an existing procedure, or clone one. Treat this skill as **create-from-fixture / create-from-customer-input**, not retrieve→modify→reuse of existing Studio journeys.

### Locate journeys by customer-provided name

Customers usually refer to **`name`**, not **`procedureId`**. For query status / publish(start) / pause / resume / trigger when only the **旅程名稱** is known, resolve `procedureId` via `ma_procedure_list` (optionally filtering by `name`), confirm the chosen procedure with the user, then invoke the id-scoped tools above.

## Hard rules: no presetting business fields

- **Before the customer states each item explicitly**, do not fill, guess, or substitute "usual defaults" for any **business- or behavior-related** field (e.g. do not silent-pick arbitrary root `templateType` keys, invented schedule bounds, `limits`, platform, trigger rules, message copy, `fbTag`, `oos`).
- **Procedure root `templateType`:** required for InsightArk MCP persistence and Studio parity; **it is not** "選一張後台現成旅程範本". **從空白畫布建立**：與 MA Studio 一致時通常為 **`all`** — still require the customer to **explicitly confirm** this value (`all` vs another documented key). Separate from **message node** `messages[].templateType` (e.g. `card`, `imagemap`).
- **Ask and complete the checklist first**, then assemble JSON, then `ma_procedure_validate`, then `ma_procedure_create`. If anything is missing, stay in Q&A: list **what is still missing** and ask with minimal follow-ups.
- Only after the customer has confirmed the overall behavior may you add **non-semantic structure placeholders** (e.g. node `id`, canvas `position`, edge `source` / `target`), and label them as wiring-only in your explanation; **do not** use structure to skip unanswered business choices.
- Body `orgId` and journey content still require customer confirmation even when org context is known from session.
- Before calling `validate` or `create`, show the final payload in a compact field table and get explicit customer approval for every business field.

### Note: `fbTag` server default

If `fbTag` is omitted, the API layer may still apply a default of `NO_TAG`. You must still confirm the **intended** tagging policy in conversation; do not skip the question because the field is optional in the schema.

### Note: "dormancy / sleep" wording

If the customer says "dormancy" or "sleep," clarify whether they mean **OOS / off-hours (`oos`)**, **per-step delay (`waitTime` or similar)**, or another rule before mapping to fields.

## Pre-create checklist (customer must confirm all rows)

**Do not** call `ma_procedure_validate` or `ma_procedure_create` until **every** row below is explicitly agreed with the customer:

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
| Switches | `enabled` and whether to publish immediately after create (publish only after explicit customer approval via `ma_procedure_start`). |
| Final sign-off | Show final payload table and receive explicit customer approval before API calls. |

Phrases like "same as before" or "you decide" are **not** literal values. Keep asking until every item has a **literal, actionable** answer.

## Mandatory agent workflow

1. Run a **gap check** against this checklist; any gap → **questions only, no MCP calls**.
2. After the customer fills gaps, assemble the JSON payload:
   - Values only from the customer, plus wiring-only ids/positions.
   - **If the journey needs template card button branching (or tag trigger + button branch):** **clone** `references/fixtures/ma-tag-trigger-click-branch-skeleton.json` first, then replace customer fields. Do **not** invent a condition DSL.
3. Show a compact final field table and get explicit customer sign-off.
4. Call `ma_procedure_validate` with `orgId` and `payload`; if `valid === false`, parse `errors` (array of `{ path, code, message }`) and **逐條用客戶語言說明缺哪個欄位或哪個規則未滿足**，請客戶補齊後再改 JSON. See **Validate error remediation** below for graph/condition codes.
5. After successful validate, confirm with the user, then call `ma_procedure_create` with `orgId` and `payload`; if the tool returns a payload-invalid error, read `data.errors` and relay `path` + `message` to the customer. Cap at **three** validate-fix rounds, each change explainable to the customer.
6. **Do not** copy names, times, keywords, or copy from sample JSON onto a real customer "to save time."

**Trigger guardrail:** call `ma_procedure_get` first to verify `status` is `progress` before `ma_procedure_trigger`. Drafts, paused, before start window, ended, or disabled procedures return HTTP 400 `error/ma-trigger-not-allowed`.

## Prerequisite knowledge (summary)

- **Graph**: `nodes[]` + `edges[]` are the editor graph; server `transformToProcedure` derives runtime `trigger` / `start` / `steps` from edges. Missing `message.data` (and similar) can break the console editor.
- **Message**: `text/plain` needs `data.content`. For `application/x-template` or other rich LINE payloads, hand construction to `insightark-messaging` and its `references/TEMPLATE_GUIDELINES.md` rather than duplicating schema here.
- **Button click branches (Studio only):** use a `group` (`data.type: "click"`) plus **one `condition` node per branch** (`click` or `n-click`). Each condition MUST have **exactly one** outgoing edge. Named `click` conditions list `data.buttons[].id` as `` `${messages[].template}_elements.${elementIndex}.buttons.${buttonIndex}` ``. You MUST set a stable client-supplied `messages[].template` on the source card **before** wiring those ids (server-generated template ids cannot be predicted). Eligible buttons exclude phone, location, and non-http(s) URL buttons. `n-click` has **no** `buttons`. `clickType: "any"` does not need named button ids / `message.template` membership.
- **Forbidden:** `condition.data.event`, `branches`, `sourceMessageNodeId`, or one condition with multiple `sourceHandle` outgoing edges (skill-invented DSL). Validate will reject these.

## Structural fixture (clone for button branches)

Canonical wiring: [`references/fixtures/ma-tag-trigger-click-branch-skeleton.json`](references/fixtures/ma-tag-trigger-click-branch-skeleton.json) — LINE **tag trigger** + card + `group` + named `click` / `n-click` conditions.

**Structure only may be kept as-is** (node/edge topology, `clickType: "button"`, `timeType: "minute"`, `messages[].template` wiring id `tplCard001`, button id strings).

### Clone MUST replace (fail-until-replaced)

Every `<REQUIRED_FROM_CUSTOMER…>` value MUST be replaced with a customer-confirmed literal before `ma_procedure_validate`. Unreplaced placeholders fail validate (placeholder policy). At minimum replace:

| Path | Why |
|------|-----|
| `orgId`, `name`, root `templateType`, `platform` | Identity / channel |
| `enabled` | Whether journey is enabled when later published |
| `startTime`, `endTime` | Schedule |
| `limits.*` | Quotas |
| `oos.*` | Off-hours policy (do not keep fixture OOS numbers) |
| trigger `event` / `match` / `tags[]` | Tag trigger rule (add vs remove; all vs any; which tags) |
| message `name`, `waitTime`, card title/subtitle/imageUrl | Content / delay |
| button `title` / `data` | Customer-facing labels and postback payloads |
| button `tags` | Optional; empty `[]` on the skeleton means "no auto-tags" wiring only — replace if the customer wants button-applied tags |
| group `time` | Timeout seconds for n-click |
| group `allowMulti` | Whether multiple clicks are allowed |
| follow-up message text | Branch content |

Do **not** tell the customer a journey is published after `ma_procedure_create` alone — call `ma_procedure_start` only after explicit approval.

Linear journeys without button branches may use the minimal shape below.

## Example JSON (linear shape only)

The block below illustrates **structure only** for journeys **without** button branches. **Do not** copy business fields before the customer confirms each field. For button branches, clone the fixture above instead.

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

## Validate error remediation

Group related codes; fix **wiring**, not copy, unless the code is clearly about content.

### Shape / type

| Code | What to do |
|------|------------|
| `error/ma-payload-unsupported-condition-shape` | Remove `event` / `branches` / `sourceMessageNodeId`; clone Studio fixture |
| `error/ma-payload-unsupported-condition-type` | Use allowlisted `data.type` (`click` / `n-click` / keyword / sticker variants) |

### Group + timing

| Code | What to do |
|------|------------|
| `error/ma-payload-condition-group-missing` | Point `groupId` at an existing `group` node |
| `error/ma-payload-condition-group-type` | That group must have `data.type: "click"` |
| `error/ma-payload-condition-group-click-type` | Set `clickType` to `any` or `button` |
| `error/ma-payload-condition-group-time-type` | Set `timeType` to `day` \| `hour` \| `minute` |
| `error/ma-payload-condition-group-time` | Set finite non-negative `time` (customer-confirmed timeout) |

### Source + edges

| Code | What to do |
|------|------------|
| `error/ma-payload-condition-source-missing` | Set non-empty `condition.data.source` and `group.data.source` to a message node |
| `error/ma-payload-condition-source-mismatch` | Set `condition.data.source` equal to `group.data.source` |
| `error/ma-payload-condition-source-edge` | Exactly one incoming edge from that source message |
| `error/ma-payload-condition-edge-cardinality` | Exactly one outgoing edge per click/n-click condition |

### Sibling cardinality

| Code | What to do |
|------|------------|
| `error/ma-payload-condition-nclick-cardinality` | Exactly one `n-click` per click group |
| `error/ma-payload-condition-any-click-cardinality` | `clickType: any` → exactly one `click` |
| `error/ma-payload-condition-named-click-cardinality` | `clickType: button` → at least one named `click` |

### Buttons / template

| Code | What to do |
|------|------------|
| `error/ma-payload-missing-message-template` | Set stable `messages[].template`, then recompute button ids |
| `error/ma-payload-condition-buttons-empty` | Named click needs ≥1 button id |
| `error/ma-payload-condition-button-not-eligible` | Id must exist on source card (Studio eligibility) |
| `error/ma-payload-condition-button-duplicate` | Each button id owned by one sibling click only |

### Post-transform

| Code | What to do |
|------|------------|
| `error/ma-runtime-condition-not-executable` | Fix group/`groupId`/source/timing so transform fills condition `data` |
| `error/ma-runtime-condition-topology` | One edge per condition; end-target → `end`, else `children: [target]` |

Do **not** try to fix these by only editing message copy.

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

- Org-scoped MCP tools require organization owner/admin; **business fields in the body must come from explicit customer input**, not silent presets.
- If you change the payload after customer sign-off, get renewed approval when business meaning changes.
- Do not paste internal Mongo procedure documents; use the MCP / shared MA procedure payload shape only.
- Never invent `template_button_click` / `branches` condition nodes; never fan out multiple `sourceHandle` edges from one condition.
- If authentication is missing, expired, revoked, or the host reports `401` / `403` / authentication-required, hand off to `insightark-session` for host OAuth recovery before retrying. Do not treat network/timeout/`5xx` failures as OAuth problems.
