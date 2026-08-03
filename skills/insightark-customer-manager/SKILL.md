---
name: insightark-customer-manager
description: Investigate and operate on customers through InsightArk MCP — session validation, org scoping, customer lookup, profile update, and tag mutation.
when_to_use: When a user wants one customer-oriented workflow that can validate MCP readiness, resolve organization scope, search customers, inspect one customer, update supported public fields, or add and remove customer tags.
allowed-mcp: true
---

# Skill: insightark-customer-manager

**Prerequisite:** Read `skills/insightark-universal-workflow/SKILL.md` before operational work or domain references.

This skill uses the InsightArk MCP server. Authentication is managed by your host through MCP OAuth (Connect / Authenticate). Every org-scoped tool requires an `orgId` argument. Write operations need explicit user confirmation before calling.

## MCP Tools

- `auth_me` — validate session (no `orgId` required)
- `auth_organizations` — list manageable organizations (no `orgId` required)
- `crm_customer_get` — get one customer by id
- `crm_customer_search` — search customers with public filters
- `crm_tag_list` — discover organization tag inventory and rough holder counts
- `crm_customer_group_list`, `crm_customer_group_get`, `crm_customer_group_members_list` — inspect saved group snapshots
- `crm_customer_group_rename`, `crm_customer_group_delete` — rename or soft-delete customer groups (confirm first)
- `crm_customer_update` — patch supported profile fields
- `crm_customer_tag_add` — add tags to a customer
- `crm_customer_tag_remove` — remove tags from a customer

## Workflow

1. Call `auth_me` or `auth_organizations` when the caller's session context is not yet trusted.
2. Resolve `orgId` before any org-scoped customer tool.
3. Choose one operational path:
   - `crm_tag_list` to discover tag names (optionally by literal `nameContains`) before searching or mutating when exact names are unknown; it returns Console-aligned `name`, `count`, `density`, and `lastUsed` when available
   - `crm_customer_search` to list customers matching known tags, other public filters, and pagination; do not use it to browse the organization tag catalog
   - `crm_customer_get` for one customer record
   - `crm_customer_update` for supported public profile changes (confirm first)
   - `crm_customer_tag_add` to append one or more tags (confirm first)
   - `crm_customer_tag_remove` to remove one or more tags (confirm first)
4. Return the result grounded in the published MCP / public customer schema response.

## `crm_customer_search` name routing

- Ordinary “find by name” requests: pass `displayName` and **omit** `displayNameMatch`.
- Treat name-search results as candidate matches, not a uniquely identified customer.
- Phone or email lookup: use `cellPhone` or `email`.
- Explicit partial-name / name-fragment / broader-match requests: pass `displayNameMatch: "contains"`.
- If default text search returns no customers and the user still expects a match: disclose that a contains retry is a broader **additional 15-credit** read, obtain approval, then call again with `displayNameMatch: "contains"`. Never silently substitute contains after an empty text result.
- Do not send `displayNameMatch` without a non-empty name-shaped `displayName`.

## Example requests

- `Use insightark-customer-manager to find the customer named "Amy Chen" in org org_demo_001.`
- `Use insightark-customer-manager to find customers in org org_demo_001 whose display name contains "Amy", include tag "vip", and return the first 20 results.`
- `Use insightark-customer-manager to show the customer detail for customer cus_123 in org org_demo_001.`
- `Use insightark-customer-manager to update customer cus_123 in org org_demo_001 with email "amy@example.com" and language "zh-TW".`
- `Use insightark-customer-manager to add tags "vip" and "newsletter" to customer cus_123 in org org_demo_001.`
- `Use insightark-customer-manager to remove tag "inactive" from customer cus_123 in org org_demo_001.`

## Constrained `customerInfo` (situational)

Exact editable fields and enum values come from the `crm_customer_update` MCP tool schema description.

- Patch only published public fields (displayName, cellPhone, email, birthday, gender, language, …).
- `gender` / `language` must match the schema allowlists when set.
- `email` must be a valid email; `birthday` must be ISO 8601.
- Unsupported or empty patches fail before credit charge — fix args rather than retrying identical payloads.

## Guardrails

- Treat update and tag operations as explicit write actions.
- Do not perform a write unless the target customer id and intended field or tag changes are explicit.
- Stay within the published public customer schema and InsightArk MCP tools.
- Do not invent organization-level tag write tools. `crm_tag_list` is read-only inventory discovery.
- Customer groups are `custom` or Console-defined `query` groups. MCP does not create or refresh groups; use Console for those operations and CSV import/export. Query counts and member pages are materialized snapshots; `updatedAt` is a mutable group record timestamp, not a materialization clock.
- Before rename or soft-delete, present the target and effect and obtain explicit confirmation.
- Group membership does not prove broadcast eligibility. Use `broadcast_audience_preview` before a group-targeted broadcast.
- If authentication is missing, expired, revoked, or the host reports `401` / `403` / authentication-required, hand off to `insightark-session` for host OAuth recovery before retrying. Do not treat network/timeout/`5xx` failures as OAuth problems.
