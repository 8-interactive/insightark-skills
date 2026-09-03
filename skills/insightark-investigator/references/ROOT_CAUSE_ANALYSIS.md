# Complaint root-cause & theme playbook (US-2)

On-demand reference for `insightark-investigator`. Load this when a user asks you
not just to *detect* complaints but to **categorise them by theme and organise
root causes / improvement directions** — e.g. "整理最近的客訴，看是哪些原因、怎麼改".

This lens **reuses the shared data layer** in
[`QUALITATIVE_DETECTION.md`](./QUALITATIVE_DETECTION.md). It adds no new tool and
no new skill. Before selecting or reading conversations, follow that playbook for:

- **Path selection** — one bounded `messaging_message_search` using tag,
  time-window, and/or literal keyword filters.
- **Cost & sample guardrails** — session spend from `credits_usage` `usage.total`
  (this client today); do not treat tool JSON as a credit receipt.
  default sample caps, no blind retry, stop-and-report at the cap.
- **Reading rules** — trace every finding to real messages, do not fabricate
  complaints, treat null `_User` identity (S8N-13049) as a known limitation,
  present findings as human-reviewable.

Everything below is the *root-cause lens* on top of that shared foundation.

---

## When to use this lens vs plain detection

| Ask | Reference |
|---|---|
| "有多少負面情緒／客訴？占比／趨勢？" | `QUALITATIVE_DETECTION.md` (detection only) |
| "**這些客訴是為什麼、集中在哪些主題、怎麼改**" | this doc (theme + root cause) |
| "整理正向意圖／商機" | `OPPORTUNITY_DISCOVERY.md` |

Root-cause work is detection **plus** grouping and interpretation, so it reads
the same messages but spends its effort on *why* and *what to do*, not on
counting sentiment.

Run this as its own scoped pass. If the ask also wants positive signals, do the
opportunity lens ([`OPPORTUNITY_DISCOVERY.md`](./OPPORTUNITY_DISCOVERY.md)) as a
**separate** run with its own audience seed — do not share one broad pull for
both, or cost and quality both suffer.

## Selecting the complaint set

- **Have a complaint tag / segment** (e.g. customers tagged `客訴`, `退款`,
  `VIP-申訴`) → search with `includeTags` plus bounded time/keyword filters.
  If every listed tag must currently be held, follow
  [`QUALITATIVE_DETECTION.md`](./QUALITATIVE_DETECTION.md) `includeTagsMode: "all"`.
- **No tag, want a period or keyword sweep** →
  `messaging_message_search` with a complaint-leaning `keyword` (退款 / 退貨 / 出貨
  / 到貨 / 客訴 / 投訴 / 沒收到 / 錯 / 壞 / 慢 / 態度 …), a bounded `startAt`/`endAt`,
  and `platform` if the ask is channel-specific. Follow the canonical Strategy A
  time-window rules in [`QUALITATIVE_DETECTION.md`](./QUALITATIVE_DETECTION.md).
- Read the **full conversation timeline** (`messaging_conversation_messages`, or
  `senderTypes: ["Customer","_User"]` on search) so a root cause is judged from
  the exchange, not one line in isolation.
- Enrich context only when it changes the categorisation: `crm_customer_get`
  for the customer's tags / order-relevant profile, and each message's
  `createdAt` for sequence and timing. Do not fan out extra reads "just in case"
  — every read spends credits.

## Theme categorisation

Do **not** impose a fixed industry taxonomy. Derive themes from the evidence.
Use this default frame only as a starting point and adapt to what the data shows:

- 商品／品質（瑕疵、規格不符、缺件）
- 物流／出貨（延遲、未到、破損、地址）
- 服務／客服回覆（態度、回覆慢、答非所問、已讀不回）
- 活動／規則（優惠條件、贈品、資格爭議）
- 系統／流程（下單、付款、帳號、退款流程卡關）
- 其他（無法歸入上列時才用，並說明）

Assign each complaint to the **best-supported** theme; if a case spans themes,
record the primary one and note the secondary.

## Root-cause structure per theme

For each theme that appears, produce:

1. **主題 + 命中量** — how many conversations/cases fell here (out of the sampled
   set — state the denominator).
2. **代表案例（可回溯）** — 1–3 representative cases, each traceable by
   `conversationId` + `createdAt` + a short quote. This is the AC-3 traceability
   requirement: every theme must point back to real conversations.
3. **可能根因** — grounded in the cited messages (e.g. "到貨延遲後客服未主動告
   知 → 顧客二次追問才回覆"). Do not assert a cause with no message support.
4. **可優化方向** — an actionable suggestion tied to the root cause (SOP, 通知時
   機, 話術, 系統修正). Frame as a candidate for human confirmation.

## Output shape

Return a compact, reviewable summary, not a long transcript dump:

```
Sampled: N conversations (period / tag), credits used: X (`credits_usage` `usage.total`)
Theme                | Cases | Representative (conversationId · createdAt) | Likely cause → Suggested fix
物流／出貨            |   6   | conv_abc · 07-14  "到貨過三天還沒..."       | 出貨後無主動通知 → 補出貨/延遲通知
服務／客服回覆        |   3   | conv_def · 07-15  "已讀不回..."             | 尖峰時段回覆量能不足 → 值班/自動回覆
...
```

Always state the sample size and measured credit cost, and label the result as
human-reviewable signals rather than an authoritative audit.
