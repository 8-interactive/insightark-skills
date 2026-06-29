---
name: super8-studio-customer-manager
description: Investigate and operate on customers through the SUPER 8 Studio Developer API using session validation, org scoping, customer lookup, profile update, and tag mutation skills.
when_to_use: When a user wants one customer-oriented workflow that can validate API readiness, resolve organization scope, search customers, inspect one customer, update supported public fields, or add and remove customer tags.
allowed-mcp: false
---

# Skill: super8-studio-customer-manager

This skill operates on the SUPER 8 Studio Developer API.

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