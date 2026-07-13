# InsightArk MCP Client Setup

This guide connects an AI agent to the hosted InsightArk MCP server.

The MCP server is hosted by Super 8 Studio. Customers do not install a server locally; they configure their MCP client to call the hosted endpoint with a InsightArk MCP `_SessionToken`.

**Plugin-first (v2.0.2+):** Claude Code, Codex, and Cursor plugins ship workflow skills plus baked MCP manifests (`.mcp.json` / `mcp.json`). Install the plugin, configure `S8_SESSION_TOKEN`, and confirm MCP is connected. Manual client config below is the **fallback** when plugin-native MCP wiring is unavailable.

## Access Requirements

MCP uses the InsightArk MCP access model (owner/admin token + org scope).

- The organization must have InsightArk MCP enabled.
- The token owner must be the organization owner or an InsightArk admin.
- The token must be created from Console -> Account Settings → InsightArk MCP.
- Every org-scoped tool call must include `orgId`.
- MCP uses the org InsightArk MCP monthly credit and RPM quota.

Tokens are shown once when created. Do not commit tokens or paste them into shared chats.

## Endpoints

| Environment | MCP endpoint |
| --- | --- |
| Production | `https://api-next.no8.io/mcp` |
| Staging | `https://stage-api-next.no8.io/mcp` |

Use production for customer installs. Use staging only for internal validation.

## Claude Code (plugin-first)

Install from marketplace (see `README.md`). The plugin bundles `.mcp.json` with the baked URL for your release channel. You only configure `S8_SESSION_TOKEN` during install.

Verify:

```bash
claude plugin details insightark-skills@insightark-skills
# MCP servers ≥ 1; insightark → https://…/mcp
```

If CLI install/enable did not prompt for a token, open Claude Code and run:

```text
/plugin configure insightark-skills@insightark-skills
```

Token source:

- Production Console: `https://console.no8.io` → Account Settings → InsightArk MCP → Create token
- Staging Console: `https://stage-console.no8.io` → Account Settings → InsightArk MCP → Create token

**Manual fallback** (if plugin MCP is not active):

```bash
claude mcp add insightark https://api-next.no8.io/mcp \
  --transport http \
  --header "_SessionToken: r:replace-with-insightark-mcp-token"
```

Start or restart Claude Code, then run `/mcp` and confirm `insightark` is connected.

To remove manual registration:

```bash
claude mcp remove insightark
```

For staging, replace the URL with `https://stage-api-next.no8.io/mcp`.

## Codex (plugin-first)

Install from marketplace. The Codex plugin references `./.mcp.json` with baked URL and `${user_config.S8_SESSION_TOKEN}` for the `_SessionToken` header.

If plugin MCP token substitution does not work on your Codex build, run from the plugin checkout:

```bash
./setup-env.sh --session-token "r:..." --write-client-configs
```

This upserts `mcp_servers.insightark` in `~/.codex/config.toml` while preserving unrelated servers and top-level settings.

**Manual fallback** — edit `~/.codex/config.toml` directly:

If your Codex build supports remote HTTP MCP directly, configure the hosted URL and `_SessionToken` header using the current Codex MCP schema. If it only supports stdio MCP servers, use `mcp-remote` as a bridge:

```toml
[mcp_servers.insightark]
command = "sh"
args = [
  "-lc",
  "npx -y mcp-remote https://api-next.no8.io/mcp --header \"_SessionToken: $S8_SESSION_TOKEN\""
]
startup_timeout_sec = 120

[mcp_servers.insightark.env]
S8_SESSION_TOKEN = "r:replace-with-insightark-mcp-token"
```

Restart Codex after editing the file. Then ask Codex to list or use the `insightark` MCP tools.

For staging, replace the URL with `https://stage-api-next.no8.io/mcp`.

## Cursor (plugin + setup-env)

Install the plugin from the GitHub mirror or a local checkout. Root `mcp.json` contains the baked hosted URL.

Run:

```bash
./setup-env.sh --write-client-configs
```

This merges `mcpServers.insightark` into `~/.cursor/mcp.json` (or use `--session-token` for non-interactive runs).

**Manual fallback** — use either:

- Project: `.cursor/mcp.json`
- User: `~/.cursor/mcp.json`

```json
{
  "mcpServers": {
    "insightark": {
      "url": "https://api-next.no8.io/mcp",
      "headers": {
        "_SessionToken": "r:replace-with-insightark-mcp-token"
      }
    }
  }
}
```

Restart Cursor or reload MCP servers, then open Cursor Settings -> MCP and confirm `insightark` is connected.

For staging, replace the URL with `https://stage-api-next.no8.io/mcp`.

## Smoke Test

Public InsightArk MCP tool names use lowercase snake_case only (for example `credits_usage`, `messaging_conversation_list`). Legacy dotted names such as `credits.usage` are not accepted.

After connecting, ask the client to call:

1. `auth_me`
2. `auth_organizations`
3. `credits_usage` with a known `orgId`

Expected result:

- `auth_me` returns the developer user.
- `auth_organizations` includes the target organization with InsightArk MCP enabled.
- `credits_usage` returns the current InsightArk MCP credit snapshot.

If org-scoped tools fail, confirm the token owner is the org owner or an InsightArk admin and that InsightArk MCP is not disabled for that organization.

## Skills and MCP Together

Install the InsightArk skills bundle when you want workflow guidance in the agent. Configure MCP when you want the agent to execute tools through the hosted MCP server.

The skills are intentionally workflow-level. They guide the agent through real tasks such as customer management, messaging, broadcast, and marketing automation. The MCP tools remain lower-level so permissions, quota, audit logs, and tool composition stay precise.

Current workflow skills:

- `insightark-session`
- `insightark-conversations`
- `insightark-investigator`
- `insightark-customer-manager`
- `insightark-messaging`
- `insightark-broadcast-manager`
- `insightark-ma-automation`

## Troubleshooting

| Symptom | Likely cause / fix |
| --- | --- |
| `401` or invalid session | Token is missing, expired, or invalid. Create a new InsightArk MCP token. |
| Organization access denied | The token owner is not owner/admin for the requested `orgId`. |
| InsightArk MCP disabled for the organization | Enable InsightArk MCP for the organization before using MCP. |
| Rate limit exceeded | MCP quota. Wait for refill or reduce request volume. |
| Tool exists but requires `orgId` | Pass `orgId` in every org-scoped tool call. |
| Plugin installed but MCP missing | Run `claude plugin details` (Claude) or `./setup-env.sh --write-client-configs` (Cursor/Codex fallback). |
| Wrong environment URL | Staging marketplace/tarball bakes `stage-api-next`; production bakes `api-next`. |
