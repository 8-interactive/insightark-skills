# FAQ generation from customer conversations

Load this reference when compiling FAQ／常見問題 from conversations (for example, "整理上週客服對話成 FAQ").

This playbook reuses [`QUALITATIVE_DETECTION.md`](./QUALITATIVE_DETECTION.md) budgets and reading rules.
Do **not** substitute `OPPORTUNITY_DISCOVERY.md` or `CS_QUALITY_REVIEW.md` for FAQ Q&A.

## Call shape

Use one `messaging_message_search` call with:

- `senderTypes: ["Customer", "_User"]` — omitting `senderTypes` defaults to Customer only and cannot cite real CS replies
- `groupBy: "conversation"`
- Explicit `startAt`/`endAt` when the user names a period
- Prefer few calls and a large schema-legal `limit` (QUALITATIVE budget)
- `fields`: you MAY omit `fields` for the full default. If you set `fields`, keep enough keys to cite Q/A and staff identity. `fields: ["data"]` alone MUST NOT be used to claim cited CS replies.

Do not rebuild an Excel workbook via MCP; full human export uses Console CS export.

## Read `conversations`

Use the grouped `conversations` payload, not a self-made reshuffle of the flat `messages` list.

- A claim that CS **actually replied** may cite only a `_User` message in the **same** `conversationId`, with `createdAt` **after** the question.
- If that conversation has no later `_User` message, treat it as unanswered in the sample; do not invent an answer or borrow a reply from another conversation.
- Label cross-conversation synthesis as **綜合／建議**; never present it as one real reply.
- If the sample has Customer messages and zero `_User` messages, say so and do not fabricate answers.

## Coverage

State the effective window, `senderTypes`, `groupBy`, and `returnedCount`.

Label **full** for that window only when paging is exhausted (`returnedCount` < `limit`) **and** the host did not truncate (`truncated` is false or absent). If `truncated: true`, label sample／partial. `keptCount` alone does not create a **full** label. If the ask exceeds budget, say so and point to Console. Never present a bounded draft as an org-wide complete FAQ.

## Output

Return an in-chat FAQ draft grounded in returned messages. Do not emit a `/copilot/faq/:id` download URL, and do not reconstruct Excel from MCP search.
