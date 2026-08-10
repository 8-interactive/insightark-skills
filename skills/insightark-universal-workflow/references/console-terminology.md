# Console terminology (zh-TW)

Canonical customer-facing labels for InsightArk-reachable Studio features. Prefer the **Console label** (or accepted **Short form**) when naming these features to customers. Use **Internal / MCP** only to choose tools or confirm mappings — keep MCP tool ids and English schema names in English when calling tools.

Read this file from `insightark-universal-workflow` before capability summaries or confirmation copy that names Studio features.

## Glossary

| Console label | English | Short form | Internal / MCP |
|---|---|---|---|
| 群發訊息 | Broadcast | 群發 | broadcast / `broadcast_*` |
| 自動旅程 | Auto journey | 旅程 | marketing automation / MA / `ma_*` |
| 客戶中心 | Customer center | — | CRM / customer manager |
| 標籤管理 | Tag management | 標籤 | tag / `crm_tag_*` |
| 目標客戶群 | Target customer group | 客戶群 | CustomerGroup / `crm_customer_group_*` |
| 一對一對話 | One-to-one conversation | 對話 | conversation / `messaging_conversation_*` |
| 群組對話 | Group chat | LINE 群組 | ChatGroup / `messaging_chat_group_*` |
| 已連接的應用程式 | Connected apps | — | Connected Apps / OAuth |

### Pack-local (not a Console nav label)

| Pack-facing label | English | Short form | Internal / MCP | Notes |
|---|---|---|---|---|
| InsightArk MCP credits | InsightArk MCP credits | credits | `credits_usage` | Pack-local / non-Console. Do not conflate with Console AI 點數 or LINE／platform messaging quota. |

## Capability summary example

When a customer asks what InsightArk can help with, prefer this shape (adjust to org entitlements):

- **客戶中心**：搜尋客戶、查看／更新資料、管理標籤與目標客戶群。
- **對話**：查詢一對一或群組對話、依期間／關鍵字／來源分析訊息。
- **訊息**：草擬、預覽，並在確認後發送單一客戶訊息。
- **群發訊息**：估算對象、預覽內容、建立／排程群發、追蹤發送狀態。
- **自動旅程**：查看範本、驗證旅程、建立草稿、發布／暫停／觸發。
- **媒體與額度**：取得上傳網址、查詢各組織 InsightArk MCP credits。

May append an internal name in parentheses when helpful, for example「群發訊息（broadcast）」。
