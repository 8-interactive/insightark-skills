# Deprecated HTTP fallback scripts

These `.sh` helpers previously called `/developer/v1/*`. That HTTP surface is
removed; live skills are MCP-only (`allowed-mcp: true`).

Keep this directory only as a temporary compatibility stub for older local
installs / `runScript` callers. Do not add new `/developer/v1` usage. Prefer
hosted MCP tools documented in each skill's `SKILL.md`.
