---
name: super8-studio-investigator
description: Investigate conversations and messages through the SUPER 8 Studio Developer API using S8_API_URL and S8_SESSION_TOKEN.
when_to_use: When a user asks a natural language investigation question that may require session validation, organization scoping, conversation discovery, conversation inspection, or message search.
allowed-mcp: false
---

# Skill: super8-studio-investigator

This skill operates on the SUPER 8 Studio Developer API.

## Composed skills

- `super8-studio-session`
- `super8-studio-org-scope`
- `super8-studio-conversations`
- `super8-studio-conversation-detail`
- `super8-studio-message-search`

## Workflow

1. Validate runtime readiness with `super8-studio-session` when the caller's API context is not yet trusted.
2. Resolve organization context with `super8-studio-org-scope` before any org-scoped route.
3. Choose one operational path:
   - `super8-studio-conversations` for discovery and pagination
   - `super8-studio-conversation-detail` for one conversation and its timeline
   - `super8-studio-message-search` for keyword-oriented evidence lookup
4. Return a concise read-only investigation result grounded in the public API response.

## Guardrails

- Do not call write endpoints.
- Do not collect credentials or attempt login bootstrap.
- Do not depend on repository-local code or hidden internal fields.
