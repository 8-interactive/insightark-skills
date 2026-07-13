# Plugin Release Process

Internal reference for cutting a release of this bundle. Not shipped to
customers (`docs/` is excluded from the public mirror tree / CDN tarball).

## Customer distribution (single source)

All customer-facing artifacts come from **one public mirror tree** built in
the `number8-next` monorepo:

```text
write-release.sh → gen-mcp-from-release.sh → npm run validate → build-release-dir.sh
  → validate-release-tree.sh → S3 tarball + publish-to-github.sh --source <same tree>
```

Customers install through:

| Path | Artifact |
| --- | --- |
| **S3 / CDN tarball** | `https://downloads.no8.io/{staging\|main}/releases/skills/insightark-skills-v2-latest.tar.gz` |
| **GitHub mirror** | `https://github.com/8-interactive/insightark-skills` (`staging` or `main` branch) — plugin marketplaces + clone/`install.sh` |
| **Claude / Codex / Cursor plugins** | Marketplace or local repo install from the GitHub mirror |

**Not a customer path:** `npm install`, `npx @8-interactive/insightark-skills`, or
`npm pack` / `npm publish`. The monorepo keeps a **private** root `package.json`
only so maintainers can run `npm run validate` locally and in Drone. That file is
**not** copied into the public mirror tree (`build-release-dir.sh` allowlist).

## Version sources of truth

These files must carry the same version — `npm run validate` checks this:

- `skills/_insightark-shared/VERSION`
- `.codex-plugin/plugin.json`
- `.claude-plugin/plugin.json`
- `.cursor-plugin/plugin.json`

Bump `VERSION` and all three plugin manifests together in the same commit.
`package.json` `version` is optional dev metadata only (not validated for sync).

## Before publishing

1. Run `npm run prepare-release` (or `write-release.sh` + `gen-mcp-from-release.sh` for your branch).
2. Run `npm run validate`.
3. Run `bash scripts/validate-install-harness.sh`.
4. If MCP-facing behavior changed, run the E2E harness against staging (see
   `e2e/HARNESS.md`) before promoting.
5. Update `CHANGELOG.md` with a dated entry.

## Automated publish (staging / main)

On every push to `staging` or `main` in `number8-next`, Drone:

1. Writes `RELEASE` and generates MCP manifests
2. Runs `npm run validate` and `validate-release-tree.sh`
3. Uploads S3 tarball from `/tmp/insightark-skills`
4. Runs `scripts/publish-to-github.sh --ci --source /tmp/insightark-skills`

Branch mapping:

- `number8-next` `staging` → `insightark-skills` `staging`
- `number8-next` `main` → `insightark-skills` `main`

If the bundle is unchanged, GitHub sync is a no-op (no commit, no push).

Drone secrets (GitHub App): `insightark_skills_github_app_id`,
`insightark_skills_github_app_installation_id`,
`insightark_skills_github_app_private_key`.

### Internal staging marketplace install

```bash
claude plugin marketplace add 8-interactive/insightark-skills@staging
claude plugin install insightark-skills@insightark-skills
```

Production (default branch `main`):

```bash
claude plugin marketplace add 8-interactive/insightark-skills
claude plugin install insightark-skills@insightark-skills
```

### Manual GitHub sync (optional)

```bash
DRONE_BRANCH=staging bash tools/insightark-skill/installer/write-release.sh
bash tools/insightark-skill/scripts/gen-mcp-from-release.sh
bash tools/insightark-skill/scripts/build-release-dir.sh --out /tmp/insightark-skills
GITHUB_TOKEN=... bash tools/insightark-skill/scripts/publish-to-github.sh \
  --ci --source /tmp/insightark-skills
```

## Marketplace listings

`claude plugin marketplace add 8-interactive/insightark-skills` and
`codex plugin marketplace add 8-interactive/insightark-skills` read manifests
from the GitHub mirror — no separate marketplace submission step. Keep plugin
`version` fields in sync with `skills/_insightark-shared/VERSION`.

## Retired: npm registry distribution

Historically the public `insightark-skills` GitHub repo published
`@8-interactive/insightark-skills` to npm via tag-triggered GitHub Actions.
That path is **retired**. Do not document `npm install` / `npx` for customers.
Do not re-add `package.json`, `.github/workflows`, or CI-only scripts to the
public mirror tree.
