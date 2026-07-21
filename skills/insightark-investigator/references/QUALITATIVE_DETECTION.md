# Qualitative detection playbook (intent / sentiment / complaint)

On-demand reference for `insightark-investigator`. Load this when a user asks you
to read a batch of conversations and judge **intent**, **sentiment**, or
**complaints** — as opposed to a single keyword lookup.

This playbook uses **only the read-only MCP tools already exposed by this skill**.
It adds no new tool and no new skill. It is designed to be cheap, bounded, and
honest: findings must trace back to real messages, and cost must stay inside a
budget you can see.

---

## Two detection paths

There is no single tool that both selects an audience by tag *and* returns a
message timeline. Pick the path from how the audience is defined.

### Strategy B — tag-segmented audience (default when a tag is involved)

Use when the audience is "customers who have tag X" (VIP, churn-risk, a campaign
segment, etc.). **This is the only path that can select by tag** —
`messaging_message_search` has no tag filter.

1. `crm_customer_search` with `includeTags: [...]` — returns customers that have
   **all** of the given tags (AND). `limit` default 20, max 100; page with `skip`.
2. For each customer, `messaging_conversation_list` with `customerId` to find
   their conversation(s). `limit` default 20, max 100.
3. `messaging_conversation_messages` with `conversationId` to read the timeline.
   `limit` default 20, max **1000**. Each message carries `createdAt`, so you can
   window client-side without another call.
4. Read the timeline and produce the qualitative judgement (see *Reading rules*).

### Strategy A — time-window / keyword audience

Use when the audience is "messages in a date range" or "messages mentioning a
keyword" across the whole org, with **no tag constraint**.

- `messaging_message_search` with any AND-combination of `keyword`, `platform`,
  `startAt`, `endAt`, `senderTypes`, `senderIds`, `conversationId`.
- Default sender filter (omit `senderType`/`senderTypes`) is **Customer only**.
  For full customer+staff dialogue pass `senderTypes: ["Customer","_User"]` in a
  single call — do not pass both `senderType` and `senderTypes`.
- Time window is **always** applied server-side: omit both dates → last **14 days**;
  explicit range max **90 days**. If the user asks for a specific period (e.g. 30
  days), pass matching `startAt`/`endAt` — do not rely on the 14-day default.
- `limit` default 20, max **1000**; page with `skip`.

### Choosing a path

| Audience is defined by… | Path |
|---|---|
| a customer **tag** (segment) | **Strategy B** |
| a **time window** and/or **keyword**, no tag | **Strategy A** |
| a tag **and** a keyword | Strategy B to select customers, then filter messages client-side by `createdAt`/keyword (avoid a second paid search) |

---

## Cost & sample guardrails (hard limits)

Read chains cost materially more than the nominal per-call number. Measured on
staging, a small run (≈3 customers / 3 conversations / ≈8 read calls) consumed on
the order of **~90 credits** against a monthly free allowance of **500**.
`messaging_message_search` is billed at a higher fixed rate per call. Treat every
batch read as spending real budget.

**You MUST:**

1. **Measure before/after.** Call `credits_usage` (it does **not** consume
   credits) at the start, and again at the end, and report actual consumption.
2. **Respect default sample caps** unless the user explicitly approves more:
   - customers per run: **≤ 25**
   - conversations per customer: **≤ 3** (most recent)
   - messages per conversation: **≤ 200** (`limit`)
   - `messaging_message_search` calls per run: **≤ 5**
   These are defaults, not hard locks — you may raise them, but only after the
   user explicitly agrees, and you should restate the expected extra cost first.
3. **Never blind-retry.** If a call fails or times out
   (`message_search_timeout`), do not resend identical arguments — credits are
   still charged. Narrow the time window / lower `limit` / add a filter, or stop.
4. **Stop at the cap, report, then ask.** On reaching any cap or a stated budget,
   halt and report what you covered and what remains. Do not keep fetching.

If the user needs full coverage of a large audience, say so plainly and route the
human to the Console CS export rather than paginating the whole org over MCP.

---

## Reading rules (traceable, non-fabricated, human-reviewable)

- **Trace every finding to evidence.** Each detected intent / sentiment /
  complaint MUST cite the specific message(s) it is grounded in (quote or
  reference by `createdAt` + sender). If you cannot point to a message, do not
  assert the finding.
- **Do not invent complaints.** Absence of a complaint is a valid result. Never
  upgrade a neutral question into a complaint to produce a "finding".
- **Staff identity may be missing.** `_User` (staff) messages can return null
  `userEmail` / `userName` — this is a known limitation (tracked as S8N-13049),
  **not** a data error. Attribute by role ("staff reply") when identity is null.
- **Frame output as human-reviewable.** Present findings as candidate signals for
  a human to confirm — counts, representative quotes, and per-conversation notes —
  not as an authoritative classification. Detection quality has not yet been
  stress-tested on real-complaint corpora, so keep confidence claims modest.

## Auth failures

If a tool returns authentication-required / `401` / `403` (missing, expired, or
revoked session), hand off to `insightark-session` for host OAuth recovery before
retrying. Network / timeout / `5xx` are not OAuth problems — apply the retry
rules above instead.
