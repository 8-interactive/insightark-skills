# Qualitative detection playbook (intent / sentiment / complaint)

Load this reference for batch **intent／sentiment／complaint** reading (not a single keyword lookup).
Use only the read-only tools already exposed by this skill. Findings must cite real messages and stay inside the budgets below.

Canonical time／fields／limit／Gate rules live in `skills/insightark-investigator/SKILL.md`.
For date-only or one-sided clocks, follow `skills/insightark-universal-workflow/references/timezone-policy.md`.
Do not silently invent midnight. Stay inside the tool schema max range for `startAt`/`endAt`.

## Path

Use `messaging_message_search` (not `messaging_conversation_list`) for period／keyword／tag／proportion／theme corpora. Conversation list filters Customer `lastMessageAt` activity, not message `createdAt`.

- Prefer `contentKinds: ["text"]` for sentiment／complaints (less notify-event noise). Add `template` when templates matter; use `event` only for join／follow-style asks.
- For full customer+staff dialogue, pass both `senderTypes` classes in one call (never singular `senderType`).
- When the user names a period, pass explicit `startAt`/`endAt` (do not rely on **omit-both-dates**).
- Put tag audience filters on the same search. When every listed current tag must be held, pass `includeTagsMode: "all"` (a multi-value list alone is OR; current holders only).
- Who received a tag during a date window uses `insightark-customer-manager` / `crm_customer_search` with `taggedAtFrom` / `taggedAtTo`.


### Decision tree

1. **Proportion／trend** over a window → search **without** keyword, preferably text, then classify client-side.
2. **Find a known theme／urgency** → run a keyword search after a keyword bank exists (from the user or from calibration).
3. **Optional calibration** when vocabulary is unknown → one large-page text pull under Gate A／call budget, then keyword or second-pass classify. Skip if the user already gave keywords.
4. **No redundant re-search** of the same window solely to recompute statistics already in hand.

## Sample budget

- Default ceiling is about **5** search calls (count＋list) per run unless the user approves more. Prefer a **large** schema-legal `limit` so the budget buys coverage, not many tiny pages.
- Never blind-retry on timeout; narrow the window or filters instead.
- Run message searches serially for a given user／org (shared lock with chat-group search and Console). Do not fan out parallel searches. `message_search_in_progress` means another search is already running — wait, then retry once; it is not a timeout.
- When you hit the ceiling, stop, report coverage, and ask. For huge full-export needs, point to Console CS export instead of paginating the whole org over MCP.
- If the user asks about usage, hand off to `insightark-session` (`credits_usage`). Do not treat tool JSON as a receipt; MUST NOT claim other tools return `chargedCredits`.

## Reading rules

- Cite evidence (`createdAt` + sender／quote). If you cannot point to a message, do not assert the finding.
- Do not invent complaints; absence of a complaint is a valid result.
- Null `_User` identity is a known limitation — attribute by staff role, not as a data error.
- Frame output as human-reviewable signals, not authoritative labels.

## Auth

If a tool returns `401`／`403`／authentication-required, hand off to `insightark-session` for OAuth recovery. Network／timeout／`5xx` are not OAuth problems — apply the retry rules above instead.
