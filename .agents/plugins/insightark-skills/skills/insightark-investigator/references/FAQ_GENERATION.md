# FAQ generation from customer conversations

On-demand reference for `insightark-investigator`. Load this when a user asks to
compile, generate, or summarize an FAQ / 常見問題 from customer conversations —
e.g. "幫我把上週的客服對話整理成 FAQ".

This reuses the shared data layer in
[`QUALITATIVE_DETECTION.md`](./QUALITATIVE_DETECTION.md) — same tools, same
credit/sample guardrails, same traceable / non-fabricated reading rules. It adds
no new tool and no new skill.

Do **not** use `OPPORTUNITY_DISCOVERY.md` (recurring-question *gaps*) or
`CS_QUALITY_REVIEW.md` (staff-reply scoring) as a substitute for FAQ Q&A.

---

## Call shape

Use **one** `messaging_message_search` call with:

- `senderTypes: ["Customer", "_User"]` — do not omit `senderTypes` (omit defaults to Customer only).
- `groupBy: "conversation"` — the backend returns flat `messages` plus `conversations` keyed by `conversationId`, each group sorted by `createdAt` ascending.
- Explicit `startAt` / `endAt` when the user gives a period. If they omit dates, existing investigator windows apply (omit both → last 14 days; max 90 days).
- Honour QUALITATIVE_DETECTION sample caps (`messaging_message_search` calls ≤ 5 per run unless the user approves more).

Do not loop search to rebuild an Excel workbook. Full human export is Console CS export.

## How to read `conversations`

Use the grouped `conversations` payload, not a self-made reshuffle of the flat list.

- A claim that an answer is how CS **actually replied** may cite only a `_User` message in the **same** `conversationId` as the customer question, with `createdAt` **after** that question.
- If that conversation has no later `_User` message, treat the question as unanswered / no staff reply in sample. Do not invent a CS answer. Do not borrow a reply from another conversation.
- Cross-conversation synthesis must be labeled **綜合／建議**. It must not be presented as a single real reply.

If the sample has Customer messages and zero `_User` messages, say so and do not present invented CS answers as real replies.

## Coverage (sample / partial / full)

The user-facing draft must state:

- coverage (effective `startAt` / `endAt` actually searched)
- `senderTypes` and `groupBy`
- backend `returnedCount` (message count from the tool / Copilot envelope)
- session spend from `credits_usage` `usage.total` for this client today (never a guessed table; tool JSON is not a credit receipt)

Label **full** for that window only when paging is exhausted (`returnedCount` strictly less than `limit`) **and** the host did not truncate the tool output. On Copilot, `truncated: true` (or a `...[truncated … chars]` marker) means sample/partial — do not invent `chargedCredits`.

Otherwise label sample or partial. If the ask exceeds search-call / sample / 90-day guardrails, say so and point to Console CS export. Never present a bounded draft as a complete org-wide FAQ export.

## Output

Return an in-chat FAQ draft (question / answer pairs grounded in returned messages). Do not emit a `/copilot/faq/:id` download URL and do not reconstruct Excel from MCP search.
