# Console terminology (zh-TW)

Canonical customer-facing labels for InsightArk-reachable Studio features. Console zh-TW i18n is the source of truth for Console-backed rows. Agents MUST prefer the **Console label** (or accepted **Short form**) when naming these features to customers. MCP tool ids and English schema names stay English when calling tools.

Read this file from `insightark-universal-workflow` before capability summaries or confirmation copy that names Studio features.

## Glossary

| Console label | Short form | Internal / MCP | Banned | Evidence |
|---|---|---|---|---|
| 群發訊息 | 群發 | broadcast / `broadcast_*` | 廣播 | super8-v2-console:src/i18n/zh-TW/main.json#/organization/broadcast=群發訊息 |
| 自動旅程 | 旅程 | marketing automation / MA / `ma_*` | 行銷自動化 | super8-v2-console:src/i18n/zh-TW/main.json#/organization/marketing-automation=自動旅程 |
| 客戶中心 | — | CRM / customer manager | — | super8-v2-console:src/i18n/zh-TW/main.json#/organization/customer-management=客戶中心 |
| 標籤管理 | 標籤 | tag / `crm_tag_*` | — | super8-v2-console:src/i18n/zh-TW/main.json#/organization/tag-management=標籤管理 |
| 目標客戶群 | 客戶群 | CustomerGroup / `crm_customer_group_*` | — | super8-v2-console:src/i18n/zh-TW/main.json#/customer-groups/title=目標客戶群 |
| 一對一對話 | 對話 | conversation / `messaging_conversation_*` | — | super8-v2-console:src/i18n/zh-TW/main.json#/navigation/oneToOneConversation=一對一對話 |
| 群組對話 | LINE 群組 | ChatGroup / `messaging_chat_group_*` | — | super8-v2-console:src/i18n/zh-TW/main.json#/chatGroup/title=群組對話 |
| 已連接的應用程式 | — | Connected Apps / OAuth | — | super8-v2-console:src/i18n/zh-TW/main.json#/oauth-connected-apps/title=已連接的應用程式 |

### Pack-local (not a Console nav label)

| Pack-facing label | Short form | Internal / MCP | Notes |
|---|---|---|---|
| InsightArk MCP credits | credits | `credits_usage` | Pack-local / non-Console. Do not conflate with Console AI 點數 or LINE／platform messaging quota. |

## Capability summary example

When a customer asks what InsightArk can help with, prefer this shape (adjust to org entitlements):

- **客戶中心**：搜尋客戶、查看／更新資料、管理標籤與目標客戶群。
- **對話**：查詢一對一或群組對話、依期間／關鍵字／來源分析訊息。
- **訊息**：草擬、預覽，並在確認後發送單一客戶訊息。
- **群發訊息**：估算對象、預覽內容、建立／排程群發、追蹤發送狀態。
- **自動旅程**：查看範本、驗證旅程、建立草稿、發布／暫停／觸發。
- **媒體與額度**：取得上傳網址、查詢各組織 InsightArk MCP credits。

May append an internal name in parentheses when helpful, for example「群發訊息（broadcast）」。
