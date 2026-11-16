# Customer-service data (客服數據)

Read-only numbers from Console 數據總覽 → 客服數據. A **case (案件)** is a customer-service CSCase record that the inbox creates and updates automatically when members reply, assign, move a conversation to unassigned, or complete it. It is not a Jira ticket, and no tool here creates, assigns, or closes cases.

## Which tool answers which question

| Question | Tool |
| --- | --- |
| 「這週／這個月客服案件量、結案、未完成？」, per platform, vs last period | `cs_case_statistics_get` (add `userId` for one member) |
| 「等待時間／處理時間／完成率／平均訊息數？」 | `cs_service_effect_get` (add `trendMetric` only when the user wants a day-by-day line) |
| 「哪位成員處理最多／完成率最高？」, ranking, filter by permission or advanced role | `cs_member_performance_list` |
| 「某位成員處理了哪些案件？」, find a case number or customer name inside one member's records | `cs_member_case_list` (`userId` required; take it from `cs_member_performance_list` `items[].userId`) |
| 「每天進件／結案的走勢？」, per platform by day | `cs_case_trend_get` |
| 「哪個時段最忙？」 | `cs_case_heatmap_get` (`type`: `create` 進件, `stopWait` 案件, `sentMessage` 訊息量) |

A typical "本週客服狀況" answer is three calls: `cs_case_statistics_get` → `cs_service_effect_get` → `cs_member_performance_list`. Every tool needs `caseType` (`assigned` 已指派 or `unassigned` 未指派); when the user does not say, ask or run both and label them.

There is no organization-wide "look up one case by number" tool: case-number search only exists inside one member's records, as in the Console.

## Periods and the organization timezone

- `period`: `day`, `week`, `lastWeek`, `month`, `lastMonth`, `custom`. `cs_case_trend_get` has no `day`.
- Dates are calendar days in the **organization timezone**, which is not always Asia/Taipei. Every response carries `period.timezone`, `period.start`, `period.end` (and `period.previousStart` / `period.previousEnd` when compared). Quote those dates instead of re-computing them.
- `week` is Monday–Sunday; `month` is the whole calendar month, including days that have not happened yet.
- `custom` limits are the Console's: both `startDate` and `endDate` (`YYYY-MM-DD`), start on or after 2015-01-01, end no later than this week's Sunday, and at most 3 calendar months (end 2026-10-16 → earliest start 2026-07-16; month-end clamps, end 05-31 → earliest start 02-28). Send dates only with `custom`.
- On `error/date-range-too-large` the call failed before any credit was used: split the range into sequential windows of at most 3 calendar months and combine the results yourself — sum counts, but do not average averages or rates across windows without weighting. On `error/invalid-cs-date` or `error/invalid-cs-date-range`, fix the dates from known calendar bounds; never probe limits by trial and error.
- The previous period is chosen by the tool, not by you: the ISO week or calendar month before, or the equal-length window right before a `day` / `custom` range.

## Reading the numbers

- Values are raw: durations are **seconds** (convert to minutes/hours when you present them), rates are 0–1 decimals (×100 for %), counts are integers.
- Field names follow the Console logic: the case-count key equals `caseType` (`assigned` or `unassigned`); `done` = 結案; `undone` = case count − done; `assign` = 轉指派 (handed to another member); `accUndone` = every still-unfinished case up to now, including cases created before the period; `serviceCustomers` = distinct customers served.
- 結案 counts cases created in the period and finished by its end. For assigned cases it includes moving a conversation from assigned to unassigned; for unassigned cases it includes handing it to a member after service.
- `avgWaitTime` / `avgWaitingTime` = average seconds until a member's first reply (assigned: from assignment; unassigned: from case creation). `avgProcessTime` = average seconds from the first reply to completion. `avgDoneRate` = done ÷ cases. Member `doneRate` = (assign + done) ÷ cases.
- `change.rate` is `null` when the previous period is 0. Say 「前期為 0，無法計算變化率」 (and give `change.delta`); never say 「沒有變化」 or 0%.
- Member lists contain only **current** members who handled cases in the period, so member sums can be lower than the organization totals. Unassigned rows have no `avgWaitingTime`; unassigned case records have no wait time, assigner, creator, or assignment time.
- Search text is literal (regex characters are plain text). Member-name search is case-insensitive; customer-name and case-number search are case-sensitive, as in the Console.
- Heatmap cells are averages over the dates in the period that had activity in that slot (Console behaviour), `weekday` 1 = Monday … 7 = Sunday, and `busiest` is `null` when there is no data.
- `cs_case_trend_get` returns per-platform `created` (by creation day) and `done` (by finish day) series.

## Charts: data first, ask before drawing

`cs_service_effect_get` (with `trendMetric`), `cs_case_trend_get`, and `cs_case_heatmap_get` return data only — no image, chart configuration, or image URL.

1. Present the key figures first as text or a small table (peak day, busiest slot, biggest change).
2. If the user wants a chart, or the data clearly suits one, **ask** which way to draw it: (a) the current agent draws it with what the host supports, or (b) call another charting tool available in this environment.
3. Draw only after the user agrees. Never draw a chart automatically.

Host notes:

- **Copilot v2**: the native `drawChart` tool can draw bar, line, and pie charts (trend lines, platform splits). It cannot draw a heatmap — show the 7×24 heatmap as a table (or the top slots), or ask the user to pick another way.
- **External MCP hosts**: depends on what that host can render; ask, do not assume.

## Failures

- `error/cs-data-disabled`: the organization turned off 數據總覽／客服數據 in its settings. Tell the user; do not retry.
- `error/cs-member-not-found` / `error/cs-role-not-found`: the member is no longer in the organization, or the role id is not one of its advanced roles. Re-list members with `cs_member_performance_list`.
- `error/invalid-cs-member-filter` (`permission` with `roleId`), `error/invalid-cs-case-filter` (`customerName` with `caseNo`), `error/invalid-cs-sort` (sort key not allowed for that `caseType`): fix the arguments; nothing was charged.
- **cs_data_timeout**: a very large organization or long window ran past the time limit. The call was already charged. Do not retry the same arguments — shorten the period (for example a month instead of 3 months), split it, or scope to one member, and tell the user.
