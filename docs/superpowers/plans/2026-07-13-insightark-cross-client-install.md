# InsightArk Cross-Client Install Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the token-based transition release install InsightArk Skills and one working MCP registration predictably for Claude, Codex, and Cursor, while preserving a later path to OAuth-based one-click authentication.

**Architecture:** Keep workflow Skills platform-neutral. Treat MCP registration and credential injection as platform adapters: Claude keeps its native plugin configuration, while Codex and Cursor use an explicit, user-authorized bootstrap that writes their supported local MCP settings. The release package must contain every bootstrap dependency and must be validated as an installed artifact rather than only as a source checkout.

**Tech Stack:** Bash, Node.js 18+ standard library, TOML, JSON, hosted HTTP MCP, `mcp-remote` bridge for Codex when arbitrary HTTP headers are unavailable.

## Global Constraints

- Do not put `S8_SESSION_TOKEN` in a Git-tracked file, command history, test fixture, log, or documentation example containing a real value.
- Preserve the current zero-runtime-dependency rule for `skills/`; installer helpers may use Node.js 18+ standard-library code only.
- Do not depend on `${user_config.S8_SESSION_TOKEN}` for Codex; it is a Claude-style interpolation contract and is not a reliable Codex credential path.
- Use `0600` permissions for every credential-bearing local file.
- A token created for staging must configure `https://stage-api-next.no8.io/mcp`; a production token must configure `https://api-next.no8.io/mcp`.
- During the transition, a client must have exactly one MCP server named `insightark`; avoid a virtual plugin MCP and a fallback MCP with the same name.
- Do not claim marketplace-only installation is fully automatic until the host exposes a supported install-time secret/configuration hook. The supported transition UX is one user-authorized bootstrap command after plugin installation.

---

## Target install contracts

| Client | Skills delivery | MCP delivery during transition | Credential source |
| --- | --- | --- | --- |
| Claude | `.claude-plugin` | Native Claude MCP manifest | `/plugin configure` managed `S8_SESSION_TOKEN` |
| Codex | `.codex-plugin` | `setup-env.sh --write-client-configs` creates `mcp_servers.insightark` | secure interactive prompt, then Codex MCP environment block |
| Cursor | `.cursor-plugin` | `setup-env.sh --write-client-configs` creates `mcpServers.insightark` | secure interactive prompt, then Cursor MCP headers |

The long-term OAuth release replaces the Codex/Cursor bridge setup with standard HTTP MCP manifests containing `oauth_resource`; it is deliberately not part of this token-transition plan.

## File structure

- Modify: `.codex-plugin/plugin.json` — make Codex Skills-only during the token transition; remove its unreliable virtual MCP declaration.
- Modify: `installer/client-config.sh` — resolve the MCP merge helper from the always-packaged `installer/` directory.
- Create: `installer/merge-client-mcp-config.js` — move the current JSON/TOML merge helper into the packaged installer surface.
- Delete: `scripts/merge-client-mcp-config.js` — remove the obsolete source location after the move.
- Modify: `scripts/build-release-dir.sh` — include the complete installer surface already required by `setup-env.sh`.
- Modify: `scripts/validate-release-tree.sh` — assert the merge helper and Codex bootstrap dependencies are present in a release tree.
- Modify: `scripts/validate-install-harness.sh` — exercise the released `setup-env.sh --write-client-configs` path in a temporary home and check the emitted settings.
- Modify: `README.md` — state the distinct Claude and Codex transition flows and remove the claim that Codex token interpolation is the primary path.
- Modify: `MCP_CLIENT_SETUP.md` — provide exact Codex bootstrap behavior, the one-server rule, and restart verification.
- Modify: `CHANGELOG.md` — record the packaging and install-contract correction.

### Task 1: Establish a single source of truth for the transition contracts

**Files:**
- Modify: `.codex-plugin/plugin.json`
- Modify: `README.md`
- Modify: `MCP_CLIENT_SETUP.md`
- Test: `scripts/validate-skills.sh`

**Interfaces:**
- Consumes: the existing Claude plugin `userConfig.S8_SESSION_TOKEN` contract and the `setup-env.sh --write-client-configs` CLI.
- Produces: a Codex plugin that installs Skills without registering a second, unauthenticated virtual server; a documented `insightark` server created only by the bootstrap.

- [ ] **Step 1: Add a failing manifest-contract check for Codex**

In `scripts/validate-skills.sh`, replace the current expectation that `data.mcpServers` equals `./.mcp.json` with a rejection of that field:

```bash
if node -e 'const d=require(process.argv[1]); process.exit(Object.hasOwn(d, "mcpServers") ? 1 : 0)' \
  "$repo_dir/.codex-plugin/plugin.json"; then
  pass "Codex transition manifest has no virtual MCP server"
else
  fail "Codex transition manifest must not declare mcpServers"
fi
```

- [ ] **Step 2: Run the manifest validation and verify it fails**

Run: `bash scripts/validate-skills.sh`

Expected: failure reporting that the Codex manifest still declares `mcpServers`.

- [ ] **Step 3: Remove the unsupported Codex token path**

Delete the `"mcpServers": "./.mcp.json",` property and the `userConfig` block from `.codex-plugin/plugin.json`. Keep `name`, `version`, `skills`, and `interface` unchanged. The resulting relevant fragment is:

```json
{
  "name": "insightark-skills",
  "version": "2.0.3",
  "skills": "./skills/",
  "interface": {
    "displayName": "SUPER 8 Studio InsightArk Skills"
  }
}
```

- [ ] **Step 4: Rewrite Codex documentation around the supported transition flow**

In both English and Chinese sections of `README.md` and `MCP_CLIENT_SETUP.md`, replace the assertion that Codex prompts for `S8_SESSION_TOKEN` at plugin install with this behavior:

```text
Install the InsightArk Skills plugin. Then run ./setup-env.sh --write-client-configs
from the installed bundle. The command prompts without echoing the token,
writes the client MCP registration, and requires a Codex restart.
```

State that `codex mcp login insightark` is not applicable because the transition server uses `_SessionToken`, not OAuth.

- [ ] **Step 5: Run manifest and documentation checks**

Run: `bash scripts/validate-skills.sh`

Expected: all checks pass and the Codex contract says it has no virtual MCP server.

- [ ] **Step 6: Commit the contract change**

```bash
git add .codex-plugin/plugin.json README.md MCP_CLIENT_SETUP.md scripts/validate-skills.sh
git commit -m "fix: make Codex MCP setup explicit"
```

### Task 2: Package the MCP configuration helper with the installer

**Files:**
- Create: `installer/merge-client-mcp-config.js`
- Delete: `scripts/merge-client-mcp-config.js`
- Modify: `installer/client-config.sh`
- Modify: `scripts/build-release-dir.sh`
- Test: `scripts/validate-release-tree.sh`

**Interfaces:**
- Consumes: `super8_merge_client_mcp_configs(mcp_url, session_token)` from `installer/client-config.sh`.
- Produces: a release-resident helper at `installer/merge-client-mcp-config.js` that merges `~/.cursor/mcp.json` and `~/.codex/config.toml` without deleting unrelated entries.

- [ ] **Step 1: Add a failing release-tree assertion for the helper**

Add this requirement after the existing installer checks in `scripts/validate-release-tree.sh`:

```bash
require_path "installer/merge-client-mcp-config.js"
```

- [ ] **Step 2: Build a temporary release tree and verify the new check fails**

Run:

```bash
tmpdir="$(mktemp -d)"
DRONE_BRANCH=staging bash installer/write-release.sh
bash scripts/gen-mcp-from-release.sh
bash scripts/build-release-dir.sh --out "$tmpdir/release"
bash scripts/validate-release-tree.sh --dir "$tmpdir/release"
```

Expected: failure stating `installer/merge-client-mcp-config.js` is missing from the release tree. Remove the generated `skills/_insightark-shared/RELEASE`, `.mcp.json`, and `mcp.json` before continuing so the checkout returns to its pre-test state.

- [ ] **Step 3: Move the helper and update its resolver**

Move `scripts/merge-client-mcp-config.js` to `installer/merge-client-mcp-config.js`. In `installer/client-config.sh`, replace the `merge_script` assignment with:

```bash
merge_script="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/merge-client-mcp-config.js"
```

The Node helper must keep these two public outputs unchanged:

```text
Cursor:  mcpServers.insightark.url + headers._SessionToken
Codex:   [mcp_servers.insightark] + [mcp_servers.insightark.env]
```

- [ ] **Step 4: Make the release allowlist explicit**

In `scripts/build-release-dir.sh`, replace the individual `scripts/register-install.sh` entry with no additional `scripts/` entries; the moved helper is now covered by the existing `installer/` directory entry. Add this comment immediately above the `installer/` entry:

```bash
# Contains all setup-env.sh runtime helpers, including MCP configuration merge.
```

- [ ] **Step 5: Rebuild and validate the release tree**

Run the Task 2 Step 2 command again.

Expected: `installer/merge-client-mcp-config.js present in release tree` and `Release tree validation passed.`

- [ ] **Step 6: Commit the packaged-helper fix**

```bash
git add installer scripts/build-release-dir.sh scripts/validate-release-tree.sh
git rm scripts/merge-client-mcp-config.js
git commit -m "fix: package Codex MCP configuration helper"
```

### Task 3: Test the released bootstrap instead of only its source tree

**Files:**
- Modify: `scripts/validate-install-harness.sh`
- Modify: `e2e/local_mcp_case.sh`
- Test: `scripts/validate-install-harness.sh`

**Interfaces:**
- Consumes: the release tree built by `scripts/build-release-dir.sh`, `SUPER8_TOOL_HOME`, and a synthetic `S8_SESSION_TOKEN`.
- Produces: a regression test proving `setup-env.sh --write-client-configs` finds the helper and writes an enabled Codex MCP server without exposing the synthetic token in output.

- [ ] **Step 1: Add a failing release-bootstrap case**

In `scripts/validate-install-harness.sh`, after the existing temporary-home setup, add a release build and run the copied setup script with the existing harness token:

```bash
release_dir="$tmpdir/release"
DRONE_BRANCH=staging bash "$repo_dir/installer/write-release.sh"
bash "$repo_dir/scripts/gen-mcp-from-release.sh"
bash "$repo_dir/scripts/build-release-dir.sh" --out "$release_dir"
SUPER8_TOOL_HOME="$tmpdir" \
  "$release_dir/setup-env.sh" \
  --session-token "r:harness-test-token" \
  --write-client-configs \
  --skip-doctor
```

- [ ] **Step 2: Run the harness and verify it fails before Task 2 is implemented**

Run: `bash scripts/validate-install-harness.sh`

Expected: failure containing `Missing merge script` from the copied release package.

- [ ] **Step 3: Assert the generated Codex configuration is structurally correct**

After the bootstrap call, add:

```bash
if rg -q '^\[mcp_servers\.insightark\]$' "$tmpdir/.codex/config.toml" \
  && rg -q '^\[mcp_servers\.insightark\.env\]$' "$tmpdir/.codex/config.toml" \
  && rg -q 'stage-api-next\.no8\.io/mcp' "$tmpdir/.codex/config.toml"; then
  pass "release bootstrap writes staged Codex InsightArk MCP"
else
  fail "release bootstrap did not write the expected Codex InsightArk MCP"
fi
```

Do not print the configuration file; it contains the harness credential.

- [ ] **Step 4: Assert unrelated MCP configuration survives**

Seed `$tmpdir/.codex/config.toml` with a distinct section before the bootstrap:

```toml
[mcp_servers.example]
command = "example-mcp"
```

Then assert `^\[mcp_servers\.example\]$` remains present after setup. This protects users with existing MCP registrations.

- [ ] **Step 5: Run the focused and full validation suite**

Run:

```bash
bash scripts/validate-install-harness.sh
npm run validate
```

Expected: both commands exit `0`; the release-bootstrap assertion passes and no output includes `r:harness-test-token`.

- [ ] **Step 6: Commit the release bootstrap regression test**

```bash
git add scripts/validate-install-harness.sh e2e/local_mcp_case.sh
git commit -m "test: cover released Codex MCP bootstrap"
```

### Task 4: Make installation state and failure recovery unambiguous

**Files:**
- Modify: `setup-env.sh`
- Modify: `skills/_insightark-shared/scripts/doctor.sh`
- Modify: `README.md`
- Modify: `MCP_CLIENT_SETUP.md`
- Modify: `CHANGELOG.md`
- Test: `scripts/validate-install-harness.sh`

**Interfaces:**
- Consumes: the user-selected release API URL, `S8_SESSION_TOKEN`, and `--write-client-configs`.
- Produces: clear state transitions: credentials written, client config written, health check passed or failed; each error includes a recovery action without printing the credential.

- [ ] **Step 1: Write failing shell assertions for setup output**

Extend the install harness to require these non-secret messages from a successful `--skip-doctor` bootstrap:

```bash
Wrote ~/.codex/config.toml (mode 600)
```

and to reject this message:

```bash
Missing merge script:
```

- [ ] **Step 2: Make setup failure state precise**

In `setup-env.sh`, wrap the merge call so failure describes the durable state already written:

```bash
if ! super8_merge_client_mcp_configs "$(super8_resolve_mcp_url "$api_url")" "$session_token"; then
  printf 'Credential file was written, but client MCP registration failed. Re-run ./setup-env.sh --write-client-configs after fixing the release package.\n' >&2
  exit 1
fi
```

- [ ] **Step 3: Make doctor distinguish transport failure from token failure**

In `doctor.sh`, only call `print_token_onboarding` after an HTTP `401` response. For `404`, print:

```text
InsightArk MCP endpoint was not found. Verify the release channel and MCP URL before replacing the token.
```

For `429`, preserve the rate-limit message. This prevents a bad endpoint from being misreported as a bad token.

- [ ] **Step 4: Document one source of truth per client**

Add a table to both documentation files stating:

```text
Claude: native plugin configuration; do not create a duplicate Codex-style server.
Codex: setup-env.sh --write-client-configs; restart Codex; inspect `codex mcp list`.
Cursor: setup-env.sh --write-client-configs; reload MCP servers.
```

Include a warning that only one server named `insightark` may be registered per client.

- [ ] **Step 5: Run verification**

Run:

```bash
bash scripts/validate-install-harness.sh
npm run validate
```

Expected: all checks pass; a 404 health-check fixture produces the endpoint guidance rather than the token-onboarding guidance.

- [ ] **Step 6: Commit the recovery guidance**

```bash
git add setup-env.sh skills/_insightark-shared/scripts/doctor.sh README.md MCP_CLIENT_SETUP.md CHANGELOG.md scripts/validate-install-harness.sh
git commit -m "fix: clarify InsightArk MCP setup recovery"
```

### Task 5: Run the real-client acceptance checklist and prepare the OAuth follow-up

**Files:**
- Modify: `docs/implementation/plugin-release-process.md`
- Modify: `CHANGELOG.md`
- Test: manual Claude, Codex, and Cursor acceptance runs using non-production test organizations

**Interfaces:**
- Consumes: platform-specific release archives and valid staging test credentials owned by the release tester.
- Produces: a release gate that establishes Skills availability, MCP tool discovery, authentication, and environment correctness on every supported client.

- [ ] **Step 1: Add the release acceptance checklist**

Add these mandatory checks to `docs/implementation/plugin-release-process.md`:

```text
1. Install the Claude archive; configure a staging token; call auth_me.
2. Install the Codex archive; run setup-env.sh --write-client-configs; restart; run codex mcp list; call auth_me.
3. Install the Cursor archive; run setup-env.sh --write-client-configs; reload MCP; call auth_me.
4. Confirm insightark-conversations can list a test organization's recent conversations.
5. Confirm the selected archive's MCP URL exactly matches the release channel.
6. Revoke the staging token after the manual acceptance run.
```

- [ ] **Step 2: Define the OAuth exit criterion**

Add a short follow-up section stating that the token bootstrap may be retired only when both Claude and Codex can install the same standard OAuth MCP endpoint, complete authorization through their platform UI, and call `auth_me` without a manually supplied `_SessionToken`.

- [ ] **Step 3: Run the automated gate**

Run: `npm run validate && bash scripts/validate-install-harness.sh`

Expected: exit `0` before starting manual acceptance.

- [ ] **Step 4: Perform the three manual acceptance runs**

Use separate staging tokens and record only: client version, release channel, MCP URL, whether Skills appeared, whether `auth_me` passed, and whether the conversation list passed. Do not record tokens, customer content, or user email addresses.

- [ ] **Step 5: Commit release-gate documentation**

```bash
git add docs/implementation/plugin-release-process.md CHANGELOG.md
git commit -m "docs: add cross-client MCP release gate"
```

## Self-review

- **Spec coverage:** Tasks 1–2 address the incompatible Codex manifest and missing package file; Task 3 proves the shipped artifact works; Task 4 gives users precise recovery; Task 5 prevents regression and defines the OAuth transition boundary.
- **Placeholder scan:** The plan has no unspecified files, interfaces, test commands, or acceptance criteria.
- **Type consistency:** The only configuration names used throughout are `S8_SESSION_TOKEN`, `mcp_servers.insightark`, `mcpServers.insightark`, and `insightark`.

## Execution handoff

Execute in task order. Do not combine Tasks 1–2 into one commit: the manifest contract and the packaging repair are independently reviewable. Use staging-only credentials for all manual checks and revoke them afterward.
