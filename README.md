# SUPER 8 Studio InsightArk Skills

InsightArk workflow skills plus a bundled hosted MCP server for SUPER 8 Studio CRM operations.

**Production customer path:** install the plugin from an approved host marketplace → Connect the bundled `insightark` MCP server through host OAuth → validate with `insightark-session` (`auth_me`) → use skills via MCP tools.

Version `2.2.0` is the first supported marketplace + OAuth release.

## Quick start

1. Install the InsightArk plugin from your host marketplace (Claude Code, Cursor, or Codex / ChatGPT desktop).
2. Connect / Authenticate the bundled `insightark` MCP server when prompted (browser OAuth).
3. Ask your agent to use the `insightark-session` skill, which calls MCP `auth_me` to confirm setup.

See [MCP_CLIENT_SETUP.md](./MCP_CLIENT_SETUP.md) for host-specific Connect labels and recovery.

## Host overview

| Host | Plugin manifest | Static OAuth client | MCP manifest |
|---|---|---|---|
| Claude Code | `.claude-plugin/plugin.json` | `insightark-claude-code` | root `.mcp.json` (`oauth.clientId`) |
| Cursor | `.cursor-plugin/plugin.json` | `insightark-cursor` | root `mcp.json` (`auth.CLIENT_ID`) |
| Codex CLI / ChatGPT desktop | `.codex-plugin/plugin.json` | `insightark-codex` | root `codex.mcp.json` (`oauth.client_id`) |

Release channels bake the MCP URL:

- Staging: `https://stage-api-next.no8.io/mcp`
- Production: `https://api-next.no8.io/mcp`

Customers do not type an API URL, client id, or SessionToken during plugin setup.

## Validate setup

Use the `insightark-session` skill (MCP `auth_me`). If the host reports that MCP needs authentication, use the host's Connect / Re-authenticate action.

## Remove, logout, and revoke

These are separate actions:

| Action | What it does |
|---|---|
| Marketplace plugin removal | Removes the plugin package from the host |
| Host logout / clear-auth | Clears host-local OAuth credentials for the MCP server |
| Console Connected Apps revocation | Revokes the server-side OAuth token family |

Plugin removal does not by itself revoke Console Connected Apps credentials unless your host also clears auth and you confirm that behavior for your client version.

## Skills included

- `insightark-session` — validate MCP auth and inspect identity/orgs/credits
- `insightark-investigator` — read-only conversation investigation
- `insightark-conversations` — list/get conversations and messages
- `insightark-customer-manager` — search/update customers and tags
- `insightark-messaging` — send and validate messages
- `insightark-broadcast-manager` — create and monitor broadcasts
- `insightark-ma-automation` — marketing automation procedures

## Requirements

- An InsightArk-eligible SUPER 8 Studio organization (owner or InsightArk admin for OAuth consent).
- Host versions that support packaged static MCP OAuth clients (see `MCP_CLIENT_SETUP.md`).

## Links

- [MCP client setup](./MCP_CLIENT_SETUP.md)
- [Security](./SECURITY.md)
- [Changelog](./CHANGELOG.md)

---

# SUPER 8 Studio InsightArk Skills（中文）

InsightArk 工作流 skills 與 bundled hosted MCP，用於 SUPER 8 Studio CRM 操作。

**正式顧客流程：** 從核准的 host marketplace 安裝 plugin → 透過 host OAuth Connect bundled `insightark` MCP → 以 `insightark-session`（`auth_me`）驗證 → 以 MCP tools 使用 skills。

`2.2.0` 是第一個支援的 marketplace + OAuth 正式版。

## 快速開始

1. 從 host marketplace 安裝 InsightArk plugin（Claude Code、Cursor，或 Codex / ChatGPT desktop）。
2. 依提示 Connect / Authenticate bundled `insightark` MCP（瀏覽器 OAuth）。
3. 請 agent 使用 `insightark-session` skill，以 MCP `auth_me` 確認設定。

主機細節與復原步驟見 [MCP_CLIENT_SETUP.md](./MCP_CLIENT_SETUP.md)。

## 驗證

使用 `insightark-session`（MCP `auth_me`）。若 host 回報需要認證，使用該 host 的 Connect / Re-authenticate。

## 移除、登出與撤銷

| 動作 | 效果 |
|---|---|
| Marketplace 移除 plugin | 從 host 移除套件 |
| Host logout / clear-auth | 清除該 MCP 的本機 OAuth 憑證 |
| Console Connected Apps 撤銷 | 撤銷伺服器端 OAuth token family |

移除 plugin 本身不會自動等同 Console Connected Apps 撤銷，除非你的 host 同時清掉本機 auth，且該版本行為已驗證。

## 需求

- 具備 InsightArk 資格的 SUPER 8 Studio 組織（OAuth 同意需 owner 或 InsightArk admin）。
- 支援 packaged static MCP OAuth client 的 host 版本（見 `MCP_CLIENT_SETUP.md`）。
