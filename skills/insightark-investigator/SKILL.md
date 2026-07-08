---
name: insightark-investigator
description: Investigate conversations and messages through InsightArk MCP using read-only tools.
when_to_use: When a user asks a natural language investigation question that may require session validation, organization scoping, conversation discovery, conversation inspection, or message search.
allowed-mcp: true
---

# Skill: insightark-investigator

This skill uses the InsightArk MCP server. Authentication uses `_SessionToken`. Every org-scoped tool requires an `orgId` argument. This skill is read-only — no write MCP tools.

## MCP Tools

- `auth.me` — validate session (no `orgId` required)
- `auth.organizations` — list manageable organizations (no `orgId` required)
- `messaging.conversation.list` — browse conversations
- `messaging.conversation.get` — get one conversation summary
- `messaging.conversation.messages` — read message timeline
- `messaging.message.search` — keyword-driven message search

## Workflow

1. Call `auth.me` or `auth.organizations` when the caller's session context is not yet trusted.
2. Resolve `orgId` before any org-scoped tool.
3. Choose one operational path:
   - `messaging.conversation.list` for discovery and pagination
   - `messaging.conversation.get` and `messaging.conversation.messages` for one conversation and its timeline
   - `messaging.message.search` for keyword-oriented evidence lookup
4. Return a concise read-only investigation result grounded in the public API response.

## Guardrails

- Do not call write endpoints (`messaging.customer.sendMessage`, `broadcast.create`, CRM mutations, MA mutations).
- Do not collect credentials or attempt login bootstrap.
- Do not depend on repository-local code or hidden internal fields.
