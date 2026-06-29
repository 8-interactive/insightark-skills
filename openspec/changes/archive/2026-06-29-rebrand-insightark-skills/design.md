## Context

Pre-release brand audit found three inconsistent name forms in the repo: `Super 8 Studio` (mixed case), `Super8` (publisher field), and the descriptive product suffix `API Skills`. The registered trademark `InsightArk` lived only in the npm package name `@8-interactive/insightark-skills` and was invisible to users. Separately, the source repo was renamed to `8-interactive/insightark-skills`, leaving the old URL (and a stray `no8io/...` clone URL) in manifests and docs. The `publish-to-public-npm` change had explicitly deferred renaming the `bin` and plugin identifiers ("documented as a known minor inconsistency, to be aligned later if desired"). This change closes that loop.

## Goals / Non-Goals

**Goals:**
- One canonical company name (`SUPER 8 Studio`) and one product name (`SUPER 8 Studio InsightArk Skills`) across every surface.
- Surface the `InsightArk` trademark in user-facing names.
- Align `bin`, plugin manifest identifiers, npm name, and repo URL on `insightark-skills`.
- Make the trademark/attribution legally explicit (LICENSE copyright + NOTICE).

**Non-Goals:**
- No change to runtime behavior, API calls, credential load order, install targets, or the install-registry format.
- No rename of the internal skill ids (`super8-studio-*`) or the shared dir `_super8-studio-api-shared` — those are stable internal identifiers, out of scope.
- No rename of env vars (`S8_*`), config files (`.super8-studio.config`, `.super8-studio.env`), or the API host.

## Decisions

### D1: Canonical casing is `SUPER 8 Studio`
The `NOTICE` trademark line is the source of truth: `SUPER 8`, all caps. Every human-readable occurrence of `Super 8 Studio` / `Super8` was normalised to `SUPER 8 Studio`.
- **Why**: A single registered form avoids ambiguity in marketplace listings and legal text.
- **Alternative**: Keep `Super 8 Studio` title case (rejected — does not match the trademark declaration).

### D2: Product name embeds the trademark, not "API"
`SUPER 8 Studio API Skills` → `SUPER 8 Studio InsightArk Skills`. The descriptive "API" was dropped from the product name in favour of the brand.
- **Why**: "API Skills" is generic and undifferentiated; `InsightArk` is the registered, distinctive mark.
- **Trade-off**: Descriptions that read "Developer API skills for ..." were reworded to "InsightArk Skills for ..." to stay consistent.

### D3: Align identifiers on `insightark-skills`; keep internal ids stable
`bin` and plugin manifest `name` move to `insightark-skills`. Internal skill folder names (`super8-studio-*`) and the shared scripts dir stay as-is.
- **Why**: User-facing identifiers should match the brand and repo; internal ids are not user-facing and renaming them is high-churn, high-risk, and out of scope.
- **Note**: `scripts/validate-skills.js` reads the `bin` key by literal name, so it had to change in lockstep or `npm run validate` would fail.

### D4: Make the trademark explicit in legal files
Filled the LICENSE copyright placeholder (`Copyright 2026 SUPER 8 Studio`) and added a `NOTICE` per Apache-2.0 §4(d) declaring `InsightArk`, `SUPER 8`, `SUPER 8 Studio` as trademarks.
- **Why**: Apache-2.0 §6 does not grant trademark rights; the NOTICE makes the reservation explicit before public release.

## Risks / Trade-offs

- **Globally-installed CLI command changes name** (`super8-studio-api-skills` → `insightark-skills`) → Mitigation: pre-release, no published global installs exist yet; `npx @8-interactive/insightark-skills` users are unaffected since npx runs the package's single bin regardless of bin name.
- **`validate-skills.js` bin-key drift** → Mitigation: updated in the same commit; `npm run validate` is the guard.
- **Stale internal ids vs new brand** (skill folders still `super8-studio-*`) → Accepted: internal-only, not user-facing; revisit if ever surfaced.

## Migration Plan

Applied as a single commit (`a699af0`) on a branch off `main`. No data migration. Rollback = revert the commit. The release gate (`validate` + `test` + `smoke`) covers the identifier changes.
