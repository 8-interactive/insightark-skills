# Contributing

> Using an AI agent (Claude Code, Codex, Cursor, …) to make changes? Read
> [AGENTS.md](AGENTS.md) first. Core rule: **every edit must trace to the
> change's scope — never remove or modify adjacent code nobody asked you to
> touch.**

## Skill Layout

Canonical cross-agent skills live under `skills/`.

```text
skills/<skill-name>/SKILL.md
skills/_insightark-shared/scripts/
```

The underscore-prefixed shared directory is runtime support, not a
triggerable skill. Skill scripts are Node (`.js`) invoked as `node <path>`;
the installer (`install.sh`, `setup-env.sh`, `uninstall.sh`) and shared
support libraries (`skills/_insightark-shared/scripts/lib/*.sh`) are Bash.

## Workflow Skills

There are 7 workflow-oriented skills (`insightark-session`,
`insightark-investigator`, `insightark-customer-manager`,
`insightark-messaging`, `insightark-broadcast-manager`,
`insightark-conversations`, `insightark-ma-automation`). Each wraps a set of
related InsightArk Developer API operations behind the hosted MCP server.
Prefer extending an existing workflow skill over adding a new narrowly-scoped
one — the bundle intentionally consolidated per-endpoint skills into these 7.

- Shared Node helpers belong in `_insightark-shared/scripts/` (libs in
  `scripts/lib/`).
- Read/investigate operations should never require user confirmation.
  Write/outbound operations (send message, mutate customer, trigger
  broadcast/MA) must confirm intent first — see `SECURITY.md`.

## Before Opening a PR

```bash
npm run validate   # bash scripts/validate-skills.sh + node scripts/validate-mcp-skills.js
```

If your change touches MCP-facing behavior, also run the E2E harness (see
`docs/implementation/plugin-release-process.md`).

## Releasing

See `docs/implementation/plugin-release-process.md`.
