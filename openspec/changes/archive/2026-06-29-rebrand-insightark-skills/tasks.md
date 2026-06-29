<!-- All tasks were applied retroactively in commit a699af0 ("feat: rebrand to SUPER 8 Studio InsightArk Skills"). -->

## 1. Canonical brand casing

- [x] 1.1 Normalise every human-readable `Super 8 Studio` / `Super8` to `SUPER 8 Studio` (README EN+中文, CHANGELOG, SECURITY, Introduction.html, docs, all SKILL.md)
- [x] 1.2 Set publisher/owner fields (`author.name`, `owner.name`, `developerName`) to `SUPER 8 Studio` in all manifests

## 2. Product name → InsightArk

- [x] 2.1 Rename `SUPER 8 Studio API Skills` → `SUPER 8 Studio InsightArk Skills` in manifest display fields, README titles, and Introduction.html
- [x] 2.2 Reword descriptive "Developer API skills for ..." copy to "InsightArk Skills for ..." in plugin descriptions and package.json

## 3. Identifier alignment (BREAKING)

- [x] 3.1 Rename `package.json` `bin` key `super8-studio-api-skills` → `insightark-skills`
- [x] 3.2 Update `scripts/validate-skills.js` to read the new `bin` key (keeps `npm run validate` green)
- [x] 3.3 Update CLI usage text in `scripts/super8-skills-cli.js` and user-facing messages in `installer/install.js`, `installer/uninstall.js`, `scripts/register-install.js`, `skills/_super8-studio-api-shared/scripts/lib/env.js`
- [x] 3.4 Rename plugin `name` → `insightark-skills` in `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `.codex-plugin/plugin.json`, `.agents/plugins/marketplace.json`

## 4. Repository URL

- [x] 4.1 Update GitHub URL to `https://github.com/8-interactive/insightark-skills` in all manifests and docs (also fix stale `no8io/...` clone URL and tarball filenames)

## 5. Legal / trademark

- [x] 5.1 Fill LICENSE copyright line: `Copyright 2026 SUPER 8 Studio`
- [x] 5.2 Add `NOTICE` declaring `InsightArk`, `SUPER 8`, `SUPER 8 Studio` as trademarks (Apache-2.0 §6)

## 6. Verification

- [x] 6.1 Confirm zero remaining `Super 8 Studio` / `Super8` / `super8-studio-api-skills` in user-facing surfaces (grep)
- [x] 6.2 Run `npm run validate` + `npm test` + `npm run smoke` (release gate) on the rebrand commit
