# SUPER 8 Studio InsightArk Skills

[English](#english) | [中文](#中文)

---

<a name="english"></a>

**SUPER 8 Studio InsightArk Skills** is a plugin for Claude Code, Codex, and Cursor that brings the [Super 8 Studio](https://www.no8.io) Developer API directly into your AI agent workflow.

It provides a curated set of reusable skills covering the full CRM lifecycle — investigating conversations, managing customers, sending broadcasts, and automating marketing journeys. Once installed, your agent can query inboxes, update customer records, compose messages, and trigger campaigns without leaving the conversation interface.

Credentials are managed securely through the platform's native keychain on Claude Code, or via an environment config file on Codex. A built-in health check runs automatically at session start to surface credential issues early.

## Plugin Install (Claude Code)

### 1. Add marketplace and install

```bash
claude plugin marketplace add 8-interactive/insightark-skills
claude plugin install insightark-skills@insightark-skills
```

> **Internal staging:** pin the marketplace catalog to the `staging` branch:
> `claude plugin marketplace add 8-interactive/insightark-skills@staging`

During installation, Claude Code will prompt for your Developer API session token only. The hosted MCP endpoint URL is baked into the plugin at release time (production vs staging).

| Variable           | Description                                           |
| ------------------ | ----------------------------------------------------- |
| `S8_SESSION_TOKEN` | Developer `_SessionToken` (stored in system keychain) |

After install, run `claude plugin details insightark-skills@insightark-skills` and confirm **MCP servers ≥ 1** (`insightark` with the hosted HTTP URL).

### 2. Enable the plugin

Installed disabled by default (connects to an external API):

```bash
claude plugin enable insightark-skills@insightark-skills
```

A `SessionStart` hook runs `doctor.sh` automatically so credential issues surface at the start of every session.

### 3. Configure `S8_SESSION_TOKEN` (required)

Claude CLI install/enable may not prompt for credentials. Open Claude Code and run:

```text
/plugin configure insightark-skills@insightark-skills
```

Get your token from Console:

- Production: `https://console.no8.io` → Account Settings → Developer API → Create token
- Staging: `https://stage-console.no8.io` → Account Settings → Developer API → Create token

The token starts with `r:` and is shown once.

### Session token

1. Console → **Account Settings → Developer API**
2. Create a token (shown **once**)

Tokens expire after six months. Never commit tokens or share them in chat.

---

## Plugin Install (Codex)

### 1. Add marketplace and install

```bash
codex plugin marketplace add 8-interactive/insightark-skills
codex plugin install insightark-skills@insightark-skills
```

### 2. Configure credentials

The Codex plugin bundles hosted MCP via `.mcp.json` and prompts for `S8_SESSION_TOKEN` at install time.

If your Codex build does not wire plugin MCP tokens correctly, run `setup-env.sh` to write `~/.insightark.env` and optionally merge client MCP config:

```bash
./setup-env.sh
# or non-interactive + client config fallback:
./setup-env.sh --session-token "r:..." --write-client-configs
```

| Variable           | Description                                  |
| ------------------ | -------------------------------------------- |
| `S8_SESSION_TOKEN` | Developer `_SessionToken`                    |
| `S8_API_URL`       | Optional override in `.insightark.env` only (default URL comes from release channel) |

### Session token

1. Console → **Account Settings → Developer API**
2. Create a token (shown **once**)

Tokens expire after six months. Never commit tokens or share them in chat.

---

## Plugin Install (Cursor)

### 1. Install from GitHub mirror or local checkout

Install the plugin from the [GitHub mirror](https://github.com/8-interactive/insightark-skills) using **Cursor → Settings → Plugins → Install from local repo**, or clone and point Cursor at the checkout.

### 2. Configure credentials and MCP

Run `setup-env.sh` after install. Use `--write-client-configs` to upsert `mcpServers.insightark` in `~/.cursor/mcp.json` with the baked hosted URL and your token:

```bash
./setup-env.sh
./setup-env.sh --session-token "r:..." --write-client-configs
```

Confirm **Cursor Settings → MCP** shows `insightark` connected.

---

## Tarball Install

Download and extract the latest release directly from the CDN, then run the installer:

**macOS / Linux**

```bash
curl -L https://downloads.no8.io/main/releases/skills/insightark-skills-v2-latest.tar.gz \
  -o insightark-skills-v2-latest.tar.gz
tar -xzf insightark-skills-v2-latest.tar.gz
cd insightark-skills
./install.sh
./setup-env.sh
```

**Windows (PowerShell)**

```powershell
Invoke-WebRequest -Uri "https://downloads.no8.io/main/releases/skills/insightark-skills-v2-latest.tar.gz" `
  -OutFile "insightark-skills-v2-latest.tar.gz"
tar -xzf insightark-skills-v2-latest.tar.gz
cd insightark-skills
./install.sh
./setup-env.sh
```

> Staging channel: replace `main` with `staging` in the URL above.

---

## Manual Install

Clone or download from the [GitHub repository](https://github.com/8-interactive/insightark-skills), then run:

```bash
./install.sh
./setup-env.sh
./setup-env.sh --check
```

### Config files

| Location         | Path                              | Contents                                      |
| ---------------- | --------------------------------- | --------------------------------------------- |
| Install registry | `~/.insightark.config`            | Skills install paths                          |
| Skills dir       | `{skills-target}/.insightark.env` | `S8_SESSION_TOKEN`, `S8_API_URL`, `S8_ORG_ID` |
| User (fallback)  | `~/.insightark.env`               | Fallback if install registry is missing       |
| Project override | `{project}/.insightark.env`       | Optional `S8_ORG_ID` / stage URL override     |

**Load order:** user file → skills install dir → project file → process environment.

### CLI options

```bash
./install.sh --base-dir ~ --agents claude-code,cursor,codex
./install.sh --target ~/.agents/skills   # shared folder, no per-agent subpaths
./uninstall.sh --base-dir ~ --agents claude-code,codex
```

---

## MCP Client Setup

The hosted InsightArk MCP server is available at:

| Environment | Endpoint |
| --- | --- |
| Production | `https://api-next.no8.io/mcp` |
| Staging | `https://stage-api-next.no8.io/mcp` |

MCP uses the same Developer `_SessionToken` as the Developer API. The organization must have Developer API enabled, and the token owner must be the organization owner or an InsightArk admin.

Client setup for Codex, Cursor, and Claude Code is documented in [MCP_CLIENT_SETUP.md](./MCP_CLIENT_SETUP.md).

---

## Skills

| Skill | Purpose |
| --- | --- |
| `insightark-session` | Validate the developer session, list manageable organizations, and inspect credit usage. |
| `insightark-conversations` | Triage conversation inboxes by platform, inbox state, customer, or activity time. |
| `insightark-investigator` | Deep-dive into conversations and messages for investigation or debugging. |
| `insightark-customer-manager` | Search customers, inspect profiles, update supported fields, and manage tags. |
| `insightark-messaging` | Compose, preview, optionally upload media, and send 1:1 customer messages. |
| `insightark-broadcast-manager` | Preview, create, list, and inspect broadcast tasks. |
| `insightark-ma-automation` | Validate, create, start, pause, inspect, and trigger Marketing Automation procedures. |

**Typical flow:** `insightark-session` → a workflow skill for the task → preview/approval before any write operation.

---

<a name="中文"></a>

**SUPER 8 Studio InsightArk Skills** 是適用於 Claude Code、Codex 與 Cursor 的 Plugin，將 [Super 8 Studio](https://www.no8.io) Developer API 直接整合進 AI Agent 工作流程。

內含一組涵蓋完整 CRM 生命週期的可重用 Skills，包括對話調查、客戶管理、廣播發送與行銷自動化。安裝後，Agent 可在不離開對話介面的情況下查詢收件匣、更新客戶資料、撰寫訊息並觸發行銷活動。

憑證管理方面，Claude Code 透過平台原生系統鑰匙圈安全儲存，Codex 則透過環境設定檔管理。內建健康檢查會在每次 session 開始時自動執行，提早偵測憑證問題。

## Plugin 安裝（Claude Code）

### 1. 加入 Marketplace 並安裝

```bash
claude plugin marketplace add 8-interactive/insightark-skills
claude plugin install insightark-skills@insightark-skills
```

> **內部 staging 測試：** 指定 marketplace catalog 的 `staging` branch：
> `claude plugin marketplace add 8-interactive/insightark-skills@staging`

安裝過程中，Claude Code 僅會提示輸入 Developer API session token。Hosted MCP endpoint 已在發佈時寫入 plugin（production / staging 依 channel 而定）。

| 變數               | 說明                                          |
| ------------------ | --------------------------------------------- |
| `S8_SESSION_TOKEN` | Developer `_SessionToken`（儲存於系統鑰匙圈） |

安裝後執行 `claude plugin details insightark-skills@insightark-skills`，確認 **MCP servers ≥ 1**（`insightark` 指向 hosted HTTP URL）。

### 2. 啟用 Plugin

預設為停用狀態（因需連線至外部 API）：

```bash
claude plugin enable insightark-skills@insightark-skills
```

`SessionStart` hook 會在每次 session 開始時自動執行 `doctor.sh`，讓憑證問題提早浮現。

### Session Token 取得方式

1. Console → **Account Settings → Developer API**
2. 建立 Token（**僅顯示一次**）

Token 有效期六個月，請勿提交至版本控制或在對話中分享。

---

## Plugin 安裝（Codex）

### 1. 加入 Marketplace 並安裝

```bash
codex plugin marketplace add 8-interactive/insightark-skills
codex plugin install insightark-skills@insightark-skills
```

### 2. 設定憑證

Codex plugin 透過 `.mcp.json` 內建 hosted MCP，安裝時會提示 `S8_SESSION_TOKEN`。

若你的 Codex 版本無法正確套用 plugin MCP token，請執行 `setup-env.sh` 寫入 `~/.insightark.env`，並可選擇合併 client MCP 設定：

```bash
./setup-env.sh
./setup-env.sh --session-token "r:..." --write-client-configs
```

| 變數               | 說明                                         |
| ------------------ | -------------------------------------------- |
| `S8_SESSION_TOKEN` | Developer `_SessionToken`                    |
| `S8_API_URL`       | 僅於 `.insightark.env` 可選覆寫（預設 URL 依 release channel） |

### Session Token 取得方式

1. Console → **Account Settings → Developer API**
2. 建立 Token（**僅顯示一次**）

Token 有效期六個月，請勿提交至版本控制或在對話中分享。

---

## Plugin 安裝（Cursor）

### 1. 從 GitHub mirror 或本機 checkout 安裝

從 [GitHub mirror](https://github.com/8-interactive/insightark-skills) 以 **Cursor → Settings → Plugins → Install from local repo** 安裝，或 clone 後指向該目錄。

### 2. 設定憑證與 MCP

安裝後執行 `setup-env.sh`。加上 `--write-client-configs` 可將 `mcpServers.insightark` 寫入 `~/.cursor/mcp.json`（含 baked URL 與 token）：

```bash
./setup-env.sh
./setup-env.sh --session-token "r:..." --write-client-configs
```

於 **Cursor Settings → MCP** 確認 `insightark` 已連線。

---

## Tarball 安裝

從 CDN 直接下載最新發佈版，解壓後執行安裝程式：

**macOS / Linux**

```bash
curl -L https://downloads.no8.io/main/releases/skills/insightark-skills-v2-latest.tar.gz \
  -o insightark-skills-v2-latest.tar.gz
tar -xzf insightark-skills-v2-latest.tar.gz
cd insightark-skills
./install.sh
./setup-env.sh
```

**Windows（PowerShell）**

```powershell
Invoke-WebRequest -Uri "https://downloads.no8.io/main/releases/skills/insightark-skills-v2-latest.tar.gz" `
  -OutFile "insightark-skills-v2-latest.tar.gz"
tar -xzf insightark-skills-v2-latest.tar.gz
cd insightark-skills
./install.sh
./setup-env.sh
```

> Staging channel：將上方 URL 中的 `main` 替換為 `staging` 即可。

---

## 手動安裝

從 [GitHub repository](https://github.com/8-interactive/insightark-skills) Clone 或下載後執行：

```bash
./install.sh
./setup-env.sh
./setup-env.sh --check
```

### 設定檔說明

| 位置           | 路徑                              | 內容                                          |
| -------------- | --------------------------------- | --------------------------------------------- |
| 安裝登錄檔     | `~/.insightark.config`            | Skills 安裝路徑                               |
| Skills 目錄    | `{skills-target}/.insightark.env` | `S8_SESSION_TOKEN`、`S8_API_URL`、`S8_ORG_ID` |
| 使用者（備援） | `~/.insightark.env`               | 找不到安裝登錄檔時的備援                      |
| 專案覆蓋       | `{project}/.insightark.env`       | 可選的 `S8_ORG_ID` 或測試環境 URL             |

**載入順序：** 使用者檔案 → Skills 安裝目錄 → 專案檔案 → Process 環境變數（最高優先）。

### CLI 選項

```bash
./install.sh --base-dir ~ --agents claude-code,cursor,codex
./install.sh --target ~/.agents/skills   # 共用資料夾，不使用各 agent 子目錄
./uninstall.sh --base-dir ~ --agents claude-code,codex
```

---

## MCP Client 設定

Hosted InsightArk MCP server 位於：

| 環境 | Endpoint |
| --- | --- |
| Production | `https://api-next.no8.io/mcp` |
| Staging | `https://stage-api-next.no8.io/mcp` |

MCP 使用與 Developer API 相同的 Developer `_SessionToken`。組織必須啟用 Developer API，且 token 所屬使用者必須是該組織 owner 或 InsightArk admin。

Codex、Cursor、Claude Code 的設定方式請見 [MCP_CLIENT_SETUP.md](./MCP_CLIENT_SETUP.md)。

---

## Skills 列表

| Skill | 用途 |
| --- | --- |
| `insightark-session` | 驗證 developer session、列出可管理組織、查看 credits。 |
| `insightark-conversations` | 依平台、收件匣狀態、客戶或活動時間整理 conversation inbox。 |
| `insightark-investigator` | 深入查詢對話與訊息，用於調查與除錯。 |
| `insightark-customer-manager` | 搜尋客戶、查看 profile、更新支援欄位、加減 tags。 |
| `insightark-messaging` | 編寫、預覽、必要時上傳 media，並傳送 1:1 customer message。 |
| `insightark-broadcast-manager` | 預覽、建立、列出與查詢 broadcast task。 |
| `insightark-ma-automation` | 驗證、建立、啟動、暫停、查詢與 trigger Marketing Automation procedure。 |

**典型流程：** `insightark-session` → 依任務選擇 workflow skill → 寫入前先 preview / approval。
