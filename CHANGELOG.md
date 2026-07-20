# Changelog

## 2.2.0 — MCP schema contract hardening (skills)

- Message search skills use `senderTypes` only (singular `senderType` removed); document all five published sender classes.
- Broadcast / customer / conversations skills add situational notes for closed params; exact enums defer to MCP schema.
- Clarify multi-class search as one tool call / one normal 20-credit charge vs two searches.

## 2.1.0 — First supported marketplace + OAuth release

- Deliver Claude Code, Cursor, and Codex/ChatGPT desktop plugins with host-specific static OAuth MCP manifests.
- Production customer path is approved marketplace install → host OAuth Connect → `auth_me`.
- Remove manual skill-copy installer surface, SessionToken setup, shell API runtime, and empty hooks packaging.
- Keep `skills/_insightark-shared/` metadata-only (`RELEASE`, `VERSION`).
- Move LINE template guidelines and examples under `insightark-messaging/references/` for MCP workflows.
- Point Cursor plugin `logo` at `assets/logo.png` (same brand asset as Codex).
- Ship Chinese starter `commands/` aligned with Codex `interface.defaultPrompt` for Cursor and Claude Code.
- Pin Cursor plugin `mcpServers` to `./mcp.json` so static `auth.CLIENT_ID` is used instead of Claude `.mcp.json` / DCR fallback.
