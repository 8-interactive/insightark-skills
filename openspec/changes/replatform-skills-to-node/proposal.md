## Why

The Super 8 Studio skill bundle is implemented entirely in bash and depends on `curl`, `jq`, and `date` at runtime, so the skills cannot run on native Windows (no WSL/Git Bash) and silently require external tools elsewhere. We want a single `npx` install flow that lets a user pick where and which coding agent to install into, and skills that run identically on macOS, Linux, and native Windows.

## What Changes

- **BREAKING**: Re-platform every skill script from bash (`.sh`) to Node (`.js`). Hard cut — no dual-shipping of `.sh` and `.js`.
- Replace external-tool dependencies with Node stdlib: `curl` → `fetch`, `jq` → `JSON`, `date` → `Date`. Shipped skill scripts stay **zero-dependency** (no `node_modules` in agent skill folders).
- **BREAKING**: Skill invocation contract changes — `SKILL.md` files instruct the agent to run `node <path>` instead of naming a `.sh` script (~24 files).
- Add a pure-Node `npx` installer with a simplified interactive flow: **install location (global `~` | repo `$CWD`) → select coding agent(s) → confirm → install**. The installer never spawns `bash`.
- Keep non-interactive flags (`--location`/`--base-dir`, `--agents`, `--target`) for automation; the advanced custom-shared-folder mode survives as `--target` only (removed from the interactive path).
- Re-platform credential setup and the doctor health check off bash so configuration also works on native Windows.
- Update `cli.js` (npx `bin`) to call the Node installer directly instead of `bash install.sh`.
- Keep the install registry (`~/.super8-studio.config`) format intact; its reader becomes `install-config.js`.
- Update Claude Code and Codex plugin manifests and README (EN + 中文) for the new install flow.

## Capabilities

### New Capabilities
- `skill-runtime`: How skills resolve credentials, call the Developer API, and emit output at runtime — Node-based, zero-dependency, cross-platform (env load order, HTTP/error handling, JSON output, `node <path>` invocation contract).
- `skill-installer`: The `npx` install/uninstall experience — interactive location→agents→confirm flow, non-interactive flags, agent registry, target resolution, and install-registry management.
- `credential-setup`: Configuring API credentials and verifying connectivity — env file creation, load-priority help, and the doctor health check — running on Node without bash.

### Modified Capabilities
<!-- No existing specs in openspec/specs/; all capabilities are new. -->

## Impact

- **Code**: `skills/_super8-studio-api-shared/scripts/**` (~24 command scripts + `lib/{env,http,output,install-config,release}.sh` → `.js`); `skills/**/SKILL.md` (~24 files); `install.sh`, `uninstall.sh`, `setup-env.sh`, `installer/common.sh` → Node installer; `scripts/super8-skills-cli.js`.
- **Dependencies**: Drops runtime need for `curl`/`jq`/`date`; requires Node 18+ (already declared in `package.json` `engines`). No new npm dependencies shipped into skill folders.
- **Distribution**: `.claude-plugin/` and `.codex-plugin/` manifests; `package.json` `files`/`bin`; README (EN + 中文).
- **Platforms**: Adds native Windows support for install, credential setup, and skill runtime.
- **Compatibility**: Existing bash installs must be re-installed; the `~/.super8-studio.config` registry format is preserved.
