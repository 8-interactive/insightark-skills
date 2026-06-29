# Super 8 Studio API Skills

[English](#english) | [中文](#中文)

---

<a name="english"></a>

**Super 8 Studio API Skills** is a plugin for Claude Code and Codex that brings the [Super 8 Studio](https://www.no8.io) Developer API directly into your AI agent workflow.

It provides a curated set of reusable skills covering the full CRM lifecycle — investigating conversations, managing customers, sending broadcasts, and automating marketing journeys. Once installed, your agent can query inboxes, update customer records, compose messages, and trigger campaigns without leaving the conversation interface.

Credentials are managed securely through the platform's native keychain on Claude Code, or via an environment config file on Codex. A built-in health check runs automatically at session start to surface credential issues early.

## Plugin Install (Claude Code)

### 1. Add marketplace and install

```bash
claude plugin marketplace add 8-interactive/super8-studio-api-skills
claude plugin install super8-studio-api-skills@super8-studio-api-skills
```

During installation, Claude Code will prompt for:

| Variable | Description |
| --- | --- |
| `S8_SESSION_TOKEN` | Developer `_SessionToken` (stored in system keychain) |

### 2. Enable the plugin

Installed disabled by default (connects to an external API):

```bash
claude plugin enable super8-studio-api-skills@super8-studio-api-skills
```

A `SessionStart` hook runs `doctor.js` automatically so credential issues surface at the start of every session.

### Session token

1. Console → **Account Settings → Developer API**
2. Create a token (shown **once**)

Tokens expire after six months. Never commit tokens or share them in chat.

---

## Plugin Install (Codex)

### 1. Add marketplace and install

```bash
codex plugin marketplace add 8-interactive/super8-studio-api-skills
codex plugin install super8-studio-api-skills@super8-studio-api-skills
```

### 2. Configure credentials

Codex does not use a system keychain. Run the Node setup to write credentials to `~/.super8-studio.env`:

```bash
npx @super8/studio-api-skills setup
```

| Variable | Description |
| --- | --- |
| `S8_SESSION_TOKEN` | Developer `_SessionToken` |

### Session token

1. Console → **Account Settings → Developer API**
2. Create a token (shown **once**)

Tokens expire after six months. Never commit tokens or share them in chat.

---

## Install via npx (any coding agent)

Pure Node — works on macOS, Linux, and **native Windows** (no bash, `curl`, or `jq` required). Node 18+ only.

```bash
npx @super8/studio-api-skills install     # interactive: choose location → agents → confirm
npx @super8/studio-api-skills setup       # configure credentials, then run doctor
npx @super8/studio-api-skills doctor      # health check
```

The installer asks **where** to install — global (`~`) or this repo (current
directory) — and **which** coding agents to install for (Claude Code, OpenCode,
Cursor, GitHub Copilot, Codex), then copies the skills into each agent's skills
folder.

### Config files

| Location | Path | Contents |
| --- | --- | --- |
| Install registry | `~/.super8-studio.config` | Skills install paths |
| Skills dir | `{skills-target}/.super8-studio.env` | `S8_SESSION_TOKEN`, `S8_ORG_ID` |
| User (fallback) | `~/.super8-studio.env` | Fallback if install registry is missing |
| Project override | `{project}/.super8-studio.env` | Optional `S8_ORG_ID` / stage URL override |

**Load order:** user file → skills install dir → project file → process environment.

### Non-interactive / advanced

```bash
npx @super8/studio-api-skills install --location global --agents claude-code,cursor,codex
npx @super8/studio-api-skills install --location repo --agents all
npx @super8/studio-api-skills install --target ~/.agents/skills   # shared folder, no per-agent subpaths
npx @super8/studio-api-skills uninstall --location global --agents claude-code,codex
```

---

## Skills

| Skill | Purpose |
| --- | --- |
| `super8-studio-conversations` | List conversations by platform, inbox state, customer, or activity time |
| `super8-studio-conversation-detail` | Conversation summary and message timeline |
| `super8-studio-message-search` | Keyword search across the org or within one conversation |
| `super8-studio-customer-search` | Find customer segments by tag or activity |
| `super8-studio-customer-detail` | Customer profile and activity |
| `super8-studio-customer-manager` | Manage customer records |
| `super8-studio-customer-update` | Update customer fields |
| `super8-studio-customer-tag-add` | Add tags to a customer |
| `super8-studio-customer-tag-remove` | Remove tags from a customer |
| `super8-studio-customer-send-message` | Send a message to a customer |
| `super8-studio-broadcast-create` | Create a broadcast |
| `super8-studio-broadcast-get` | Get broadcast details |
| `super8-studio-broadcast-list` | List broadcasts |
| `super8-studio-broadcast-manager` | Manage broadcast lifecycle |
| `super8-studio-messaging` | Compose and send messages |
| `super8-studio-investigator` | Deep investigation across conversations and customers |
| `super8-studio-session` | Session and auth utilities |
| `super8-studio-org-scope` | Org-scoped API utilities |

**Typical flow:** `customer-search` or `conversations` → `message-search` → `conversation-detail`

---

<a name="中文"></a>

**Super 8 Studio API Skills** 是適用於 Claude Code 與 Codex 的 Plugin，將 [Super 8 Studio](https://www.no8.io) Developer API 直接整合進 AI Agent 工作流程。

內含一組涵蓋完整 CRM 生命週期的可重用 Skills，包括對話調查、客戶管理、廣播發送與行銷自動化。安裝後，Agent 可在不離開對話介面的情況下查詢收件匣、更新客戶資料、撰寫訊息並觸發行銷活動。

憑證管理方面，Claude Code 透過平台原生系統鑰匙圈安全儲存，Codex 則透過環境設定檔管理。內建健康檢查會在每次 session 開始時自動執行，提早偵測憑證問題。

## Plugin 安裝（Claude Code）

### 1. 加入 Marketplace 並安裝

```bash
claude plugin marketplace add 8-interactive/super8-studio-api-skills
claude plugin install super8-studio-api-skills@super8-studio-api-skills
```

安裝過程中，Claude Code 會提示輸入以下資訊：

| 變數 | 說明 |
| --- | --- |
| `S8_SESSION_TOKEN` | Developer `_SessionToken`（儲存於系統鑰匙圈） |

### 2. 啟用 Plugin

預設為停用狀態（因需連線至外部 API）：

```bash
claude plugin enable super8-studio-api-skills@super8-studio-api-skills
```

`SessionStart` hook 會在每次 session 開始時自動執行 `doctor.js`，讓憑證問題提早浮現。

### Session Token 取得方式

1. Console → **Account Settings → Developer API**
2. 建立 Token（**僅顯示一次**）

Token 有效期六個月，請勿提交至版本控制或在對話中分享。

---

## Plugin 安裝（Codex）

### 1. 加入 Marketplace 並安裝

```bash
codex plugin marketplace add 8-interactive/super8-studio-api-skills
codex plugin install super8-studio-api-skills@super8-studio-api-skills
```

### 2. 設定憑證

Codex 不使用系統鑰匙圈，請執行 Node setup 將憑證寫入 `~/.super8-studio.env`：

```bash
npx @super8/studio-api-skills setup
```

| 變數 | 說明 |
| --- | --- |
| `S8_SESSION_TOKEN` | Developer `_SessionToken` |

### Session Token 取得方式

1. Console → **Account Settings → Developer API**
2. 建立 Token（**僅顯示一次**）

Token 有效期六個月，請勿提交至版本控制或在對話中分享。

---

## 透過 npx 安裝（適用任何 coding agent）

純 Node 實作——可在 macOS、Linux 與**原生 Windows** 上執行（無需 bash、`curl` 或 `jq`）。僅需 Node 18+。

```bash
npx @super8/studio-api-skills install     # 互動式：選擇位置 → agents → 確認
npx @super8/studio-api-skills setup       # 設定憑證，接著執行 doctor
npx @super8/studio-api-skills doctor      # 健康檢查
```

安裝器會詢問**安裝位置**——global（`~`）或此 repo（當前目錄）——以及要**安裝給哪些
coding agent**（Claude Code、OpenCode、Cursor、GitHub Copilot、Codex），然後將
skills 複製到各 agent 的 skills 資料夾。

### 設定檔說明

| 位置 | 路徑 | 內容 |
| --- | --- | --- |
| 安裝登錄檔 | `~/.super8-studio.config` | Skills 安裝路徑 |
| Skills 目錄 | `{skills-target}/.super8-studio.env` | `S8_SESSION_TOKEN`、`S8_ORG_ID` |
| 使用者（備援） | `~/.super8-studio.env` | 找不到安裝登錄檔時的備援 |
| 專案覆蓋 | `{project}/.super8-studio.env` | 可選的 `S8_ORG_ID` 或測試環境 URL |

**載入順序：** 使用者檔案 → Skills 安裝目錄 → 專案檔案 → Process 環境變數（最高優先）。

### 非互動 / 進階

```bash
npx @super8/studio-api-skills install --location global --agents claude-code,cursor,codex
npx @super8/studio-api-skills install --location repo --agents all
npx @super8/studio-api-skills install --target ~/.agents/skills   # 共用資料夾，不使用各 agent 子目錄
npx @super8/studio-api-skills uninstall --location global --agents claude-code,codex
```

---

## Skills 列表

| Skill | 用途 |
| --- | --- |
| `super8-studio-conversations` | 依平台、收件匣狀態、客戶或活動時間列出對話 |
| `super8-studio-conversation-detail` | 對話摘要與訊息時間軸 |
| `super8-studio-message-search` | 跨全組織或在單一對話中搜尋關鍵字 |
| `super8-studio-customer-search` | 依標籤或活動搜尋客戶族群 |
| `super8-studio-customer-detail` | 客戶個人資料與活動紀錄 |
| `super8-studio-customer-manager` | 管理客戶資料 |
| `super8-studio-customer-update` | 更新客戶欄位 |
| `super8-studio-customer-tag-add` | 為客戶新增標籤 |
| `super8-studio-customer-tag-remove` | 移除客戶標籤 |
| `super8-studio-customer-send-message` | 傳送訊息給客戶 |
| `super8-studio-broadcast-create` | 建立廣播 |
| `super8-studio-broadcast-get` | 取得廣播詳情 |
| `super8-studio-broadcast-list` | 列出廣播 |
| `super8-studio-broadcast-manager` | 管理廣播生命週期 |
| `super8-studio-messaging` | 撰寫與發送訊息 |
| `super8-studio-investigator` | 跨對話與客戶的深度調查 |
| `super8-studio-session` | Session 與驗證工具 |
| `super8-studio-org-scope` | 組織範圍 API 工具 |

**典型流程：** `customer-search` 或 `conversations` → `message-search` → `conversation-detail`
