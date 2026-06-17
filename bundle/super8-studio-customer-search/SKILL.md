---
name: super8-studio-customer-search
description: Operate on the Super 8 Studio Developer API to search organization-scoped customers with supported public filters.
when_to_use: When a user wants to find customers by customer id, display name, platform, tags, contact fields, or supported activity time windows.
allowed-mcp: false
---

# Skill: super8-studio-customer-search

This skill operates on the Super 8 Studio Developer API.

## Script

- `../_super8-studio-api-shared/scripts/customer_search.sh`

## CLI

- `--org-id <id>` (optional, falls back to `S8_ORG_ID`)
- `--customer-id <id>` (optional)
- `--display-name <value>` (optional)
- `--original-display-name <value>` (optional)
- `--platform <channel>` (optional, repeatable; accepted values are defined by the developer customer search API)
- `--cell-phone <value>` (optional)
- `--email <value>` (optional)
- `--include-tag <tag>` (optional, repeatable)
- `--exclude-tag <tag>` (optional, repeatable)
- `--joined-start-at <ISO 8601>` (optional)
- `--joined-end-at <ISO 8601>` (optional)
- `--last-inbound-start-at <ISO 8601>` (optional)
- `--last-inbound-end-at <ISO 8601>` (optional)
- `--last-message-start-at <ISO 8601>` (optional)
- `--last-message-end-at <ISO 8601>` (optional)
- `--limit <n>` (optional; page size)
- `--skip <n>` (optional; offset-style pagination)

## Workflow

1. Resolve organization context through `--org-id` or `S8_ORG_ID`.
2. Run `customer_search.sh` with only supported public filters such as `--customer-id`, `--display-name`, `--platform`, `--include-tag`, `--exclude-tag`, `--joined-start-at`, `--last-inbound-start-at`, `--last-message-start-at`, `--limit`, and `--skip`.
3. Return the public customer search results and offset page metadata.

## Segment insight playbook

Use this three-step loop when the user asks what a customer segment (for example VIP tag holders) recently talked about:

1. **Find the segment** — `customer_search.sh` with `--include-tag` and a recent activity window such as `--last-message-start-at` (keep `--limit` at 20 or fewer for analysis).
2. **Resolve each conversation** — for each `customerId` in the search result, run `conversations.sh --customer-id <id> --limit 1` from `super8-studio-conversations`.
3. **Sample messages** — run `conversation_messages.sh --conversation-id <id> --limit 10 --order desc` from `super8-studio-conversation-detail`.

Cap analysis at roughly **20 customers** and **10 messages per customer** unless the user explicitly requests a larger sample.

## Guardrails

- Stay within the published public customer search contract.
- Do not invent internal query structures, Mongo operators, or hidden fields.
