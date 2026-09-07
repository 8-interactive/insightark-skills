# Write lifecycle

## Confirmation

Before any write tool (`messaging_customer_send_message`, `broadcast_create`, CRM updates/tags, `ma_procedure_create` / `start` / `pause` / `trigger`, …):

1. Summarize the customer-visible outcome in business language.
2. Obtain explicit confirmation for that outcome.
3. Only then call the write tool.

Draft create and publish/start are separate confirmations for MA.

## Rich content

If the write involves preview-required content, complete the Rich Preview Gate first (unless the user explicitly skipped preview).

## Failures

- Authentication missing/expired/`401`/`403` → hand off to `insightark-session` for host OAuth recovery.
- Network / timeout / `5xx` → diagnose connectivity; do not treat as OAuth.
- `429` with `limitType` `credit_bucket` → do not retry; do not inspect remaining via `credits_usage` unless the user then asks. Customer-facing text MUST be exactly `This operation could not complete. Please try again later.` / `這次操作無法完成，請稍後再試。`.
- `429` with `limitType` `rpm` → you MAY name a rate limit; MUST NOT use the `credit_bucket` opaque strings.
