---
name: super8-studio-messaging
description: Investigate and operate on messaging through the SUPER 8 Studio Developer API using session validation, org scoping, conversation listing, conversation inspection, message search, and outbound message dispatch.
when_to_use: When a user wants a single messaging-oriented workflow that can validate API readiness, resolve organization scope, browse conversations, inspect one conversation, search messages, or dispatch outbound messages to a customer.
allowed-mcp: false
---

# Skill: super8-studio-messaging

This skill operates on the SUPER 8 Studio Developer API.

## Composed skills

- `super8-studio-session`
- `super8-studio-org-scope`
- `super8-studio-conversations`
- `super8-studio-conversation-detail`
- `super8-studio-message-search`
- `super8-studio-customer-send-message`

## Workflow

1. Validate runtime readiness with `super8-studio-session` when the caller's API context is not yet trusted.
2. Resolve organization context with `super8-studio-org-scope` before any org-scoped messaging route.
3. Choose one operational path:
   - `super8-studio-conversations` for listing, filtering, and pagination over conversations
   - `super8-studio-conversation-detail` for one conversation's public message timeline
   - `super8-studio-message-search` for keyword and filter-driven message search inside an organization
   - `super8-studio-customer-send-message` for dispatching outbound text, image, or video messages to one customer
4. Return the result grounded in the public developer API response.

## Example requests

- `Use super8-studio-messaging to validate my Developer API session and show the conversations in org org_demo_001 from the past 24 hours.`
- `Use super8-studio-messaging to open conversation conv_abc in org org_demo_001 and show the latest messages.`
- `Use super8-studio-messaging to search messages in org org_demo_001 for the keyword "refund" within the past 7 days.`
- `Use super8-studio-messaging to send the text "Your order is on the way" to customer cus_123 in org org_demo_001.`
- `Use super8-studio-messaging to send the image https://cdn.example.com/promo.jpg to customer cus_123 in org org_demo_001 with reply token rtok_abc.`

## Guardrails

- Treat `super8-studio-customer-send-message` as a write operation that can trigger real platform messages and incur cost.
- Do not perform a send unless the target customer id and intended message content are explicit.
- Do not infer customer ids or message content from ambiguous user input; confirm before dispatching if any field had to be inferred.
- Stay within the published public messaging schema and developer API routes.
- For read operations (list, inspect, search), use the underlying skills' published filters and response shapes without inventing fields.
