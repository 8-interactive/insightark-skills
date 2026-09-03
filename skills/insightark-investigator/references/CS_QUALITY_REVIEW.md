# CS reply-quality & training-material playbook (US-6)

On-demand reference for `insightark-investigator`. Load this when a user wants to
review **customer-service reply quality by agent** and compile exemplary /
needs-improvement cases as training material — e.g. "看看每個客服回得好不好，各挑
幾則好的跟要改的當月教育訓練素材".

This lens **reuses the shared data layer** in
[`QUALITATIVE_DETECTION.md`](./QUALITATIVE_DETECTION.md) — same tools, same
credit/sample guardrails, same traceable / non-fabricated reading rules. It adds
no new tool and no new skill. What is different here is the **axis**: the other
lenses read the *customer*; this one evaluates the **staff responder** (`_User`).

---

## Primary path is `messaging_message_search`

Staff (`_User`) reply identity — `userName` / `userEmail` — is returned **only by
`messaging_message_search`**. `messaging_conversation_messages` does **not**
carry staff identity, so it cannot attribute replies to an agent. Therefore CS
quality review uses `messaging_message_search`:

- To read the exchange for judging a reply in context, use
  `senderTypes: ["Customer","_User"]` in one search call.
- To pull only staff replies, use `senderTypes: ["_User"]`.
- Narrow with `startAt`/`endAt`, `platform`, and `conversationId` as usual, and
  honour the shared sample caps (`messaging_message_search` calls ≤ 5 per run).
  Follow the canonical Strategy A time-window rules in
  [`QUALITATIVE_DETECTION.md`](./QUALITATIVE_DETECTION.md).
- **Single conversation** ("誰處理這通、回得好不好?") is still Strategy A: search
  narrowed by `conversationId` (+ `senderTypes`). Do **not** reach for
  `messaging_conversation_messages` — it reads the timeline but cannot name the
  agent.

For a tag-segmented audience, add `includeTags` to that same search.

## Identify the agents (no roster tool exists)

There is **no** endpoint that lists org staff. The only source of
`senderId → agent` is the identity attached to each `_User` message by
`messaging_message_search`. So discover agents from the data:

1. Run one bounded search over the period with `senderTypes: ["_User"]` (or
   `senderTypes: ["Customer","_User"]`).
2. Collect the **distinct `sender` objectIds** that appear, each with its
   `userName` / `userEmail` label.
3. Drill into a specific agent with `senderIds: [<that objectId>]` — the value
   you pass is the **same `sender` objectId** you grouped on in step 2.

**Grouping key is the `sender` objectId** (stable and unique per agent);
`userName` / `userEmail` are display labels only. `userEmail` may be an email or a
username fallback — do not treat it as a guaranteed mailbox.

## Staff identity null boundary

If a `_User` record has neither name nor email/username, `userName` / `userEmail`
come back null (S8N-13049 hardened this, but it is rare and can still happen).
Then attribute by role ("staff reply") and **still group by `sender` objectId** —
treat missing identity as a known limitation, not an error (same rule as the
shared reading rules).

> Dependency note: the staff-identity fields ship in `messaging_message_search`
> already (merged in code); their end-to-end staging verification is a follow-up
> tracked with S8N-13049, not a gap in this playbook.

## Judging reply quality

Read the **full exchange** (customer turn + staff reply) so quality is judged in
context, never a staff line in isolation. Reasonable, human-reviewable signals:

- **Exemplary** — timely, on-point, empathetic, resolves or clearly advances the
  issue.
- **Needs improvement** — slow / no response, off-topic, curt, leaves the
  customer to chase, or misses the actual question.

These are candidate signals for a human reviewer, **not** an authoritative score
(there is no scoring engine).

## Output shape

Per agent, a small, traceable set — not a transcript dump:

```
Sampled: N staff replies over <period> (platform), credits used: X (`credits_usage` `usage.total`)
Agent (senderId · label)        | Exemplary (conversationId · createdAt · quote) | Needs-improve (conversationId · createdAt · quote)
u_abc · 小美 <mei@…>             | conv_11 · 07-14 "已幫您加急並回報物流…"          | conv_19 · 07-16 "(顧客追問兩次才回)"
u_def · staff (identity null)    | conv_22 · 07-15 "…"                            | —
```

Rules (inherited from the shared reading rules):

- **Trace every case** to a specific message (`conversationId` + `createdAt` +
  quote). No evidence → not a case.
- **Do not fabricate** a quality problem or praise; absence of an issue is valid.
- Report sample size and measured credit cost; label output as human-reviewable.
- For full monthly coverage of every reply, route the human to the Console CS
  export; use MCP for **sampling**, within the shared caps.
