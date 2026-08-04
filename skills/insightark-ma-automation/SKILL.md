---
name: insightark-ma-automation
description: Create draft Marketing Automation procedures, then publish, pause, inspect status, and manually trigger via InsightArk MCP (developer session, org owner/admin). Always validate payload before create. Do not preset or guess any customer business field; ask until all required inputs are explicit. Canonical graph/message shapes follow marketing-automation-front-end (submodule), not ad-hoc JSON. Create alone does not publish.
when_to_use: When a user needs to manage MA journeys or enqueue a manual API trigger for a customer via InsightArk MCP.
allowed-mcp: true
---

# Skill: insightark-ma-automation

**Customer language:** This workflow operates Console **自動旅程** (internal: MA / marketing automation). Prefer 自動旅程 in customer-facing speech; MCP tool ids remain `ma_*`. Synonym routing for customer utterances lives under `insightark-universal-workflow` → `## Synonym routing`.

**Prerequisite:** Read `skills/insightark-universal-workflow/SKILL.md` before operational work or domain references.

This skill uses the InsightArk MCP server. Authentication is managed by your host through MCP OAuth (Connect / Authenticate). Every org-scoped tool requires an `orgId` argument. Write operations need explicit user confirmation before calling.

## MCP Tools

- `ma_template_list` — list agent-ready MA templates for an organization (requires `orgId`; optional `intent`, `platform`, `includeUnavailable`)
- `ma_template_get` — retrieve one available agent-ready template metadata + skeleton (requires `orgId`, `templateId`); **runtime source of truth** for catalog-backed creation
- `ma_procedure_list` — list marketing automation procedures (requires `orgId`; optional `name`, `skip`, `limit`)
- `ma_procedure_get` — get procedure **status summary** only (requires `orgId`, `procedureId`); does **not** return `editor.nodes` / `editor.edges`
- `ma_procedure_validate` — validate a journey definition without persisting (requires `orgId`, `payload`)
- `ma_procedure_create` — create a **draft** procedure (requires `orgId`, `payload`); does **not** publish
- `ma_procedure_publish` — **publish** a draft (leaves editing; requires `orgId`, `procedureId`). May become `progress`, `scheduled`, or `pausing`. Does **not** wait for `startTime`.
- `ma_procedure_pause` — pause or resume a procedure (requires `orgId`, `procedureId`; optional `action`: `pause` | `resume`)
- `ma_procedure_trigger` — manually trigger a procedure for a customer (requires `orgId`, `procedureId`, `customerId`)

### Procedure lifecycle (create vs publish vs time)

Status after create/publish is **derived** from `enabled`, `pausing`, `editing`, and the `startTime`/`endTime` window (same as Studio).

| Step | Tool / event | Meaning |
|------|----------------|---------|
| Draft | `ma_procedure_create` | Saved with `editing`; status `editing`; **not** accepting triggers |
| Publish | `ma_procedure_publish` | Leaves editing (Studio publish). Typical statuses: `progress`, `scheduled` (before `startTime`), or `pausing` (e.g. active-journey quota). Also possible: `terminated` if `enabled` is false; `done` if already past `endTime` |
| Schedule window | wall clock | After publish, when now ≥ `startTime` (and before `endTime`, not paused/disabled), status is `progress` — **no second publish** |
| Pause / resume | `ma_procedure_pause` | Only tool that toggles pause |

There is currently **no** MCP tool to fetch a full existing Studio graph, update an existing procedure, or clone one from an already-created journey. Catalog-backed authoring uses `ma_template_list` → `ma_template_get`. Packaged files under `references/fixtures/` are documentation / golden / drift copies only — **do not** clone catalog fixtures as the runtime source of truth (blank-canvas recipes below may use packaged skeletons as structural references).

### Catalog template discovery (required for catalog-backed creation)

For **every** catalog template (including capability-neutral LINE archetypes), resolve the confirmed `orgId`, then:

1. Call `ma_template_list` (default = available only). Use `includeUnavailable: true` only when explaining upgrade/conditional options.
2. Select an **available** entry; disclose its `templateId` + `version` to the customer.
3. Call `ma_template_get` for that id; replace every `requiredInputs` / `<REQUIRED_FROM_CUSTOMER…>` value.
4. Show the final business-field summary, get approval, `ma_procedure_validate`, then confirm again before `ma_procedure_create` (draft). Publish only via `ma_procedure_publish` after separate approval.

**Blank canvas:** use when the customer explicitly chooses blank-canvas authoring, **or** when discovery shows no agent-ready catalog template that covers the required trigger/action/judgment combination. In the catalog-gap case, state the gap in customer language, get acknowledgment, then proceed blank-canvas with the normal checklist → validate → create-draft → optional publish flow.

**Do not** infer GA4 / EC / sticker / channel entitlement from the user description, a static fixture, a configured GA4 domain alone, or Console template names. Relay discovery unavailableReasons in customer language (feature_not_enabled includes featureKey such as ma_sticker).

**Namespaces (never conflate):**

| Id | Meaning |
|----|---------|
| Catalog `templateId` | Server catalog entry only (e.g. `line-tag-follow-up`) |
| Payload root `templateType` | Studio procedure wiring. Catalog-backed: already set on the `ma_template_get` skeleton from `defaultRootTemplateType` — **consume it; do not ask the customer**. Blank canvas: set `authoringSource: "blank-canvas"` and omit → server defaults to `all`. |
| `messages[].template` / message `templateType` | Message wiring ids / card types |

Never copy catalog `templateId` or `consoleKey` into root `templateType`. Never ask the customer to name root `templateType` unless they request API/schema detail.

### Locate journeys by customer-provided name

Customers usually refer to **`name`**, not **`procedureId`**. For query status / publish / pause / resume / trigger when only the **旅程名稱** is known, resolve `procedureId` via `ma_procedure_list` (optionally filtering by `name`), confirm the chosen procedure with the user, then invoke the id-scoped tools above.

## Hard rules: no presetting business fields

- **Before the customer states each item explicitly**, do not fill, guess, or substitute "usual defaults" for any **business- or behavior-related** field (e.g. do not silent-pick invented schedule bounds, `limits`, platform, trigger rules, message copy, `fbTag`, `oos`).
- **Procedure root `templateType`:** wiring only. Catalog-backed journeys keep the concrete value from `ma_template_get` (materialized from catalog `defaultRootTemplateType`) and SHOULD send `authoringSource: "catalog"` (or omit the marker while keeping the concrete type). Blank-canvas journeys MUST set `authoringSource: "blank-canvas"` when omitting root `templateType` (server applies `all`). **Do not** ask the customer to choose this field in normal flows; disclose it only if they request API/schema detail. Separate from **message node** `messages[].templateType` (e.g. `card`, `imagemap`).
- **Ask and complete the checklist first**, then assemble JSON, then apply the Rich Preview Gate for any rich/quick-reply steps, then `ma_procedure_validate`, then `ma_procedure_create`. If anything is missing, stay in Q&A: list **what is still missing** and ask with minimal follow-ups.
- Only after the customer has confirmed the overall behavior may you add **non-semantic structure placeholders** (e.g. node `id`, canvas `position`, edge `source` / `target`), and label them as wiring-only in your explanation; **do not** use structure to skip unanswered business choices.
- **Node / end ids MUST NOT contain `_`.** Use Console-style alphanumeric ids (e.g. `s1`, `t1`, `m1`, `e1`, or 10-char ids like `I9xZ0RZwne`). Analytics units are `${procedureId}_${stepId}`; underscored node ids break detail analytics. Button field ids such as `` `${template}_elements.0.buttons.0` `` are exempt (Studio contract). If a payload still uses `_` in node ids, validate/create remaps them server-side — prefer authoring safe ids yourself.
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
| Platform (發送平台) | `platform` — **必填**（如 line、facebook、instagram、whatsapp、livechat）；由客戶指定。 |
| Schedule (旅程期間) | `startTime`, `endTime` — **必填**；ISO 8601 **含時區**。`startTime` must be **now or later** (do not use a past clock such as “today 00:00” if that instant has already passed). 客戶時間語言成為旅程邊界 instant 時，依 `skills/insightark-universal-workflow/references/timezone-policy.md`：未指定時區 → Asia/Taipei（`+08:00`）；客戶有指定時區／`Z`／offset → 照客戶。**日期-only**（如「7/1～7/31」）不得自動補起訖時分 — 必須先問並確認邊界（例如台北時間 `07/01 00:00:00+08:00` 至 `07/31 23:59:59+08:00`）後才能 validate/create。不得用「預設區間」臆測客戶未給的日期或時分。確認表須含 **客戶意圖** 與 **MCP 輸入**（並可註明系統可能保存的等價 UTC）。 |
| Quotas (訊息則數 / 旅程次數) | `limits.message` 與 `limits.per_customer` **皆必填**；皆須為非負整數，**或** `per_customer` 使用字串 **`onceByDay`** — 須由客戶明確選擇。 Explain what each limit controls before asking. **Do not** describe numeric `0` as unlimited (`per_customer: 0` is a hard stop). Unlimited is not defined by this skill. |
| Messenger tag | For Meta channels, confirm `fbTag`; **do not** assume `NO_TAG` without asking. |
| Off-hours / OOS (休眠) | **預設關閉**：除非客戶明確要開啟，否則使用 `oos: { "enabled": false, ... }`；**若 `enabled: true`**，必須與客戶確認並填寫 `hour`、`minute`、`duration`（秒）。 |
| Trigger | Full trigger type and rules. |
| Content and steps | Copy or template shape per message node; multi-step journeys need step-by-step customer confirmation. **Fixed clock schedules** (e.g. daily HH:MM): confirmation MUST disclose the **next fire** relative to now (if today’s slot already passed → next calendar occurrence, usually tomorrow). Prefer relative short windows when the goal is near-term verification. |
| Message step `skipOOS` | Add **only** if the customer explicitly wants that message node to bypass OOS; otherwise **omit** the field. |
| Switches | `enabled` and whether to publish immediately after create (publish only after explicit customer approval via `ma_procedure_publish`). |
| Final sign-off | Show final payload table and receive explicit customer approval before API calls. |

Phrases like "same as before" or "you decide" are **not** literal values. Keep asking until every item has a **literal, actionable** answer.

## Mandatory agent workflow

1. Confirm `orgId`. For catalog-backed creation: `ma_template_list` → pick available → `ma_template_get` (never clone packaged fixtures as runtime source). Blank canvas may skip discovery.
2. Run a **gap check** against this checklist (plus any `requiredInputs` from `ma_template_get`); any gap → **questions only, no write MCP calls**.
3. After the customer fills gaps, assemble the JSON payload from the retrieved skeleton (or blank-canvas assembly):
   - Values only from the customer, plus wiring-only ids/positions.
   - Keep catalog-materialized root `templateType` as returned; for blank canvas, set `authoringSource: "blank-canvas"` and omit (or use `all`).
   - Preserve catalog `templateId`/`version` in your explanation for drift diagnosis.
   - For customer-derived `startTime` / `endTime` instants, follow `skills/insightark-universal-workflow/references/timezone-policy.md` (default Asia/Taipei when timezone omitted; never invent date-only clock bounds).
4. Show a compact final field table and get explicit customer sign-off. For schedule fields include **customer intent** and **MCP input** (and note equivalent UTC storage when helpful).
5. For any preview-required message step (non-`text/plain` or quick replies), follow `skills/insightark-universal-workflow/references/rich-preview-gate.md` (disclose 2-credit cost, preview + journey timing, wait for approval). Text-only steps without quick replies need confirmation only.
6. Call `ma_procedure_validate` with `orgId` and `payload`; if `valid === false`, parse `errors` (array of `{ path, code, message, featureKey? }`) and **逐條用客戶語言說明**. See **Validate error remediation** below.
7. After successful validate, confirm with the user, then call `ma_procedure_create` with `orgId` and `payload` (**draft only**). Cap at **three** validate-fix rounds.
8. Publish only with explicit approval via `ma_procedure_publish`.
9. After successful publish, **always** call `ma_procedure_get` before telling the customer the journey is live. Explain `status` (derived from enabled / pausing / editing / time window):
   - `progress` — live and accepting triggers in window
   - `scheduled` — published; waiting for `startTime` (no extra publish when time arrives)
   - `pausing` — published but paused (possible active-journey quota); explain and **ask** before `ma_procedure_pause action=resume`
   - `terminated` — `enabled` is false; not live
   - `done` — past `endTime`; not live
   - `editing` — still a draft (publish did not leave editing); not live
   - other — do not claim the journey is live
   Never auto-resume without confirmation.

**Trigger guardrail:** call `ma_procedure_get` first to verify `status` is `progress` before `ma_procedure_trigger`. Drafts, paused, before start window, ended, or disabled procedures return HTTP 400 `error/ma-trigger-not-allowed`.

## Prerequisite knowledge (summary)

- **Graph**: `nodes[]` + `edges[]` are the editor graph; server `transformToProcedure` derives runtime `trigger` / `start` / `steps` from edges. Missing `message.data` (and similar) can break the console editor.
- **Message**: `text/plain` needs `data.content`. For `application/x-template` or other rich LINE payloads, hand construction to `insightark-messaging` and its `references/TEMPLATE_GUIDELINES.md` rather than duplicating schema here.
- **Button click branches (Studio only):** use a `group` (`data.type: "click"`) plus **one `condition` node per branch** (`click` or `n-click`). Each condition MUST have **exactly one** outgoing edge. Named `click` conditions list `data.buttons[].id` as `` `${messages[].template}_elements.${elementIndex}.buttons.${buttonIndex}` ``. You MUST set a stable client-supplied `messages[].template` on the source card **before** wiring those ids (server-generated template ids cannot be predicted). Eligible buttons exclude phone, location, and non-http(s) URL buttons. `n-click` has **no** `buttons`. `clickType: "any"` does not need named button ids / `message.template` membership.
- **Forbidden:** `condition.data.event`, `branches`, `sourceMessageNodeId`, or one condition with multiple `sourceHandle` outgoing edges (skill-invented DSL). Validate will reject these.

## Structural fixtures (docs / drift only)

Packaged copies under [`references/fixtures/`](references/fixtures/) mirror server catalog skeletons for documentation and CI drift checks:

| Catalog `templateId` | Fixture file |
|----------------------|--------------|
| `line-linear-message` | `line-linear-message.json` |
| `line-join-welcome` | `line-join-welcome.json` |
| `line-tag-follow-up` | `line-tag-follow-up.json` |
| `line-tag-click-branch` | `ma-tag-trigger-click-branch-skeleton.json` |
| _(blank-canvas)_ keyword branch | `ma-tag-keyword-branch-skeleton.json` |

**Runtime catalog:** always `ma_template_get`. Do not treat catalog fixtures as live clone sources. The keyword-branch fixture is blank-canvas-only (not a catalog archetype).

**Structure only may be kept as-is** after retrieval (node/edge topology, Studio discriminators, stable wiring ids such as `tplCard001`). Recompute derived button ids if message `template` or nested structure changes.

### Retrieved skeleton MUST replace (fail-until-replaced)

Every `<REQUIRED_FROM_CUSTOMER…>` value MUST be replaced with a customer-confirmed literal before `ma_procedure_validate`. Unreplaced placeholders fail validate. At minimum replace:

| Path | Why |
|------|-----|
| `orgId`, `name`, `platform` | Identity / channel |
| root `templateType` | Wiring — already set from catalog get, or blank-canvas `all`; **not** a customer checklist item |
| `enabled` | Whether journey is enabled when later published |
| `startTime`, `endTime` | Schedule |
| `limits.*` | Quotas |
| `oos.*` | Off-hours policy |
| trigger rules / tags | Tag triggers: `match` (`any`\|`all`) + `tags` only — never a tag `event` |
| message copy, waits, URLs, buttons | Content / behavior |
| group `timeout.value` + `timeout.unit` (`minute`\|`hour`\|`day`), allowMulti | **Click groups only** — collect value and unit; **never** calculate or author `time` / `timeType` seconds for click |
| keyword group `time` + `timeType` | **Keyword groups only** — Studio seconds + unit; see blank-canvas recipes (not click `timeout`) |

Do **not** tell the customer a journey is published after `ma_procedure_create` alone — call `ma_procedure_publish` only after explicit approval.

## Example JSON (linear shape only)

The block below illustrates **structure only** for blank-canvas journeys **without** button branches. Prefer `ma_template_get` for catalog archetypes. **Do not** copy business fields before the customer confirms each field.

```json
{
  "authoringSource": "blank-canvas",
  "orgId": "<REQUIRED_FROM_CUSTOMER>",
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

## Template discovery error remediation

| Situation | What to do |
|-----------|------------|
| `error/ma-template-not-available` without reasons | Unknown or non-agent-ready id — re-run `ma_template_list`; offer an available LINE archetype or blank canvas |
| `error/ma-template-not-available` with `unavailableReasons` | Explain reasons in customer language; do not call get/create for that template; offer available alternative |
| `platform_not_integrated` | Channel not connected for this org |
| `ga4_service_not_enabled` / `ga4_domain_not_configured` | GA4 entitlement and/or domain missing — do not treat domain alone as enough |
| `ec_not_enabled` / `ec_provider_not_enabled` | EC / provider not enabled |
| feature_not_enabled + featureKey | Missing feature (for example featureKey=ma_sticker) — name that feature to the customer |
| Discovery code ma_not_available | Marketing Automation product not available for the org |
| Validate after discovery succeeds but capability changed | Trust current validate/create errors; discovery was advisory — re-list or fall back to available archetype / blank canvas |
| `error/ma-studio-ga4-service-not-enabled` / `error/ma-studio-feature-not-enabled` | Same facts as discovery; `featureKey` may be present on feature errors |
| No catalog archetype covers customer intent (e.g. tagging action, keyword branch, rejoin) | Acknowledge the gap; after customer OK, author blank-canvas using recipes below |

## Validate error remediation

Group related codes; fix **wiring**, not copy, unless the code is clearly about content.

### Schedule / journey bounds

| Code | What to do |
|------|------------|
| `error/ma-studio-start-in-past` | Journey `startTime` cannot be in the past. Ask for a start instant that is **now or later** (timezone per universal policy), then re-validate. |

### Shape / type

| Code | What to do |
|------|------------|
| `error/ma-payload-unsupported-condition-shape` | Remove `event` / `branches` / `sourceMessageNodeId`; clone Studio fixture |
| `error/ma-payload-unsupported-condition-type` | Use allowlisted `data.type` (`click` / `n-click` / keyword / sticker variants) |

### Group + timing

| Code | What to do |
|------|------------|
| `error/ma-payload-condition-group-missing` | Point `groupId` at an existing `group` node |
| `error/ma-payload-condition-group-type` | Click conditions need `data.type: "click"` on the group |
| `error/ma-payload-condition-group-click-type` | Set `clickType` to `any` or `button` |
| `error/ma-payload-condition-group-duration-shape` | **Click groups:** use only `data.timeout: { value, unit }`; remove raw `time` / `timeType` |
| `error/ma-payload-condition-group-timeout-value` | Set `timeout.value` to a customer-confirmed positive whole number |
| `error/ma-payload-condition-group-timeout-unit` | Set `timeout.unit` to `minute` \| `hour` \| `day` |
| `error/ma-payload-condition-group-time-type` | Click: repair via `timeout.unit`. **Keyword groups:** set Studio `timeType` to `minute` \| `hour` \| `day` |
| `error/ma-payload-condition-group-time` | Click: repair via `timeout`. **Keyword groups:** set Studio `time` to non-negative seconds (`value * unit factor`) |

**Click duration authoring:** ask value + unit; write `group.data.timeout`. Never calculate seconds for click groups.

**Keyword duration authoring:** ask value + unit in business language, then write Studio `timeType` (= unit) and `time` (= seconds). Do **not** use click `data.timeout` on keyword groups (intent-only compile is click-only).

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

## Blank-canvas recipes (standard edition)

Use when catalog has no matching archetype. Always set `authoringSource: "blank-canvas"`, complete the checklist, validate, create draft, then publish with approval.

### Keyword-branch (hit / miss)

Topology: trigger → guide `message` → keyword `group` + `right-keyword` / `n-keyword` (optional `wrong-keyword`) → per-branch actions → `end`.

Structural reference: [`references/fixtures/ma-tag-keyword-branch-skeleton.json`](references/fixtures/ma-tag-keyword-branch-skeleton.json).

Keyword `group.data`: `type: "keyword"`, `source` = guide message id, `keywordType` (`keyword` \| `any`), `keywords` when type is `keyword`, `timeType` + `time` (seconds), optional `allowMulti`. Conditions: `groupId`, `source`, `type` ∈ `right-keyword` \| `n-keyword` \| `wrong-keyword`. Edges: guide message → each condition (same pattern as click-branch).

### Node recipes (minimal shapes)

Align with Super8 Studio / `marketing-automation-front-end` editor nodes. Do not invent alternate enums or wrappers.

| Intent | Node sketch |
|--------|-------------|
| Tag trigger | `trigger` with `data.type: "tag"`, `match` (`any`\|`all`), `tags: [...]` — no tag `event` |
| Keyword trigger | `trigger` with `data.type: "keyword"`, `conditions: [{ type: "keyword", value: ["…"] }]` (non-empty `value` list from customer) |
| Rejoin trigger | `trigger` with `data.type: "rejoin"` (confirm platform/rejoin semantics with customer) |
| Tagging action | Top-level node `type: "tagging"` with `data.tags: [...]` (and usually `data.type: "tagging"`). **Not** an `action` wrapper node. |
| Wait | Top-level `wait` with `data.waitTime` = non-negative integer **seconds** (Studio default often `300`; `0` means no delay). Prefer message-node `waitTime` only when delaying that message step (same seconds rule; `null` = off on messages). |
| Schedule | Top-level `schedule` with Studio clock fields (Asia/Taipei wall clock for `time`). Required: `data.type` ∈ `day` \| `week` \| `month`, and `data.time` as `"HH:mm"` (e.g. `"18:10"`). **day:** only `type` + `time`. **week:** also `data.week: number[]` weekday ints `0`–`6` (Sunday=`0`). **month:** also `data.month: number[]` day-of-month `1`–`31`, plus `data.hasLastDay: boolean`. Disclose **next fire** in the confirmation table (if today’s slot already passed → next occurrence). |
| Inbox | Top-level `type: "inbox"` with `data.inbox` **exactly** one of Studio values: `unassigned` \| `private` \| `done` (Console dropdown; no other values). For `private`, also set `data.userId` (org member objectId) and usually `data.displayName`. **Not** an `action` wrapper. Unknown inbox strings must not be used — runtime would silently treat them like unassigned. |

Wire with normal `edges` (`source`/`target`). Validate before create.

## Field reference (create / validate body)

| Field | Role |
|--------|------|
| `orgId` | Target org (customer-specified; must match session authority). |
| `templateType` (root) | Studio wiring. Catalog-backed: consume `ma_template_get` value (`defaultRootTemplateType`). Blank canvas: `authoringSource: "blank-canvas"` + omit → server `all`. Not a normal customer prompt. Separate from **`messages[].templateType`**. |
| `type` | Procedure type; often derived server-side — ask if the customer or template requires an explicit value. |
| `name` | Display name from the customer. |
| `enabled` | Whether the customer wants it enabled. |
| `platform` | Channel confirmed by the customer. |
| `startTime` / `endTime` | Schedule bounds from the customer; encode customer-derived instants per timezone-policy (default Asia/Taipei when timezone omitted). Confirm **customer intent** + **MCP input** before validate/create. |
| `limits` | Total / per-customer caps; **`message` and `per_customer` must be non-negative integers**, or `per_customer: "onceByDay"`. Do **not** call `0` unlimited. |
| `fbTag` | Meta-related tag policy (customer-confirmed). |
| `oos` | Off-hours / OOS settings confirmed by the customer. |
| `nodes` / `edges` | Graph shape; business content from the customer; ids/positions may be wiring-only. |

## Guardrails

- Org-scoped MCP tools require organization owner/admin; **business fields in the body must come from explicit customer input**, not silent presets.
- If you change the payload after customer sign-off, get renewed approval when business meaning changes.
- Do not paste internal Mongo procedure documents; use the MCP / shared MA procedure payload shape only.
- Never invent `template_button_click` / `branches` condition nodes; never fan out multiple `sourceHandle` edges from one condition.
- If authentication is missing, expired, revoked, or the host reports `401` / `403` / authentication-required, hand off to `insightark-session` for host OAuth recovery before retrying. Do not treat network/timeout/`5xx` failures as OAuth problems.
