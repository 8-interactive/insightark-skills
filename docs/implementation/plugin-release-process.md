# Plugin Release Process

Internal reference for cutting a release of this bundle. Not shipped to
customers (`docs/` is excluded from the npm package and CDN tarball).

## Version sources of truth

Four files must carry the same version — `npm run validate` checks this:

- `package.json`
- `skills/_insightark-shared/VERSION`
- `.codex-plugin/plugin.json`
- `.claude-plugin/plugin.json`

Never bump them by hand; use `npm version <patch|minor|major|x.y.z>`, which
bumps `package.json` and should sync the other three (see
`scripts/sync-versions.js` if present, otherwise update the remaining three
files in the same commit).

## Before tagging

1. Run `bash scripts/validate-skills.sh`.
2. Run `node scripts/validate-mcp-skills.js`.
3. If MCP-facing behavior changed, run the E2E harness against staging (see
   `tools/insightark-skill/e2e/HARNESS.md` in the source monorepo) before
   promoting.
4. Update `CHANGELOG.md` with a dated entry.

## Two distribution channels

This bundle ships through two independent channels — keep both in sync:

| Channel | Source of truth | Trigger |
| --- | --- | --- |
| S3 / CDN tarball (`downloads.no8.io/{branch}/releases/skills/...`) | `number8-next` monorepo, built by Drone (`.drone.yml`) | push to `staging` / `main` in the monorepo |
| GitHub repo + npm (`@8-interactive/insightark-skills`) + plugin marketplaces | `8-interactive/insightark-skills` GitHub repo | Drone `publish-to-github.sh --ci` on `number8-next` `staging`/`main` push; npm via `v*` tag on GitHub repo |

## Publishing to the GitHub repo / npm

### Automated sync (staging / main)

On every push to `staging` or `main` in `number8-next`, Drone runs
`scripts/publish-to-github.sh --ci` after `npm run validate`:

- `number8-next` `staging` → `insightark-skills` `staging` branch
- `number8-next` `main` → `insightark-skills` `main` branch

No review branch (`sync/...`) is created. If the bundle is unchanged, the
step is a no-op (no commit, no push).

Requires Drone secrets:

- `insightark_skills_github_app_id` — e.g. `4244140`
- `insightark_skills_github_app_installation_id` — e.g. `145139908`
- `insightark_skills_github_app_private_key` — full `.pem` private key contents

The App must be installed on `8-interactive` with `insightark-skills` repository
access and **Contents: Read and write**. Alternatively, set `GITHUB_TOKEN` to a
PAT for local runs.

Internal staging marketplace install:

```bash
claude plugin marketplace add 8-interactive/insightark-skills@staging
claude plugin install insightark-skills@insightark-skills
```

Production (default branch `main`):

```bash
claude plugin marketplace add 8-interactive/insightark-skills
claude plugin install insightark-skills@insightark-skills
```

### Manual sync (optional)

```bash
GITHUB_TOKEN=... bash tools/insightark-skill/scripts/publish-to-github.sh \
  --clone-to /tmp/insightark-skills --branch staging --push
```
1. Ensure `main` on `insightark-skills` is up to date (Drone sync on
   `number8-next` `main` push).
2. Tag the GitHub repo with `vX.Y.Z` matching `package.json` and push the tag.
3. Pushing the tag triggers `.github/workflows/release.yml`, which verifies
   the tag matches `package.json`, runs `npm run validate`, then
   `npm publish`. A prerelease version (`1.0.0-rc.1`) publishes under the
   `next` dist-tag.

## Marketplace listings

`claude plugin marketplace add 8-interactive/insightark-skills` and
`codex plugin marketplace add 8-interactive/insightark-skills` read
`.claude-plugin/marketplace.json` / `.agents/plugins/marketplace.json`
directly from the GitHub repo — there is no separate marketplace submission
step. Keep both manifests' `version` fields in sync with the release.
