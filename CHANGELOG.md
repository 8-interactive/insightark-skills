# Changelog

## 2.15.1 — MA quotas: "unlimited" is an omitted key, defined by the tool schema (S8CS-345)

- `ma_procedure_validate` / `ma_procedure_create`: `payload.limits` meaning is now described in the tool schema. Omit `limits.message` for no total message cap and omit `limits.per_customer` for unlimited journeys per customer (the Console's 不限訊息則數上限 / 不限旅程次數). Both keys are no longer required. `null` is rejected, and `per_customer: 0` is rejected because it blocks every customer. `limits.message: 0` is a cap, not "unlimited".
- `insightark-ma-automation`: the quota row is now a scenario rule only — customers choose between a limit and 不限, a stated 不限 is taken as the answer instead of asking again, and the skill defers to the tool schema for how to encode it.
- E2E: `ma-validate-pause` omits `limits.message` and asserts it is absent on `ma_procedure_validate` / `ma_procedure_create`.

## 2.15.0 — Broadcast pause / resume (`broadcast_update`), `draft` phase, `allowedActions`

- New MCP tool `broadcast_update` (write scope): `action: pause | resume` changes broadcast lifecycle state only. Pause turns a far-enough scheduled broadcast into a draft; resume turns a complete draft into a scheduled or immediately started broadcast. Content edits stay in the Super8 Console.
- `broadcast_list` / `broadcast_get`: new `draft` phase (long-lived, distinct from the transitional `preparing`), read-only `allowedActions`, and `publishedAt: null` while a broadcast is a draft. The state transitions now live once in the tool descriptions.
- `insightark-broadcast-manager`: WHEN/WHY guidance for pausing and resuming (confirm first, confirm before resuming a draft the customer did not just pause, content edits go to the Console). Replaces the stale claim that no draft lifecycle tool exists. The skill never repeats tool schema text; a Jest suite under `validate:server-contracts` enforces it.
- Completion guidance (S8N-13232): `broadcast_create` description now defines the asynchronous acceptance response and one polling contract with stop conditions; `broadcast_get` / `broadcast_list` define every phase and `deliveryOutcome` value and describe `success` as the platform-accepted count, not proof of customer receipt.
- `broadcast_create` result gains additive `phase`, `deliveryOutcome: null`, and `nextAction`; existing fields are unchanged.
- `insightark-broadcast-manager`: WHEN/WHY completion guardrails (create response is an acceptance, follow up with `broadcast_get`, stop at the tool-defined limit and report completion as unconfirmed, `success` is not a receipt claim).
- Ships with the matching InsightArk MCP server release.

## 2.14.0 — crm_customer_search joinedAt window and missing-phone filter

- `crm_customer_search` accepts `joinedAtFrom` / `joinedAtTo`: inclusive ISO-8601 instants with an explicit offset or `Z` (date-only rejected with `error/invalid-joined-at-instant`; inverted windows with `error/invalid-joined-at-window`). They do not require `platform`.
- `crm_customer_search` accepts boolean `cellPhoneMissing`: `true` matches a missing, null, or empty basic-profile `cellPhone`; `false` / omitted adds no filter. It cannot be combined with `cellPhone` (`error/conflicting-cell-phone-filter`).
- `insightark-customer-manager`: "joined / became friends during a date range" asks use `joinedAtFrom` / `joinedAtTo` (plus `platform`), `return: "count"` for numbers, and paging only inside the window. Do not page all customers and filter joinedAt client-side. "No phone in the basic profile" asks use `cellPhoneMissing: true`.
- Ships with the matching InsightArk MCP server release (S8N-13235).

## 2.13.1 — Republish after Copilot MCP Phase II skill deltas

- Bump VERSION so main can republish after S8N-13128 merged further message-search / investigator / inbox skill copy under already-tagged `v2.13.0`.
- Loosen unit tests that hard-pinned pack VERSION so future bumps only need metadata sync, not per-suite pin updates.

## 2.13.0 — Conversation inbox semantics, slimmed tool/skill copy, Antigravity plugin bundle

- `messaging_conversation_list` `inbox` param: Console folder semantics（五值）. `insightark-conversations` routes miss-reply triage via `lastMessage.senderType`.
- `npm run validate` also runs server Jest suites that read `skills/` (`validate:server-contracts`), so skill-copy contracts fail locally instead of only on staging `yarn test:unit`.
- Slim MCP tool `description` fields across `tools.js`: keep purpose, cross-tool routing, and non-schema pitfalls; drop details already on param descriptions (message-search sender／time／groupBy, MA click-timeout → payload, etc.).
- Investigator／chat-groups P2 cleanup: drop US-*／Strategy A leftovers; align zero-charge and Gate B `page.count` wording.
- Slim `messaging_message_search`／`messaging_chat_group_message_search` tool descriptions: keep purpose, routing, staff identity, and one-at-a-time lock; drop duplicated sender／groupBy／time-window details already on param descriptions.
- Document one-at-a-time message-search lock on `messaging_message_search`／`messaging_chat_group_message_search` tool descriptions and investigator／chat-groups skills (do not call in parallel; wait on `message_search_in_progress`).
- `insightark-investigator`: aggressive trim — keep cross-tool pitfalls, Gate A/B, fields／limit guidelines, domain quirks; drop schema-restating prose and redundant tables.
- QUALITATIVE／FAQ／chat-groups: align to the same minimal bar (load-on-demand; no “Schema first” essays).
- Add a Google Antigravity plugin bundle under `.agents/plugins/insightark-skills/` in generated customer trees.
- Configure the hosted InsightArk MCP with Antigravity's DCR-only `serverUrl` schema; no static OAuth client ID or secret is included.
- Document workspace/global installation and validate that the bundled skills match the canonical skills tree.
- Publish a dedicated `insightark-skills-antigravity-*.zip` artifact so Antigravity installs can consume the plugin root directly.

## 2.12.1 — Broadcast list/get accounting + templateAccounting

- `insightark-broadcast-manager`: after `broadcast_list` / `broadcast_get`, report open/click via `accounting.read` / `accounting.click` (delivered = top-level `success`). Rate **formulas** live on the MCP tool descriptions; the skill tells agents to follow those tools and present 開封率／點擊率 to the user.
- On `broadcast_get`, use nested `templateAccounting` paths → `{ uv, pv }` (uv=unique, pv=including repeats); `elements.i.buttons.j` maps to `options.messages` interactive template element i / button j. `{}` when accounting is unavailable.
- When `accounting` is `null`, state that open/click stats are not available yet. MUST NOT invent rates from delivery counters alone.

## 2.12.0 — Message search fields/count/paging; taggedAt listing; batch tag enqueue

- `messaging_message_search` / `messaging_chat_group_message_search`: allowlisted `fields` projection and `return: "count"` preflight (same filters as list; `{ count }` only).
- Investigator + chat-groups + QUALITATIVE_DETECTION: lean `fields` picking; Gate A (`ceil(count / planned-list-limit) > 5` → ask; omitted list `limit` uses tool default **20**); Gate B / `skip += keptCount` only when `truncated === true` and `keptCount < returnedCount`.
- Conversations / messaging continuation: `skip += keptCount` when truncated with `keptCount < returnedCount`; otherwise `skip += page.limit`.
- FAQ: omit `fields` OK (full default including `platform`); content-only `fields` cannot claim cited CS replies; `keptCount` does not create **full** coverage.
- `insightark-customer-manager`: period-tagged listing (“who / how many received tag X during this calendar window”) uses existing `crm_customer_search` with `taggedAtFrom` / `taggedAtTo` (`YYYY-MM-DD`) and exactly one `includeTags` value. Console include+dates density replay; not current holders.
- Current-holder AND remains `includeTagsMode: "all"` without taggedAt.
- `insightark-investigator`: simultaneous-tag 觸發+完成 funnels stay `includeTagsMode: "all"`; period-tagged customer asks hand off to customer-manager / taggedAt.
- Over-range taggedAt windows fail with `error/date-range-too-large` before the search runs. Do not trial-and-error the cap.
- `insightark-customer-manager`: enqueue the same tags on an explicit search `customerIds` list via `crm_customer_tag_batch_add` / `crm_customer_tag_batch_remove`, then poll `crm_system_task_get` until Mongo `done` or `error`.
- One-customer `crm_customer_tag_add` / `crm_customer_tag_remove` remain for a single known id.
- Investigator ads-referral unique ids hand off tagging to customer-manager; investigator and messaging do not call the batch or poll tools.

## 2.11.0 — Hide conversation credits

- Customer-facing skill copy and MCP `tools/list` descriptions no longer advertise catalog prices or volunteer remaining/used.
- Call `credits_usage` only when the user asks about usage. Do not peek as a search or session-validation preamble.
- On `429` with `limitType` `credit_bucket`, stop retries and use opaque EN/ZH-TW copy; do not inspect remaining unless asked.
- Keep omit-`chargedCredits` and backend debit amounts unchanged.

## 2.10.1 — includeTagsMode all for current-holder AND

- `insightark-investigator`: simultaneous-tag / 觸發+完成 funnels pass `includeTagsMode: "all"` on `messaging_message_search`. Omit / `"any"` remains OR (current holders, not tag history).
- `insightark-customer-manager`: listing customers who currently hold every named tag uses `crm_customer_search` with `includeTagsMode: "all"`.
- Qualitative detection and downstream lenses follow the same `includeTagsMode: "all"` rule when every listed tag must currently be held.

## 2.10.0 — Omit per-call chargedCredits; windowed credits_usage

- MCP tool JSON no longer includes a per-call `chargedCredits` receipt. Usage questions use `credits_usage`.
- `credits_usage` returns monthly peek plus windowed `usage` (omit `from`/`to` = this client today). Params: `from`, `to`, `client`, `aggregate`, `includeTools`. No `date` argument. Response key `usage` replaces `today`.
- Skills report remaining / today / weekly totals from `credits_usage`; they do not treat tool JSON as a credit receipt. The smallest unit for “剛剛” is a calendar day.

## 2.9.0 — Canonical MCP pagination

- Document keyset continuation as `cursor` echoed from `page.nextCursor` (not `pageCursor` / `nextPageCursor`).
- Document offset continuation as `skip = page.skip + page.limit` while `page.hasMore` is true.
- Align conversations, chat-groups, investigator, customer-manager, ma-automation, messaging, and broadcast-manager skills with the canonical pagination envelope.

## 2.8.0 — Conversation FAQ from investigator

- `insightark-investigator`: add `references/FAQ_GENERATION.md` for compiling FAQ / 常見問題 from customer conversations (not a new skill).
- FAQ search uses `messaging_message_search` with `senderTypes: ["Customer","_User"]` and `groupBy: "conversation"`.
- Copilot v2 unmounts native Excel FAQ and thin-routes to this skill.

## 2.7.3 — Customer-facing glossary without CI metadata

- Slim `console-terminology.md` to Console label / English / Short form / Internal·MCP (drop Banned and Evidence from the shipped glossary).
- Move banned tokens and Console evidence pointers to maintainer-only `scripts/console-terminology-gates.json`; validator aligns glossary labels to that file.

## 2.7.2 — Terminology evidence skip when Console checkout absent

- Console evidence deep-equal runs only against a populated `super8-v2-console` checkout (`package.json` or `src/`). Empty submodule placeholders (typical CI without submodule init) skip deep-equal after pointer-shape checks so `npm run validate` can pass in Drone.
- Align `validate-release-tree.sh` starter commands with the current three Codex prompts (drop `search-and-update-customers`) and require `console-terminology.md` in the release tree.

## 2.7.1 — Codex starter prompts refresh

- Update Codex `interface.defaultPrompt` (and aligned Chinese starter `commands/`) to three concrete workflows: MCP session check, weekly conversation Dashboard, and draft a vip-tag LINE broadcast with preview／audience estimate before create.
- Drop the prior customer-search starter command.

## 2.7.0 — Org-wide ChatGroup message search

- `messaging_chat_group_message_search` is organization-wide by default (omit `conversationId` and `chatGroupId`). Passing either id still narrows to one room; passing both remains invalid before credit.
- **Compatibility:** omitting both room ids previously failed with zero-credit `error/invalid-scope`; it now runs a charged (20 credit) org-wide ChatGroup search, parallel to `messaging_message_search` for 1:1.
- Add shared `contentKinds` (same enum／MIME map as `messaging_message_search`).
- `insightark-chat-groups`: route org／cross-group asks without per-group loops; disclose the 20-credit／90-day search contract and actual coverage for multi-call analysis.

## 2.6.1 — Single-source version metadata

- Use `skills/_insightark-shared/VERSION` as the canonical version and synchronize all host metadata with a checked-in script.

## 2.6.0 — Release metadata synchronization

- Align the source tooling and all host plugin/marketplace manifests with the published skills version.

## 2.5.0 — US-1 analysis guidance + contentKinds / list activity window

- Document per-tool messaging scenarios (list／get／messages／search／preview) and contrast list `lastMessageAt*` activity windows vs search `startAt`/`endAt` message windows.
- Guide Strategy A qualitative detection: corpus vs keyword decision tree, optional Phase 0 calibration, no redundant same-window keyword re-search, prefer `contentKinds: ["text"]`.
- Document `messaging_message_search.contentKinds` exact MIME map; clarify `messaging_message_preview` is outbound-only.
- Document conversation list `lastMessageAtFrom`/`To` (≤90d, timezone-aware instants) and opaque `pageCursor` keyset paging.

## 2.4.0 — Generic instant timezone policy (query windows included)

- Apply universal `timezone-policy.md` whenever customer temporal language becomes an MCP input representing a specific instant or interval boundary; no current tool/field allowlist is required.
- Unspecified customer wall-clock → Asia/Taipei (`+08:00`); honor explicit timezone / `Z` / offset. Exclude calendar dates, recurring wall-clock settings, durations, cursors, and returned timestamps.
- Keep message-search date-only / one-sided defaults and ≤90-day limit in messaging and canonical investigator Strategy A guidance; downstream analysis lenses reuse Strategy A.
- `CS_QUALITY_REVIEW.md`: replace singular `senderType` with `senderTypes: ["_User"]`.
- Hierarchy validators assert semantic policy ownership, canonical domain guidance, and CS `senderTypes`-only.

## 2.3.0 — MA template discovery + universal workflow policy hierarchy

MA template discovery (server + skill):

- Catalog agent-ready entries expose `defaultRootTemplateType` (agent-ready default `all`); `ma_template_get` materializes root `templateType` from the selected catalog entry.
- Blank-canvas omit of `templateType` defaults to `all` only when `authoringSource: "blank-canvas"`; catalog clones keep the materialized type.
- Supported create/validate root types: `all`, `default`, and catalog `defaultRootTemplateType` values — not console-only keys.
- Skill fixtures and MA workflow guidance consume the materialized `templateType` (no client-side ID/`consoleKey` derivation).

Universal workflow policy hierarchy (skills):

- Add policy skill `insightark-universal-workflow` (Rich Preview Gate + write lifecycle) with catalog `role` / `prerequisites`.
- Seven workflow skills link the Prerequisite; messaging / broadcast / MA delegate rich-preview and write-lifecycle rules.
- Validators enforce hierarchy behavior, release-tree policy skill presence, and reject treating credit `0` as unlimited.

## 2.2.0 — Investigator qualitative analysis lenses + MCP schema contract hardening

Qualitative detection & analysis lenses (investigator):

- Add `insightark-investigator/references/QUALITATIVE_DETECTION.md`: an on-demand playbook for batch qualitative intent/sentiment/complaint detection using only existing read-only MCP tools.
- Document two detection paths — tag-segmented (`crm_customer_search` → `messaging_conversation_list` → `messaging_conversation_messages`) and time-window/keyword (`messaging_message_search`) — with a selection rule.
- Add hard cost/sample guardrails (`credits_usage` before/after, default sample caps, no blind retry, stop-and-report) and traceable, non-fabricated, human-reviewable reading rules.
- Add `insightark-investigator/references/ROOT_CAUSE_ANALYSIS.md` (US-2): a complaint root-cause / theme-categorisation lens — theme buckets, per-theme root cause + improvement direction, and traceable representative cases.
- Add `insightark-investigator/references/OPPORTUNITY_DISCOVERY.md` (US-3): a positive-intent / opportunity-discovery lens — signal types, keyword seeds, and an explicit "keep runs separate from complaint analysis" rule.
- Add `insightark-investigator/references/CS_QUALITY_REVIEW.md` (US-6): a per-agent CS reply-quality lens — evaluates the staff responder, discovers agents from `_User` message identity (no roster tool), groups by `sender` objectId, and compiles traceable exemplary / needs-improvement cases. Runs on Strategy A because staff identity is returned only by `messaging_message_search`.
- All three lenses reuse the `QUALITATIVE_DETECTION.md` shared layer (Strategy A/B path selection, credit/sample guardrails, traceable non-fabricated reading rules) — no duplication of the data path.
- `SKILL.md` gains an "Analysis lenses" pointer; README investigator entry (EN + 中文) notes all three lenses.

MCP schema contract hardening (skills):

- Message search skills use `senderTypes` only (singular `senderType` removed); document all five published sender classes.
- Broadcast / customer / conversations skills add situational notes for closed params; exact enums defer to MCP schema.
- Clarify multi-class search as one tool call / one normal 20-credit charge vs two searches.

- No new MCP tool and no new skill; still exactly 7 workflow skills. Server backend and `tools/message-preview/` untouched.

## 2.1.0 — First supported marketplace + OAuth release

- Deliver Claude Code, Cursor, and Codex/ChatGPT desktop plugins with URL-only DCR OAuth MCP manifests.
- Production customer path is approved marketplace install → host OAuth Connect → `auth_me`.
- Remove manual skill-copy installer surface, SessionToken setup, shell API runtime, and empty hooks packaging.
- Keep `skills/_insightark-shared/` metadata-only (`RELEASE`, `VERSION`).
- Move LINE template guidelines and examples under `insightark-messaging/references/` for MCP workflows.
- Point Cursor plugin `logo` at `assets/logo.png` (same brand asset as Codex).
- Ship Chinese starter `commands/` aligned with Codex `interface.defaultPrompt` for Cursor and Claude Code.
- Pin Cursor plugin `mcpServers` to `./mcp.json` so the host performs DCR from its own URL-only manifest.
