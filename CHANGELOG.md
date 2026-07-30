# Changelog

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
