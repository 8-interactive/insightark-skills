# Broadcast status golden cases

These cases define the required reporting behavior after a read-only `broadcast_get` or `broadcast_list` response.

| Case | Evidence | Required report |
| --- | --- | --- |
| Progressing | Two working snapshots about 60 seconds apart; `completed` rises from 41 to 65 | Delivery made progress; cite both counts and `observedAt` values. |
| No progress observed | Two available working snapshots remain working with the same `completed` | Report `no_progress_observed` as an attention signal only; do not state a root cause. |
| Phase transition | First snapshot is working; second is terminal or dispatching | Report the second phase/outcome; do not apply the unchanged-working rule. |
| Scheduled overdue | `phase: scheduled`, `attention: scheduled_overdue` | Report delayed scheduling evidence and the schedule/observation times; do not mutate or retry it. |
| Classified terminal failure | `deliveryOutcome: done_with_failures`, `classificationAvailability: available` | Report only the bounded allowlisted aggregates, any unclassified remainder, and `taskId`; stop for user direction. |
| Partial terminal failure | `classificationAvailability: available`, positive `unclassifiedFailedCount` | State that classification is partial; do not invent a cause for the remainder. |
| Unavailable terminal failure | `classificationAvailability: unavailable` | Report the unclassified count and `taskId` for Super8 Console/support handoff; do not expose raw provider values or infer a cause. |
| Just-created broadcast | `broadcast_create` response with `phase: preparing` or `scheduled`, `deliveryOutcome: null`; customer asks whether it arrived | Call `broadcast_get`; answer from `phase` and `deliveryOutcome`. While the phase is not terminal, say it is still in progress; never report delivery from the create response. |
| Cap reached while working | Tool-defined follow-up limit reached, `phase: working`, `completed` below `total` | Report the phase and progress, say completion is unconfirmed (not a failure), and cite `taskId` for Console/support handoff. |
| Replacement request after failure | Any terminal failure diagnostic | Do not resend automatically: there is no resend/cancel/delete/export tool (`broadcast_update` only pauses and resumes a scheduled broadcast). Obtain fresh explicit user confirmation before a replacement `broadcast_create`. |
