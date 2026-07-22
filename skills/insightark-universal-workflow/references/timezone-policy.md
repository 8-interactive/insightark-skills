# Timezone policy for instant-valued MCP inputs

Use this policy when **all** of the following are true:

1. The value comes from customer-provided temporal language.
2. The agent will place the value in an MCP input.
3. The input represents a **specific instant** or an **interval boundary parsed as an instant**.

This is a semantic rule, not a tool or field-name allowlist. Future instant-valued MCP inputs inherit it automatically.

## Do not apply to semantic non-instants

Do **not** apply instant timezone encoding solely because a value looks date- or time-related:

| Semantic class | Examples | Why |
|----------------|----------|-----|
| Calendar date | Birthday or anniversary | Identifies a day, not a moment |
| Recurring wall-clock setting | Daily off-hours clock | Repeats in an owning timezone |
| Relative duration | Wait or timeout length | Measures elapsed time |
| Cursor / opaque token | Pagination state | Not customer temporal language |
| Returned timestamp | A time reported by a tool | Not an MCP input assembled by the agent |

Follow the owning workflow or tool contract for these values.

## Conversion rules

1. If the customer gives a **wall-clock time** without a timezone, interpret it as **Asia/Taipei (UTC+8)** and encode it with explicit offset **`+08:00`**.
2. If the customer names a timezone or supplies `Z` / an offset, **honor that timezone**; do not rewrite it to Taipei.
3. Resolve relative calendar language (for example “tomorrow” or “next Friday”) on the calendar of the **effective timezone**:
   - customer named a timezone / offset / `Z` → use that timezone;
   - timezone omitted → use Asia/Taipei.
4. When an MCP input requires an instant but the customer supplied only a **date**, ask for the intended clock boundary. Do not silently invent midnight, end-of-day, or another clock.
5. Customer-derived wall-clock instants must carry an explicit timezone suffix. Do not default an omitted customer timezone to `Z`.

System-derived instants such as the execution-time `now` may use canonical UTC because they do not interpret a customer wall-clock timezone.

## Confirmation and disclosure

- **Writes:** Follow the owning write lifecycle. Show the customer intent, effective timezone, and encoded MCP input before writing; include persistence/display conversion when the owning workflow requires it.
- **Reads:** When customer wall-clock language is encoded, disclose the effective timezone in the same turn as the read or in the plan before calling. Do not require an extra write-style approval solely for timezone.

The owning domain workflow remains responsible for tool-specific omitted values, range limits, storage behavior, credit confirmation, and other execution rules.
