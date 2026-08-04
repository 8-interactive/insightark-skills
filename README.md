# InsightArk Connector for AI Agents

[中文](#適用於-ai-agent-的-insightark-連接器)

InsightArk is a core product of **Super 8 Studio**—an AI-driven conversational commerce and marketing platform. It provides social customer management and data intelligence capabilities for agent-assisted operations.

This plugin provides an officially supported InsightArk connection. It packages the `insightark` MCP server with workflow skills, allowing agents to work with InsightArk through natural-language requests. Officially supported agents are:

- ChatGPT / Codex
- Claude Code
- Cursor

## Capabilities

Use the plugin to:

- investigate conversations and messages;
- search, update, and tag customers;
- draft, send, and monitor messages or broadcasts; and
- create, validate, start, pause, and inspect marketing-automation procedures.

For example:

> 調查昨天未回覆的對話，整理待跟進清單。
>
> 找出最近 30 天有互動的客戶，並加上 `VIP` 標籤。

| Skill | Capability |
|---|---|
| `insightark-universal-workflow` | Shared policy (customer guidance, rich preview, write lifecycle, scheduling timezone) — prerequisite for all workflows |
| `insightark-session` | Validate access and inspect the authenticated identity, organizations, and credit balance |
| `insightark-investigator` | Investigate conversations and messages in read-only mode |
| `insightark-conversations` | List and retrieve conversations and messages |
| `insightark-customer-manager` | Search and update customers; add or remove tags |
| `insightark-messaging` | Send and validate messages, including LINE templates |
| `insightark-broadcast-manager` | Create and monitor broadcasts |
| `insightark-ma-automation` | Manage marketing-automation procedures |

## Prerequisites

- An InsightArk-enabled Super 8 Studio organization.
- Organization administrator access.
- A supported agent from the list above.

## Installation and authentication

Install the plugin from a supported marketplace. The plugin automatically configures the bundled `insightark` MCP server; do not add it separately. MCP server authentication uses OAuth; the authorization flow differs by agent and is described in the relevant installation steps below.

### Marketplace source

When an agent asks for the marketplace source, copy this URL:

```text
https://github.com/8-interactive/insightark-skills
```

The marketplace and plugin identifier is `insightark-skills`.

### Complete OAuth authorization

The agent opens an InsightArk sign-in page during installation:

1. Sign in using your usual Super 8 Studio sign-in method.
2. On the authorization page, review the requested permissions:
   - `insightark-mcp:read`
   - `insightark-mcp:write`
3. Select **Allow** to complete authorization.

### ChatGPT desktop and Codex CLI

#### ChatGPT desktop

1. In the left sidebar, select **Plugins**.
2. Select the arrow next to **Create** in the upper-right corner, then select **Add marketplace**.
3. Paste the [marketplace source](#marketplace-source) into the **Source** field and select **Add marketplace**.
4. Return to **Plugins**. Open the **Personal** tab (next to **Public**).
5. Select **SUPER 8 Studio InsightArk Skills**.
6. Select **Install** in the upper-right corner. Installation opens the browser for OAuth automatically.

After OAuth completes, start a new **Codex Work** conversation in ChatGPT desktop.

#### Reauthorize

For ChatGPT desktop or Codex, uninstall the InsightArk plugin and install it again using the steps above. Installation starts OAuth automatically.

#### Codex CLI

```bash
codex plugin marketplace add https://github.com/8-interactive/insightark-skills
codex plugin add insightark-skills@insightark-skills
```

OAuth opens automatically during `codex plugin add`.

### Claude Code

#### Claude Code desktop app

1. Select the **+** button next to the chat prompt, then select **Plugins**.
2. Select **Add plugin**.
3. Add the [marketplace source](#marketplace-source), then select **SUPER 8 Studio InsightArk Skills**.
4. Select **Install** and complete OAuth in the browser when it opens.

#### Claude Code terminal

```text
/plugin marketplace add 8-interactive/insightark-skills
/plugin install insightark-skills@insightark-skills
```

When prompted, select the installation scope. OAuth opens automatically when the plugin is installed.

#### Reauthorize

Uninstall the InsightArk plugin, then install it again using the steps above. Installation starts OAuth automatically.

### Cursor

1. Open **Customize** from the Cursor sidebar, then select **Browse Marketplace** in the upper-right corner.
2. Open the **All** dropdown menu to the left of the **Manage** button at the top.
3. Select **Add Marketplace** → **Import from GitHub**.
4. Paste the [marketplace source](#marketplace-source) in the **Repository** field and complete the import.
5. On the Marketplace page, find **SUPER 8 Studio InsightArk Skills** and select **Add**.
6. Once the status changes to **Added**, open the plugin details page.
7. In the **MCPs** section, select **Authenticate** next to `insightark` to start OAuth authorization.

Cursor does not provide a native CLI command to install marketplace plugins. Cursor CLI reuses the plugin and MCP configuration installed in the IDE.

#### Reauthorize

After authentication, the **Authenticate** button is no longer shown. To authorize again:

1. Open the InsightArk plugin details page.
2. In the **MCPs** section, select `insightark` to open its configuration.
3. Under **Environments**, select **Logout** for the connected local environment.
4. Return to the plugin details page and select **Authenticate** next to `insightark`.

## Verify the connection

Ask your agent:

> 使用 `insightark-session` skill 驗證我的 InsightArk MCP 設定。

The skill calls `auth_me`. A successful result confirms that the agent can access your InsightArk organizations.

## Manage authorized agents

To review or revoke agent access:

1. In Super 8 Console, select your avatar in the lower-left corner.
2. Open the **User Information** tab.
3. Scroll to **Connected Apps** to view agents authorized through OAuth.
4. Select the relevant agent to revoke its authorization.

## Documentation

- [Changelog](./CHANGELOG.md)

---

# 適用於 AI Agent 的 InsightArk 連接器

[English](#insightark-connector-for-ai-agents)

InsightArk 是 **Super 8 Studio** 的核心產品，專注於社群顧客管理與數據洞察。Super 8 Studio 是雲發互動科技（Super 8）打造的 AI 驅動對話商務與行銷解決方案平台。

本 plugin 提供官方支援的 InsightArk 連線能力。它將 `insightark` MCP server 與工作流程 skills 打包，讓 agent 能依自然語言指令操作 InsightArk。目前官方支援的 agent 包括：
- ChatGPT / Codex
- Claude Code
- Cursor

## 功能

安裝後，你可以請 agent：

- 調查對話與訊息；
- 搜尋、更新客戶及管理標籤；
- 建立、發送與追蹤訊息或群發訊息；以及
- 建立、驗證、啟動、暫停及查看自動旅程。

例如：

> 調查昨天未回覆的對話，整理待跟進清單。
>
> 找出最近 30 天有互動的客戶，並加上 `VIP` 標籤。

| Skill | 功能 |
|---|---|
| `insightark-session` | 驗證存取權限，查看已認證身分、組織與剩餘額度 |
| `insightark-investigator` | 唯讀調查對話與訊息 |
| `insightark-conversations` | 列出與取得對話及訊息 |
| `insightark-customer-manager` | 搜尋與更新客戶，新增或移除標籤 |
| `insightark-messaging` | 發送與驗證訊息，包含 LINE 模板 |
| `insightark-broadcast-manager` | 建立與追蹤群發訊息 |
| `insightark-ma-automation` | 管理自動旅程 |

## 使用條件

- 需有已啟用 InsightArk 的 Super 8 Studio 組織。
- 需要具有組織的 admin 權限。
- 使用上述官方支援的 AI agent。

## 安裝與認證

從支援的 marketplace 安裝 plugin，Plugin 會自動設定內建的 `insightark` MCP server，請勿另外新增 MCP server。MCP server 認證走 OAuth 協定，依據不同的 agent 會有不同的認證流程，詳見各 agent 的說明。

### Marketplace 來源

當 agent 要求 marketplace 來源時，請複製以下 URL：

```text
https://github.com/8-interactive/insightark-skills
```

Marketplace 和 plugin 識別名稱皆為 `insightark-skills`。

### 完成 OAuth 授權

安裝時，agent 會開啟 InsightArk 登入頁面：

1. 依你過往登入 Super 8 Studio 的方式完成登入。
2. 在授權頁面確認要求的權限範圍：
   - `insightark-mcp:read`
   - `insightark-mcp:write`
3. 點選 **允許**，即完成授權。

### ChatGPT desktop 與 Codex CLI

#### ChatGPT desktop

1. 在左側列表點選 **外掛程式**。
2. 點選右上角 **建立** 右方的向下展開箭頭，再選擇 **新增市集**。
3. 在 **來源** 欄位貼上 [Marketplace 來源](#marketplace-來源)，再按 **新增市集**。
4. 回到 **外掛程式**，在 **公開** 與 **個人** 頁籤中選擇 **個人**。
5. 點選 **SUPER 8 Studio InsightArk Skills**。
6. 點選右上角的 **安裝**。安裝後會自動開啟瀏覽器進行 OAuth 認證。

OAuth 完成後，在 ChatGPT desktop 開啟新的 **Codex Work** 對話即可使用 plugin。

#### 重新授權

ChatGPT desktop 或 Codex 請先解除安裝 InsightArk plugin，再依上述步驟重新安裝。安裝時會自動啟動 OAuth。

#### Codex CLI

```bash
codex plugin marketplace add https://github.com/8-interactive/insightark-skills
codex plugin add insightark-skills@insightark-skills
```

執行 `codex plugin add` 時會自動開啟 OAuth。

### Claude Code

#### Claude Code desktop app

1. 點選 chat prompt 旁的 **+**，再選擇 **Plugins**。
2. 點選 **Add plugin**。
3. 加入 [Marketplace 來源](#marketplace-來源)，選擇 **SUPER 8 Studio InsightArk Skills**。
4. 點選 **Install**，並在瀏覽器開啟後完成 OAuth。

#### Claude Code terminal

```text
/plugin marketplace add 8-interactive/insightark-skills
/plugin install insightark-skills@insightark-skills
```

依提示選擇安裝範圍，安裝 plugin 時會自動開啟 OAuth。

#### 重新授權

解除安裝 InsightArk plugin，再依上述步驟重新安裝。安裝時會自動啟動 OAuth。

### Cursor

1. 在 Cursor 側邊欄開啟 **Customize**，再點選右上角的 **Browse Marketplace**。
2. 開啟上方 **Manage** 按鈕左側的 **All** 下拉選單。
3. 選擇 **Add Marketplace** → **Import from GitHub**。
4. 在 **Repository** 欄位貼上 [Marketplace 來源](#marketplace-來源)，完成匯入。
5. 在 Marketplace 頁面上找到 **SUPER 8 Studio InsightArk Skills**，點選 **Add**。
6. 當狀態變為 **Added** 後，點選進入 plugin 詳細頁面。
7. 在 **MCPs** 區塊的 `insightark` 右側點選 **Authenticate**，開始 OAuth 授權流程。

Cursor 目前沒有原生 CLI 指令可安裝 marketplace plugin。Cursor CLI 會沿用 IDE 已安裝的 plugin 與 MCP 設定。

#### 重新授權

完成認證後，**Authenticate** 按鈕會消失。需要重新授權時：

1. 開啟 InsightArk plugin 詳細頁面。
2. 在 **MCPs** 區塊點選 `insightark`，開啟 MCP 設定。
3. 在 **Environments** 中，對已連接的 local environment 點選 **Logout**。
4. 回到 plugin 詳細頁面，在 `insightark` 右側點選 **Authenticate**。

## 驗證連線

請 agent：

> 使用 `insightark-session` skill 驗證我的 InsightArk MCP 設定。

該 skill 會呼叫 `auth_me`。成功結果代表 agent 已能存取你的 InsightArk 組織。

## 管理已授權的 agent

檢視或撤銷 agent 的授權：

1. 在 Super 8 Console 左下角點選使用者頭像。
2. 開啟 **使用者資訊** 頁籤。
3. 往下滑到 **已連接的應用程式**，即可查看已透過 OAuth 授權的 agent。
4. 選擇要撤銷的 agent，取消其授權。

## 文件

- [Changelog](./CHANGELOG.md)
