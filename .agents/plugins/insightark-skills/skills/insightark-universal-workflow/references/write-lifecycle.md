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
- Credit exhaustion / `429` → stop retry loops; report remaining credits via `credits_usage` when useful.
