## 1. Release prerequisites

- [x] 1.1 Merge PR #2 (Node re-platform) and PR #3 (fix-api-url-at-install) to `main` — merged via #2, #5 (superseded #3), #4, and #6 (release tooling)
- [ ] 1.2 Add `NPM_TOKEN` (automation token with publish rights to `@8-interactive`) to repo CI secrets — a token was added but the first publish hit `EOTP`; must be a **Classic Automation** token to bypass 2FA in CI (pending re-issue)

## 2. Package identity & access

- [x] 2.1 Change `package.json` `name` to `@8-interactive/insightark-skills` (leave `bin` and plugin identifiers unchanged)
- [x] 2.2 Set `package.json` `publishConfig.access` to `public`
- [x] 2.3 Confirm intended first public version in `package.json` / bundle `VERSION` / both plugin manifests (keep version sync green)

## 3. CI publish-on-tag

- [x] 3.1 Add a CI job that triggers on a pushed version tag and runs `npm run validate`, `npm test`, `npm run smoke` as a gate
- [x] 3.2 On gate pass, run `npm publish` using `NPM_TOKEN`; ensure no publish occurs if any check fails
- [x] 3.3 Confirm the publish job does not echo the token and runs on a clean checkout

## 4. Docs & client steering

- [x] 4.1 Update all `npx` commands in README (EN + 中文) and CHANGELOG to `@8-interactive/insightark-skills`
- [x] 4.2 Steer Claude Code / Codex clients to `npx @8-interactive/insightark-skills install --agents claude-code|codex`; mark the plugin-marketplace path as available when the repo is public
- [x] 4.3 Update openspec references to the new npx command where relevant

## 5. Pre-publish verification

- [x] 5.1 Run `npm pack` and confirm the tarball contains only the `files` allowlist (no `openspec/`, `test/`, agent-guidance, or git history)
- [x] 5.2 Scan the shipped files for secrets/tokens
- [x] 5.3 Dry-run the release gate (validate + test + smoke) on the release commit

## 6. Release & verify

- [ ] 6.1 Tag the release and let CI publish to public npm
- [ ] 6.2 Verify end-to-end: `npx @8-interactive/insightark-skills@<version> install` installs for a representative agent with no repo/npm auth
- [ ] 6.3 Verify `npx @8-interactive/insightark-skills install --agents claude-code` installs skills into the Claude Code folder
