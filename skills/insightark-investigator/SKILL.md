---
name: insightark-investigator
description: Investigate conversations and messages through InsightArk MCP using read-only tools.
when_to_use: When a user asks a natural language investigation question that may require session validation, organization scoping, conversation discovery, conversation inspection, or message search.
allowed-mcp: true
---

# Skill: insightark-investigator

This skill uses the InsightArk MCP server. Authentication uses `_SessionToken`. Every org-scoped tool requires an `orgId` argument. This skill is read-only — no write MCP tools.

## MCP Tools

- `auth_me` — validate session (no `orgId` required)
- `auth_organizations` — list manageable organizations (no `orgId` required)
- `messaging_conversation_list` — browse conversations
- `messaging_conversation_get` — get one conversation summary
- `messaging_conversation_messages` — read message timeline
- `messaging_message_search` — keyword-driven message search

## Workflow

1. Call `auth_me` or `auth_organizations` when the caller's session context is not yet trusted.
2. Resolve `orgId` before any org-scoped tool.
3. Choose one operational path:
   - `messaging_conversation_list` for discovery and pagination
   - `messaging_conversation_get` and `messaging_conversation_messages` for one conversation and its timeline
   - `messaging_message_search` for keyword-oriented evidence lookup
4. Return a concise read-only investigation result grounded in the public API response.

## Guardrails

- Do not call write endpoints (`messaging_customer_send_message`, `broadcast_create`, CRM mutations, MA mutations).
- Do not collect credentials or attempt login bootstrap.
- Do not depend on repository-local code or hidden internal fields.
