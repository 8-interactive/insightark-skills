# InsightArk MCP client setup

Production customers install the InsightArk plugin from an approved host marketplace, then complete host-managed MCP OAuth for the bundled `insightark` server.

## Shared flow

1. Install / enable the InsightArk plugin from the host marketplace.
2. Open the host MCP UI and Connect / Authenticate `insightark` (browser OAuth).
3. Validate with the `insightark-session` skill → MCP `auth_me`.

Customers do not add the MCP URL, paste a client id, create a SessionToken, or copy skills manually.

## Claude Code

- Static client: `insightark-claude-code`
- Manifest: root `.mcp.json` (`oauth.clientId`)
- Typical recovery: host Connect / Authenticate, or `/mcp` if your build exposes it

Minimum tested version: record during staging verification (task 4.3).

## Cursor

- Static client: `insightark-cursor`
- Manifest: root `mcp.json` (`auth.CLIENT_ID`)
- Plugin pin: `.cursor-plugin/plugin.json` must set `"mcpServers": "./mcp.json"` so Cursor does not load Claude's `.mcp.json` or fall back to DCR
- Typical path: Customize → Tools & MCP → Connect / Authenticate `insightark`

Minimum tested version: record during staging verification (task 4.3).

## Codex CLI

- Static client: `insightark-codex`
- Manifest: root `codex.mcp.json` (`oauth.client_id`), referenced by `.codex-plugin/plugin.json`
- Marketplace policy may use `authentication: ON_INSTALL` where supported
- Recovery for an already registered server: `codex mcp login insightark`

## ChatGPT desktop (Codex plugin)

- Same static client and manifest as Codex CLI
- Install and Connect through the ChatGPT desktop App / marketplace UI
- Final acceptance uses the App UI, not Codex CLI

## Auth recovery

If `auth_me` fails because credentials are missing, expired, cleared, or revoked:

1. Use the host Connect / Authenticate / Re-authenticate action (or Codex `codex mcp login insightark`).
2. Retry `insightark-session` → `auth_me`.

Do not treat network, timeout, MCP-unavailable, or `5xx` failures as OAuth recovery cases.

## Remove vs logout vs revoke

| Action | Owner |
|---|---|
| Remove plugin | Host marketplace / plugin manager |
| Clear local OAuth | Host logout / clear-auth |
| Revoke server tokens | SUPER 8 Console → Connected Apps |

---

# InsightArk MCP 用戶端設定（中文）

正式顧客從核准的 host marketplace 安裝 InsightArk plugin，再對 bundled `insightark` MCP 完成 host 管理的 OAuth。

## 共用流程

1. 從 marketplace 安裝 / 啟用 plugin。
2. 在 host MCP UI Connect / Authenticate `insightark`（瀏覽器 OAuth）。
3. 以 `insightark-session` → MCP `auth_me` 驗證。

顧客不需手動新增 MCP URL、貼上 client id、建立 SessionToken，或手動複製 skills。

## 認證復原

若因憑證缺失、過期、清除或撤銷導致 `auth_me` 失敗，使用 host 的 Connect / Authenticate / Re-authenticate（Codex 可用 `codex mcp login insightark`），然後重試。網路、逾時、MCP 不可用或 `5xx` 不應當成 OAuth 復原情境。
