# Broadcast status golden cases

These cases define the required reporting behavior after a read-only `broadcast_get` or `broadcast_list` response.

| Case | Evidence | Required report |
| --- | --- | --- |
| Progressing | Two working snapshots about 60 seconds apart; `completed` rises from 41 to 65 | Delivery made progress; cite both counts and `observedAt` values. |
| No progress observed | Two available working snapshots remain working with the same `completed` | Report `no_progress_observed` as an attention signal only; do not state a root cause. |
| Phase transition | First snapshot is working; second is terminal or dispatching | Report the second phase/outcome; do not apply the unchanged-working rule. |
| Scheduled overdue | `phase: scheduled`, `attention: scheduled_overdue` | Report delayed scheduling evidence and the schedule/observation times; do not mutate or retry it. |
| Done with failures | Terminal `deliveryOutcome: done_with_failures` | Report final counters and bounded aggregate diagnostics; cite `taskId` for support. |
