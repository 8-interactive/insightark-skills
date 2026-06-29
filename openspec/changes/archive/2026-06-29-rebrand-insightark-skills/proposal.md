## Why

The product carried three inconsistent names (`Super 8 Studio`, `Super8`, and the descriptive `... API Skills`) while the company's registered trademark **InsightArk** appeared only in the npm package name and never in any user-facing surface. The `publish-to-public-npm` change deliberately deferred aligning the `bin` and plugin-manifest identifiers; the GitHub repo was also renamed to `8-interactive/insightark-skills`, leaving stale URLs throughout. This change settles the brand identity before public release.

## What Changes

- Standardise the company/brand name to **`SUPER 8 Studio`** (all-caps `SUPER 8`) everywhere it appears in human-readable text.
- Rename the product from `SUPER 8 Studio API Skills` to **`SUPER 8 Studio InsightArk Skills`**, surfacing the registered `InsightArk` trademark in display names, descriptions, README, and the setup guide.
- **BREAKING (identifier)**: Rename the `bin` command `super8-studio-api-skills` → `insightark-skills` (resolves the deferral from `publish-to-public-npm`). Globally-installed CLIs change command name; `npx @8-interactive/insightark-skills` is unaffected.
- **BREAKING (identifier)**: Rename the plugin manifest `name` in `.claude-plugin/`, `.codex-plugin/`, and `.agents/plugins/` from `super8-studio-api-skills` → `insightark-skills`.
- Update the GitHub repository URL to `https://github.com/8-interactive/insightark-skills` (also fixing a stale `no8io/...` clone URL).
- Fill the LICENSE copyright line (`Copyright 2026 SUPER 8 Studio`) and add a `NOTICE` file declaring `InsightArk`, `SUPER 8`, and `SUPER 8 Studio` as trademarks.

## Capabilities

### New Capabilities
- `brand-identity`: The canonical product and company names, casing rules, the trademark/attribution declaration (NOTICE + LICENSE copyright), and where each brand string must appear in user-facing surfaces.

### Modified Capabilities
- `distribution`: The `bin` command name and plugin-manifest identifiers are now `insightark-skills` (previously `super8-studio-api-skills`, with the npm name allowed to differ). The package name, `bin` name, and plugin identifiers are now aligned.

## Impact

- **Identifiers**: `package.json` `bin` key; plugin `name` in `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `.codex-plugin/plugin.json`, `.agents/plugins/marketplace.json`.
- **Code**: `scripts/validate-skills.js` (reads `bin` key by name), `scripts/super8-skills-cli.js` usage text, `scripts/register-install.js`, `installer/install.js`, `installer/uninstall.js`, `skills/_super8-studio-api-shared/scripts/lib/env.js` (user-facing messages only — no behavior change).
- **Docs/UI**: `README.md` (EN + 中文), `Introduction.html`, `CHANGELOG.md`, `SECURITY.md`, `docs/**`, all `skills/*/SKILL.md`.
- **Legal**: `LICENSE` copyright line; new `NOTICE` file.
- **No runtime/behavior change**: API calls, credential load order, install targets, and the install registry format are untouched.
