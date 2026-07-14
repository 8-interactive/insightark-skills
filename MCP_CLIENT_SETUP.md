# InsightArk MCP Client Setup

This guide connects an AI agent to the hosted InsightArk MCP server.

The MCP server is hosted by Super 8 Studio. Customers do not install a server locally; they configure their MCP client to call the hosted endpoint.

**Auth (preferred when OAuth is enabled on the server):** OAuth 2.1 + PKCE browser login with static client ids (`insightark-cursor`, `insightark-claude-code`, `insightark-codex`).
**Auth (fallback / always supported):** InsightArk MCP `_SessionToken` from Console.

**Plugin-first (v2.0.2+):** Claude Code, Codex, and Cursor plugins ship workflow skills plus baked MCP manifests.

| Host | MCP manifest | Primary auth |
| --- | --- | --- |
| Claude Code | root `.mcp.json` | `S8_SESSION_TOKEN` / `_SessionToken` |
| Codex / ChatGPT desktop | `.codex-plugin/mcp.json` (plugin `mcpServers: ./mcp.json`) | OAuth `client_id=insightark-codex` |
| Cursor | root `mcp.json` | `_SessionToken` (OAuth bake deferred) |

**Codex minimum:** CLI / ChatGPT desktop Codex **≥ 0.144.2** for plugin-baked `oauth.client_id`.

**Important:** Installing a plugin does **not** always auto-open OAuth Connect (especially ChatGPT desktop). After install you may still need in-app Connect or `codex mcp login insightark`. Do not invent a second `mcp add` if the plugin already registered `insightark`.

**Duplicate registration:** If both a plugin OAuth `insightark` and a legacy SessionToken / manual `mcp_servers.insightark` exist, prefer OAuth and remove or disable the duplicate. `doctor.sh` warns when both modes are present under `CODEX_HOME`.

## Access Requirements

MCP uses the InsightArk MCP access model (owner/admin identity + org scope).

- The organization must have InsightArk MCP enabled.
- The authenticated user must be the organization owner or an InsightArk admin.
- For token paste: create a token from Console → Account Settings → InsightArk MCP.
- Every org-scoped tool call must include `orgId`.
- MCP uses the org InsightArk MCP monthly credit and RPM quota.

Tokens are shown once when created. Do not commit tokens or paste them into shared chats.

## OAuth (when `insightark_mcp.oauth.enabled=true`)

Discovery:

| Document | Path |
| --- | --- |
| Protected Resource Metadata | `/.well-known/oauth-protected-resource` |
| Authorization Server Metadata | `/.well-known/oauth-authorization-server` |

All MCP OAuth endpoints live under `/mcp/oauth/*` (`authorize`, `handoff/*`, `token`, `revoke`) so they coexist with Super8's OIDC IdP mount under `/oauth`. Clients must use discovery metadata (or plugin-baked URLs), not hard-coded paths.

Static clients (no Dynamic Client Registration in MVP):

| Client | `client_id` | Primary redirect notes |
| --- | --- | --- |
| Cursor | `insightark-cursor` | `http://localhost:8787/callback`, Cursor Agents callback, legacy `cursor://…` |
| Claude Code | `insightark-claude-code` | Prefer `--callback-port 3118` → `http://localhost:3118/callback` |
| Codex | `insightark-codex` | **CLI (verified):** `codex://oauthandmcp/callback`; loopback `http://127.0.0.1:<port>/callback[/<id>]` / `http://localhost:<port>/callback[/<id>]` (`path_prefix`). **ChatGPT desktop App Connect:** capture the authorize `redirect_uri` during GUI E2E and confirm it is allowlisted before sign-off — do not assume CLI-only URIs cover App (see below). |

Scopes: `insightark-mcp:read`, `insightark-mcp:write` (request both for full agent use).

**SSO / Console sign-in:** Organizations with enforced SSO cannot use the API password form. The authorize page sets a short-lived HttpOnly handoff cookie and links to Console login with `redirect={api}/mcp/oauth/handoff/resume`. After Console SSO, the Console SPA **must** call `POST /mcp/oauth/handoff/bind` with the user's `_SessionToken` (and `credentials: 'include'` so the handoff cookie is sent) before redirecting the browser to `/mcp/oauth/handoff/resume`. Bound handoffs are consumed **only** on `/mcp/oauth/handoff/resume` (not on `/mcp/oauth/authorize`). Console allows only the build's `NEXT_API_URL` origin by default; local/stage extras via `VITE_MCP_OAUTH_HANDOFF_EXTRA_ORIGINS`. No `_SessionToken` or `user_id` is placed in URLs or HTML forms.

Residual risk: localhost callbacks can be abused by other local processes even with static `client_id`s; consent shows Super8-configured display names only.

### ChatGPT desktop redirect_uri gate

Before marking App GUI OAuth complete:

1. Start Connect from ChatGPT desktop for plugin-registered `insightark`.
2. Capture the authorize request’s exact `redirect_uri` query value(s).
3. Confirm each value matches `insightark-codex` `redirect_uris` or `redirect_uri_patterns` in server config; if not, update config + `mcp_oauth` redirect tests and redeploy staging.
4. Record verified App URI(s) here after measurement:

| Source | `redirect_uri` | Status |
| --- | --- | --- |
| Codex CLI | `codex://oauthandmcp/callback` | Verified |
| Codex CLI loopback | `http://127.0.0.1:<port>/callback[/<id>]` | Verified (path_prefix) |
| ChatGPT desktop Connect | _(pending GUI capture)_ | **Blocking for GUI sign-off** |

Desktop Connect variance: Install with `policy.authentication: ON_INSTALL` may still defer the browser until Connect / first tool use — document the actual UI label during staging GUI E2E.

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

## Codex / ChatGPT desktop (plugin-first, OAuth)

Install from marketplace (see `README.md`). The Codex plugin points at **`.codex-plugin/mcp.json`** (not Claude’s root `.mcp.json`) with the channel-baked MCP URL and:

```json
"oauth": { "client_id": "insightark-codex" }
```

Happy path:

1. Install plugin (App Plugins or `codex plugin add`).
2. Complete Connect / Sign in, **or** `codex mcp login insightark` if Connect did not start.
3. Smoke `auth_me` — **without** a new `codex mcp add --oauth-client-id …` when the plugin already registered the server.

**Clean-home validation tip:** prove marketplace wiring with a fresh `CODEX_HOME` so a leftover top-level `[mcp_servers.insightark]` from a prior manual `mcp add` cannot false-pass.

**Token fallback (optional):** If OAuth is unavailable, `./setup-env.sh --write-client-configs` can still upsert a SessionToken-based entry in `~/.codex/config.toml`. Prefer removing token-mode duplicates once OAuth works.

**Manual operator add** (not the customer happy path):

```bash
codex mcp add insightark --url https://api-next.no8.io/mcp --oauth-client-id insightark-codex
codex mcp login insightark
```

For staging, use `https://stage-api-next.no8.io/mcp`.

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
| Plugin installed but MCP missing | Claude: `claude plugin details`. Codex: confirm `.codex-plugin/mcp.json` OAuth bake + Connect / `codex mcp login insightark`. Cursor: `./setup-env.sh --write-client-configs`. |
| Codex tools fail / wrong auth | Remove duplicate `mcp_servers.insightark` (token vs OAuth). Prefer plugin OAuth registration. |
| ChatGPT desktop OAuth fails at callback | Capture authorize `redirect_uri`; ensure `insightark-codex` allowlist includes it (CLI success ≠ App URI). |
| Wrong environment URL | Staging marketplace/tarball bakes `stage-api-next`; production bakes `api-next`. |
