---
name: super8-studio-broadcast-manager
description: Investigate and operate on broadcast tasks through the Super 8 Studio Developer API using session validation, org scoping, broadcast creation, broadcast inspection, and broadcast listing.
when_to_use: When a user wants a single broadcast-oriented workflow that can validate API readiness, resolve organization scope, launch a broadcast, inspect one broadcast's progress, or browse recent broadcasts.
allowed-mcp: false
license: MIT
metadata:
  owner: platform
  version: "1.0.0"
  category: agent-orchestrator
  domain: super8-studio
---

# Skill: super8-studio-broadcast-manager

This skill operates on the Super 8 Studio Developer API.

## Composed skills

- `super8-studio-session`
- `super8-studio-org-scope`
- `super8-studio-broadcast-create`
- `super8-studio-broadcast-get`
- `super8-studio-broadcast-list`

> Phase 2 will extend this composer with `super8-studio-broadcast-cancel` and `super8-studio-broadcast-clone` when the matching API endpoints ship.

## Workflow

1. Validate runtime readiness with `super8-studio-session` when the caller's API context is not yet trusted.
2. Resolve organization context with `super8-studio-org-scope` before any org-scoped broadcast route.
3. Choose one operational path:
   - `super8-studio-broadcast-create` to launch a new broadcast with explicit recipients and message content
   - `super8-studio-broadcast-get` to poll one broadcast's status and progress counts; surface `options.customerNum` as the audience-size snapshot taken at creation time so the operator can compare it against the running `success` / `fail` totals
   - `super8-studio-broadcast-list` to browse recent broadcasts, optionally filtered by status
4. Return the result grounded in the public developer API response.

## Example requests

- `Use super8-studio-broadcast-manager to launch a LINE broadcast in org org_demo_001 sending the text "Hello <%=name%>, sale starts now" to customers cus_123 and cus_456.`
- `Use super8-studio-broadcast-manager to schedule a Facebook broadcast in org org_demo_001 for 2026-05-12T09:00:00Z with the image https://cdn.example.com/promo.jpg to the customers in where-file ./vip.json.`
- `Use super8-studio-broadcast-manager to show the status of broadcast 65f0c8a1b2c3d4e5f6a7b8c9 in org org_demo_001.`
- `Use super8-studio-broadcast-manager to list the last 20 broadcasts in org org_demo_001 with status working or scheduled.`

## Guardrails

- Treat `super8-studio-broadcast-create` as a write operation that affects many real recipients at scale and incurs real platform cost.
- A single broadcast task targets exactly one platform (`line`, `facebook`, `instagram`, or `whatsapp`). If the requested audience spans multiple platforms, split the dispatch into one broadcast per platform; the API rejects mixed-platform recipient lists.
- Do not perform a create unless the target organization, platform, recipient input, and message content are explicit.
- Do not infer the platform from ambiguous user input; confirm when the recipient list could plausibly span more than one channel.
- Do not infer customer ids or message content from ambiguous user input; confirm before dispatching if any field had to be inferred.
- Read operations (list, get) must stay within the published developer broadcast schema and only forward explicit user inputs.

## When not to use

- A single leaf skill directly satisfies the request.
- Required identifiers, target customer, audience, or message content are ambiguous.
- The user asks for an operation outside this orchestrator's domain.

## Inputs

- Natural-language user intent.
- Valid `S8_API_URL`, `S8_SESSION_TOKEN`, and org context where required.
- Explicit identifiers and payload details before any write operation.

## Outputs

- The selected composed skill output, returned without fabricating or transforming API results.

## Failure handling

- Validate session and org context before operational paths.
- Surface sub-skill errors directly and stop when prerequisites fail.
- Require explicit confirmation before write actions and never retry writes silently.

## Observability

- Record selected sub-skill, user intent, target identifiers, and HTTP status while avoiding PII and full message bodies.
