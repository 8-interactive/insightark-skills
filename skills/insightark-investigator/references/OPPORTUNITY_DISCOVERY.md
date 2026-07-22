# Opportunity discovery playbook — positive intent (US-3)

On-demand reference for `insightark-investigator`. Load this when a user wants to
mine conversations for **product / marketing / service opportunities** — customer
suggestions, recurring questions, purchase intent, and unmet needs — e.g. "從對話
裡找出商機／顧客想要什麼／常問什麼".

This lens **reuses the shared data layer** in
[`QUALITATIVE_DETECTION.md`](./QUALITATIVE_DETECTION.md) — same tools, same
Strategy A/B path selection, same cost/sample guardrails, same traceable /
non-fabricated reading rules. It adds no new tool and no new skill. Everything
below is the *opportunity lens* on top of that foundation.

---

## This is NOT complaint analysis — keep the runs separate

Opportunity discovery and complaint root-cause ([`ROOT_CAUSE_ANALYSIS.md`](./ROOT_CAUSE_ANALYSIS.md))
look at the *same conversations* but for **opposite signals**, and they must be
run as **separate, scoped passes**:

| | Complaint / root cause | Opportunity discovery |
|---|---|---|
| Looking for | dissatisfaction, failure, risk | interest, requests, unmet needs |
| Keyword seed (Strategy A) | 退款/延遲/客訴/壞/慢/態度… | 想要/有沒有/什麼時候有/可以…嗎/推薦/回購/敲碗/預購/缺貨補貨… |
| Output | 主題 → 根因 → 改善 | 機會點 → 依據 → 行動建議 |

**Do not** reuse one broad "pull everything" read for both — it inflates cost and
dilutes quality (this is exactly the concern raised in the ticket). Decide the
lens first, seed the audience for *that* lens, and honour the same sample caps.

## Opportunity signal types

Classify each candidate into what the customer is actually signalling:

- **功能／商品需求** — asks for a feature, variant, size, bundle that doesn't
  exist yet ("有沒有大包裝", "會不會出XX色").
- **重複詢問（未滿足資訊需求）** — the same question recurs across customers →
  a content / FAQ / onboarding gap, or a demand signal.
- **購買／回購意圖** — explicit intent to buy, restock, or upgrade ("什麼時候補
  貨", "想再買一組", "有沒有優惠").
- **交叉／加購線索** — mentions an adjacent need the catalogue could serve.
- **未滿足需求／競品提及** — wishes, comparisons, "別家有…" that reveal a gap.

## Selecting the opportunity set

- **Segment by tag** (e.g. `VIP`, `回購`, a campaign audience) → Strategy B.
- **Sweep by period / keyword** → Strategy A with positive-intent `keyword`
  seeds above, a bounded `startAt`/`endAt`, and `platform` if channel-specific.
  Follow the canonical Strategy A time-window rules in
  [`QUALITATIVE_DETECTION.md`](./QUALITATIVE_DETECTION.md).
- Prefer reading the **customer turns** (`senderTypes: ["Customer"]` / omit) for
  raw voice-of-customer; pull staff replies only when the response context
  matters for judging the opportunity. Keep within the shared sample caps.

## Output shape

Return a compact, reviewable opportunity list — **not** a scoring engine
(explicitly out of scope), just organised, traceable signals for a human to act on:

```
Sampled: N conversations (period / tag), credits used: X (before→after)
Opportunity (theme)        | Signal type      | Evidence (conversationId · createdAt) | Suggested action
大包裝需求                 | 功能/商品需求    | conv_abc · 07-14  "有沒有家庭號..."     | 評估大容量SKU / 預購測水溫
補貨時間常被問             | 重複詢問         | conv_def·07-15, conv_ghi·07-16          | 補貨通知/到貨預告內容
回購優惠詢問               | 回購意圖         | conv_jkl · 07-17  "想再買有沒有折..."   | 回購券/會員回饋觸發
```

Rules (inherited from the shared reading rules):

- **Trace every opportunity to real messages** (`conversationId` + `createdAt` +
  quote). No evidence → not an opportunity.
- **Do not inflate.** A neutral question is not automatically demand; a single
  offhand comment is a weak signal — say so. Frame confidence modestly and mark
  the whole output as human-reviewable candidate signals.
- Report sample size and measured credit cost.
