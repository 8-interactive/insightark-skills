---
name: insightark-customer-manager
description: Investigate and operate on customers through InsightArk MCP — session validation, org scoping, customer lookup, profile update, and tag mutation.
when_to_use: When a user wants one customer-oriented workflow that can validate MCP readiness, resolve organization scope, search customers, inspect one customer, update supported public fields, or add and remove customer tags.
allowed-mcp: true
---

# Skill: insightark-customer-manager

This skill uses the InsightArk MCP server. Authentication is managed by your host through MCP OAuth (Connect / Authenticate). Every org-scoped tool requires an `orgId` argument. Write operations need explicit user confirmation before calling.

## MCP Tools

- `auth_me` — validate session (no `orgId` required)
- `auth_organizations` — list manageable organizations (no `orgId` required)
- `crm_customer_get` — get one customer by id
- `crm_customer_search` — search customers with public filters
- `crm_customer_update` — patch supported profile fields
- `crm_customer_tag_add` — add tags to a customer
- `crm_customer_tag_remove` — remove tags from a customer

## Workflow

1. Call `auth_me` or `auth_organizations` when the caller's session context is not yet trusted.
2. Resolve `orgId` before any org-scoped customer tool.
3. Choose one operational path:
   - `crm_customer_search` for discovery, filtering, and pagination
   - `crm_customer_get` for one customer record
   - `crm_customer_update` for supported public profile changes (confirm first)
   - `crm_customer_tag_add` to append one or more tags (confirm first)
   - `crm_customer_tag_remove` to remove one or more tags (confirm first)
4. Return the result grounded in the public developer API response.

## Example requests

- `Use insightark-customer-manager to find customers in org org_demo_001 whose display name contains "Amy", include tag "vip", and return the first 20 results.`
- `Use insightark-customer-manager to show the customer detail for customer cus_123 in org org_demo_001.`
- `Use insightark-customer-manager to update customer cus_123 in org org_demo_001 with email "amy@example.com" and language "zh-TW".`
- `Use insightark-customer-manager to add tags "vip" and "newsletter" to customer cus_123 in org org_demo_001.`
- `Use insightark-customer-manager to remove tag "inactive" from customer cus_123 in org org_demo_001.`

## Guardrails

- Treat update and tag operations as explicit write actions.
- Do not perform a write unless the target customer id and intended field or tag changes are explicit.
- Stay within the published public customer schema and developer API routes.
- If authentication is missing, expired, revoked, or the host reports `401` / `403` / authentication-required, hand off to `insightark-session` for host OAuth recovery before retrying. Do not treat network/timeout/`5xx` failures as OAuth problems.
