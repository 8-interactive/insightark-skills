# Plugin Release Process

## Versioning

Keep these versions synchronized:

- `.codex-plugin/plugin.json`
- `.claude-plugin/plugin.json`
- `.claude-plugin/marketplace.json`
- `package.json`
- `skills/_super8-studio-api-shared/VERSION`

## Release Checklist

1. Run `bash scripts/validate-skills.sh`.
2. Confirm `skills/_super8-studio-api-shared/RELEASE` is generated only during
   release packaging.
3. Confirm the tarball contains `skills/`, root install scripts, `installer/`,
   `scripts/`, docs, and plugin metadata.
4. Test direct install into a temporary target.
5. Test the package binary with `node scripts/super8-skills-cli.js --help`.
6. Test Codex marketplace discovery against `.agents/plugins/marketplace.json`.
7. Test Claude marketplace discovery against `.claude-plugin/marketplace.json`.
8. Verify the current `npx skills add --...` contract before publishing the
   Vercel skills-add path.

## Channel Mapping

- `staging` publishes staging tarballs and should use npm prerelease or beta
  tags when npm publishing is enabled.
- `main` publishes production tarballs and should use npm latest tags when npm
  publishing is enabled.

## Authentication

Installation only places skills and writes install registry metadata. Users
still need to run `./setup-env.sh` or the package equivalent to create and
validate Developer API credentials.

Marketplace installs should not be described as running install hooks unless
the target platform documents that behavior. Treat registry writes as optional
for marketplace and external skills-manager paths.
