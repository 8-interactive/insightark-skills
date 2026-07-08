# InsightArk MCP Client Setup

This guide connects an AI agent to the hosted InsightArk MCP server.

The MCP server is hosted by Super 8 Studio. Customers do not install a server locally; they configure their MCP client to call the hosted endpoint with a Developer API `_SessionToken`.

## Access Requirements

MCP uses the same access model as the Super 8 Studio Developer API.

- The organization must have Developer API enabled.
- The token owner must be the organization owner or an InsightArk admin.
- The token must be created from Console -> Account Settings -> Developer API.
- Every org-scoped tool call must include `orgId`.
- MCP and Developer API share the same per-org rate limit and credit quota.

Tokens are shown once when created. Do not commit tokens or paste them into shared chats.

## Endpoints

| Environment | MCP endpoint |
| --- | --- |
| Production | `https://api-next.no8.io/mcp` |
| Staging | `https://stage-api-next.no8.io/mcp` |

Use production for customer installs. Use staging only for internal validation.

## Codex

Codex MCP configuration lives in `~/.codex/config.toml`.

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
S8_SESSION_TOKEN = "r:replace-with-developer-session-token"
```

Restart Codex after editing the file. Then ask Codex to list or use the `insightark` MCP tools.

For staging, replace the URL with `https://stage-api-next.no8.io/mcp`.

## Cursor

Cursor supports project or user MCP configuration.

Use either:

- Project: `.cursor/mcp.json`
- User: `~/.cursor/mcp.json`

```json
{
  "mcpServers": {
    "insightark": {
      "url": "https://api-next.no8.io/mcp",
      "headers": {
        "_SessionToken": "r:replace-with-developer-session-token"
      }
    }
  }
}
```

Restart Cursor or reload MCP servers, then open Cursor Settings -> MCP and confirm `insightark` is connected.

For staging, replace the URL with `https://stage-api-next.no8.io/mcp`.

## Claude Code

Claude Code can register the hosted MCP server from the CLI:

```bash
claude mcp add insightark https://api-next.no8.io/mcp \
  --transport http \
  --header "_SessionToken: r:replace-with-developer-session-token"
```

Start or restart Claude Code, then run `/mcp` and confirm `insightark` is connected.

To remove it:

```bash
claude mcp remove insightark
```

For staging, replace the URL with `https://stage-api-next.no8.io/mcp`.

## Smoke Test

After connecting, ask the client to call:

1. `auth.me`
2. `auth.organizations`
3. `credits.usage` with a known `orgId`

Expected result:

- `auth.me` returns the developer user.
- `auth.organizations` includes the target organization with Developer API enabled.
- `credits.usage` returns the current Developer API credit snapshot.

If org-scoped tools fail, confirm the token owner is the org owner or an InsightArk admin and that Developer API is enabled for that organization.

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
| `401` or invalid session | Token is missing, expired, or invalid. Create a new Developer API token. |
| Organization access denied | The token owner is not owner/admin for the requested `orgId`. |
| Developer API not enabled | Enable Developer API for the organization before using MCP. |
| Rate limit exceeded | MCP and Developer API share quota. Wait for refill or reduce request volume. |
| Tool exists but requires `orgId` | Pass `orgId` in every org-scoped tool call. |
