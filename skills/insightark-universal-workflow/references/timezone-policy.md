# Timezone policy (scheduling writes)

Apply this policy **only** when assembling or confirming these **write payload** fields:

- `broadcast_create.scheduleAt`
- Marketing Automation `startTime`
- Marketing Automation `endTime`

Do **not** apply this policy to query time windows (for example message-search `startAt` / `endAt`) or other fields that happen to be named `startTime` / `endTime`.

## Default

1. If the customer gives a **wall-clock time** and does **not** specify a timezone → interpret as **Asia/Taipei (UTC+8)** and encode ISO 8601 with offset **`+08:00`**  
   (example: `2026-07-23T09:00:00+08:00`).
2. If the customer explicitly names UTC / another timezone, or already provides `Z` or an offset → **honor that**; do not rewrite to Taipei.
3. Relative dates (“tomorrow”, “next Friday”) → resolve on the calendar of the **timezone in effect for this request**:
   - customer named a timezone / offset / `Z` → resolve relative dates in **that** timezone’s calendar;
   - timezone omitted → resolve in **Asia/Taipei**.
   Then show the **resolved absolute date** and the **timezone used for resolution** in the confirmation table before writing.  
   Example failure mode to avoid: when Taipei has already crossed midnight but UTC has not, “tomorrow 09:00 UTC” must use the UTC calendar day, not Taipei’s.
4. **Date-only** ranges (for example “7/1–7/31”) → **do not** invent start/end clock boundaries. Ask whether the intended bounds are Taipei time such as `07/01 00:00:00+08:00` through `07/31 23:59:59+08:00` (or another explicit pair in the customer’s timezone). Only after the customer confirms may you validate/create.  
   Timezone default only interprets an **already explicit** wall-clock time; it does **not** replace MA’s rule against guessing schedule bounds.
5. Agent policy (not a broadcast API guarantee): do **not** default to `Z`, and do **not** submit a bare datetime without offset for these scheduling fields when the customer did not specify a timezone.  
   Broadcast `scheduleAt` is only validated with `new Date()` today and may accept bare datetimes; agents must still send an explicit `+08:00` (or a customer-specified offset).

## How broadcast persistence works

`broadcast_create` parses the input into a `Date` and may persist via `.toISOString()`.  
So MCP input `2026-07-23T09:00:00+08:00` is the same instant as stored/returned UTC `2026-07-23T01:00:00.000Z`. That is expected; it does not mean the customer asked for UTC wall-clock 09:00.

MA validate/create still require an ISO timezone suffix (`Z` or `±HH:MM`). When the customer omitted a timezone, supply **`+08:00`**, not `Z`.

## Confirmation table (extend existing write confirm)

Before calling the write tool, include at least:

| Field | Example |
|-------|---------|
| Customer intent | `明天 09:00 UTC` → resolved `2026-07-23 09:00（UTC）` |
| Timezone used for resolution | `UTC` (explicit) — or `Asia/Taipei` when unspecified |
| MCP input | `2026-07-23T09:00:00Z` |
| System may return/store | equivalent UTC `2026-07-23T09:00:00.000Z` |

When timezone was omitted, state in customer language that scheduling uses Taiwan time (UTC+8). When the customer named another timezone, show that timezone and the absolute date resolved on its calendar.
