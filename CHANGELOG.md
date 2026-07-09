# Changelog

## 2.0.2

- Bundle hosted MCP with workflow skills for Claude Code, Codex, and Cursor plugins.
- Bake MCP endpoint URL per release channel (`staging` / `main`); remove `S8_API_URL` from Claude plugin `userConfig`.
- Add `setup-env.sh` client-config merge for `~/.cursor/mcp.json` and Codex `~/.codex/config.toml` fallback.
- Add packaging validators: `validate-release-tree.sh`, `validate-install-harness.sh`; reorder CI to generate MCP before validate.
- **Retire npm customer distribution** — remove `npx` CLI adapter; `package.json` is private dev tooling only and is excluded from the public mirror tree.

## 2.0.0

- Consolidate per-tool skills into 7 workflow-oriented MCP skills.
- Use the hosted InsightArk MCP server as the primary execution path.
- Add customer-facing MCP client setup guidance for Codex, Cursor, and Claude Code.
- Keep CDN/tarball distribution compatible with channel-specific releases.
- Align npm package name with GitHub distribution repo: `@8-interactive/insightark-skills`.

## 1.1.0

- Renamed all skills from `super8-studio-*` to `insightark-*`.
- npm package renamed from `@super8/studio-api-skills` to `@insightark/skills`, bin renamed to `insightark-skills`.
- Product rebranded to "SUPER 8 Studio InsightArk Skills".
- GitHub repo moved to `8-interactive/insightark-skills`.
- `docs/` excluded from npm publish and CDN tarball (dev-only content).

## 1.0.0

- Add canonical skill bundle installer for direct skills installation.
- Add shared runtime scripts for Super 8 Studio Developer API workflows.
- Add plugin, marketplace, npm, and validation metadata for multi-channel
  installation readiness.
