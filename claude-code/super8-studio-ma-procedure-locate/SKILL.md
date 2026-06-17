---
name: super8-studio-ma-procedure-locate
description: List Marketing Automation journeys in an org by optional journey name substring, resolve procedureId from the customer's spoken/written MA name, then drive status/start/pause/trigger APIs. Developer session, org owner/admin. Never invent journey names — always ask the customer, then narrow the list.
when_to_use: When the user asks to query MA journey status, start (publish draft), pause, resume, or trigger by journey name rather than procedure id — or before any id-scoped MA call where only the journey title is known.
allowed-mcp: false
license: MIT
metadata:
  owner: platform
  version: "1.0.0"
  category: marketing-automation-api
  domain: super8-studio
---

# Skill: super8-studio-ma-procedure-locate

## Scripts (in `../_super8-studio-api-shared/scripts/`)

| Script | Purpose |
|--------|---------|
| `ma_procedure_list.sh` | `GET /developer/v1/automation/procedures` — **`--org-id`** (or `S8_ORG_ID`), optional **`--name`**, **`--skip`**, **`--limit`**. Default **`limit=20`**（腳本未指定時）；回傳僅輕量欄位（無圖檔無成效彙總）。用 **`data.hasMore`** + **`skip`** 翻頁。 |
| `ma_procedure_status.sh` | After resolving id: `GET .../procedures/{procedureId}?orgId=...` |
| `ma_procedure_start.sh` | `POST .../procedures/{procedureId}/start` |
| `ma_procedure_pause.sh` | `PATCH .../procedures/{procedureId}/status` — `--action pause` \| `resume` |
| `ma_procedure_trigger.sh` | `POST .../procedures/{procedureId}/trigger` — requires `--customer-id` |

## Mandatory workflow

1. **Collect from the customer** the target org (`orgId` if not implicit from env) and the **exact journey name or distinctive substring** they use (never guess from samples).
2. Run **`ma_procedure_list.sh`** with `--name` set to customer text (trimmed)，**視需要分頁**直到 **`data.hasMore === false`** 或已找到目標。若 **`data.procedures` is empty**， widen wording only **after asking** the customer；若可能只是落在後頁，應先用 **`--skip`** 掃過再下結論。
3. **Disambiguate**:
   - **0 rows** → tell the customer no match; ask for alternate spelling/substring or confirm org.
   - **1 row** → use **`procedureId`** from that row **only after** quoting **`name`** + **`platform`** + **`status`**/`editing`/`pausing` and getting customer confirmation (“是這個嗎？”).
   - **2+ rows** → show a compact table (**name**, **platform**, **procedureId**, **status**, **editing**, **pausing**) and ask the customer to pick one **procedureId** or refine `--name`.
4. After confirmation, invoke the appropriate id-scoped script (`status` / `start` / `pause` / `trigger`) from **`super8-studio-ma-automation`** (same scripts, shared folder).

## Pagination（列表分頁）

- **預設每頁 20 筆**：腳本未傳 **`--limit`** 時會自動加上 **`limit=20`**（與後端預設一致）。
- **`data.hasMore === true`** 表示還有更多筆：**下一請求**將 **`--skip`** 設為 **`本頁 skip + 本頁 limit`**（例：`skip=0`、`limit=20` 後接 `skip=20`）。
- **`--limit`** 可調大但不超過 API 上限 **100**；名稱篩選下若仍 **`hasMore`**，必須繼續翻頁，不可假設已全部載入。
- Inspect：**`jq`** 示例：`.data | {skip, limit, hasMore, count: (.procedures|length)}`

## API response shape

- List success: **`data`** 包含 **`procedures`、`skip`、`limit`、`hasMore`**。每筆僅 **`procedureId`、標題/平台/狀態/時段等基本欄位**（無 graph nodes/edges、無 analytics／成效資料）。
- HTTP **404** **`error/ma-org-resource-not-found`**: MA not provisioned for that org — explain to the customer; do not fabricate journeys.

## Hard rules

- Do not ask customers to memorize **`procedureId`**. Operators speak in **旅程名稱 / MA 名稱**; you resolve ids via **`ma_procedure_list.sh`** first.
- If the customer's phrase matches multiple live journeys with similar names, **always** pause for explicit confirmation before mutating (**start**/ **pause**/ **trigger**).

## Related skill

Creation and validation of new journeys stay in **`super8-studio-ma-automation`**; this skill focuses on **discover → confirm id → lifecycle / trigger**.

## When not to use

- The user needs conversation, customer, or broadcast operations outside Marketing Automation.
- Required business fields, journey name, `procedureId`, confirmation, or payload file has not been explicitly provided.
- MA is not provisioned for the target org.

## Inputs

- `--org-id` or `S8_ORG_ID` (required).
- Journey name for locate workflows; `--procedure-id` for lifecycle workflows.
- `--json-file`, `--confirmation-file`, customer id, and action flags required by MA scripts.

## Outputs

- Procedure lists, resolved `procedureId`, validation results, created procedure status, publish/pause/trigger confirmations, or current procedure status.

## Failure handling

- If validation returns errors, explain each path and message; do not autocorrect business-meaning fields.
- If multiple journeys match, ask the user to choose before proceeding.
- If trigger is not allowed or MA is not provisioned, report the API reason and stop.

## Observability

- Record script invoked, filter used, pages fetched, `procedureId` when available, HTTP status, and validation status. Do not log full graph data.
