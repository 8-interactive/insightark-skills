---
name: super8-studio-customer-manager
description: Investigate and operate on customers through the Super 8 Studio Developer API using session validation, org scoping, customer lookup, profile update, and tag mutation skills.
when_to_use: When a user wants one customer-oriented workflow that can validate API readiness, resolve organization scope, search customers, inspect one customer, update supported public fields, or add and remove customer tags.
allowed-mcp: false
license: MIT
metadata:
  owner: platform
  version: "1.0.0"
  category: agent-orchestrator
  domain: super8-studio
---

# Skill: super8-studio-customer-manager

This skill operates on the Super 8 Studio Developer API.

## Composed skills

- `super8-studio-session`
- `super8-studio-org-scope`
- `super8-studio-customer-search`
- `super8-studio-customer-detail`
- `super8-studio-customer-update`
- `super8-studio-customer-tag-add`
- `super8-studio-customer-tag-remove`

## Workflow

1. Validate runtime readiness with `super8-studio-session` when the caller's API context is not yet trusted.
2. Resolve organization context with `super8-studio-org-scope` before any org-scoped customer route.
3. Choose one operational path:
   - `super8-studio-customer-search` for discovery, filtering, and pagination
   - `super8-studio-customer-detail` for one customer record
   - `super8-studio-customer-update` for supported public profile changes
   - `super8-studio-customer-tag-add` to append one or more tags
   - `super8-studio-customer-tag-remove` to remove one or more tags
4. Return the result grounded in the public developer API response.

## Example requests

- `Use super8-studio-customer-manager to find customers in org org_demo_001 whose display name contains "Amy", include tag "vip", and return the first 20 results.`
- `Use super8-studio-customer-manager to show the customer detail for customer cus_123 in org org_demo_001.`
- `Use super8-studio-customer-manager to update customer cus_123 in org org_demo_001 with email "amy@example.com" and language "zh-TW".`
- `Use super8-studio-customer-manager to add tags "vip" and "newsletter" to customer cus_123 in org org_demo_001.`
- `Use super8-studio-customer-manager to remove tag "inactive" from customer cus_123 in org org_demo_001.`

## Guardrails

- Treat update and tag operations as explicit write actions.
- Do not perform a write unless the target customer id and intended field or tag changes are explicit.
- Stay within the published public customer schema and developer API routes.

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
