## Context

The bundle ships ~24 thin bash command scripts (`skills/_super8-studio-api-shared/scripts/*.sh`) plus three core libs — `env.sh` (credential load order), `http.sh` (curl wrapper), `output.sh` (jq-based JSON printing) — and two config libs (`install-config.sh`, `release.sh`). Each `SKILL.md` names a `.sh` script. Installation is a bash flow (`install.sh` + `installer/common.sh`) reachable through `npx super8-studio-api-skills install`, which spawns `bash`. Credential setup (`setup-env.sh`) and the doctor health check are bash too.

This design replaces all of that with Node so install, credential setup, and skill runtime work on macOS, Linux, and native Windows. The decisions below were settled during exploration (`/opsx:explore`).

## Goals / Non-Goals

**Goals:**
- Skills run on native Windows with no bash, WSL, `curl`, or `jq`.
- A single `npx` install flow: location (global/repo) → agent(s) → confirm → install.
- Shipped skill scripts are zero-dependency (Node stdlib only; no `node_modules` in agent skill folders).
- Preserve credential load-order semantics and the `~/.super8-studio.config` registry format.

**Non-Goals:**
- No Rust / compiled-binary distribution. Node + `npx` is the chosen platform (Node 18+ is already required by `npx` and by every skill).
- No dual-shipping of `.sh` and `.js` — hard cut.
- No change to the Developer API contract, routes, or auth model.
- No change to the agent set (claude-code, opencode, cursor, github-copilot, codex) or their skill subpaths.

## Decisions

### D1: Node 18+ stdlib, zero runtime dependencies
Use global `fetch` (Node 18+), `JSON`, `Date`, `node:fs`, `node:path`, `node:os`, `node:readline`. No npm dependencies in shipped scripts.
- **Why**: Keeps agent skill folders free of `node_modules`, keeps `npx` cold-start instant, and removes the `curl`/`jq`/`date` external-tool requirement.
- **Alternatives**: `undici`/`got` (rejected — adds deps); `prompts`/`inquirer` for the installer (rejected — even the installer stays zero-dep using `node:readline`).

### D2: Hard cut `.sh` → `.js`, one `.js` per command
Each `*.sh` becomes a sibling `*.js` with `#!/usr/bin/env node`; the `.sh` files are deleted. Keep the per-command file layout (not a single multi-command CLI) to minimize `SKILL.md` churn.
- **Why**: One-to-one mapping keeps the diff reviewable and each `SKILL.md` edit mechanical (path + runner only).
- **Alternatives**: Single `s8 <command>` binary (rejected — larger `SKILL.md` rewrite, conflates with the installer CLI); dual-ship (rejected by decision — doubles maintenance, drift risk).

### D3: Invocation contract = `node <path>`
`SKILL.md` instructs the agent to run `node ../_super8-studio-api-shared/scripts/<command>.js <args>`.
- **Why**: Shebangs are unreliable on Windows; `node <path>` is portable and explicit. This is the load-bearing change for cross-platform *runtime*.

### D4: `env.js` preserves exact load order and priority
Replicate `env.sh` precedence: process env / `CLAUDE_PLUGIN_OPTION_*` (highest) → repo `./.super8-studio.env` → skills-install-dir env (from registry) → user `~/.super8-studio.env`. Map `CLAUDE_PLUGIN_OPTION_S8_*` to `S8_*` when the process env is unset. Reproduce the missing-credentials help text and the load-priority explanation.
- **Why**: Credential resolution is subtle (`env.sh:36-102`); a regression silently breaks auth. This is the highest-risk port.
- **Note**: Parse `.env` files in JS (simple `KEY=value`), not by sourcing a shell.

### D5: Registry format preserved, reader becomes `install-config.js`
Keep `~/.super8-studio.config` as `key=value` lines (`layout`, `base_dir`, `agents`, `skills_targets`, `installed_at`) with mode `600`. The Node code both writes and reads it.
- **Why**: Forward/backward consistency and avoids re-teaching the runtime a new format. Even though it is a hard cut, keeping the format avoids breaking a registry a user may already have.

### D6: Installer flow = location → agents → confirm
Interactive: Step 1 location (`global` = `os.homedir()`, `repo` = `process.cwd()`); Step 2 agent multi-select (numbers / ids / `all`); Step 3 confirm and copy. Target = `{base}/{agent-subpath}`. Non-interactive flags: `--location global|repo` (or `--base-dir PATH`), `--agents LIST`, `--target PATH` (advanced shared-folder, mutually exclusive with `--agents`).
- **Why**: Collapses the old shared-vs-peragent → agents → user-vs-project maze into the simpler order the user specified.
- **Alternatives for repo base**: git-root discovery or prompt-for-path (rejected — `$CWD` is the least surprising default).

### D7: Copy semantics unchanged
Copy `super8-studio-*` and `_super8-studio-*` directories; remove existing same-named dirs in the target first (clean replace). Use `fs.cpSync(..., {recursive: true})`. `chmod +x` becomes a no-op concern (we invoke via `node`), but set executable bit on POSIX where harmless.

### D8: Cross-platform paths
All path building via `node:path`; expand a leading `~` to `os.homedir()` explicitly (no shell expansion). Registry and env paths anchored at `os.homedir()`.

## Risks / Trade-offs

- **`env.js` load-order regression** → Port `env.sh` precedence with a focused test matrix (process env, plugin-option mapping, repo file, skills-dir file, user file, and combinations); diff behavior against the bash version before deleting `.sh`.
- **Date-window math drift** (`s8_iso_days_ago`, macOS vs GNU `date`) → Replace with `Date` arithmetic emitting ISO-8601 UTC; verify N-days-ago output matches the bash output for representative N.
- **`fetch` error handling parity** → Reproduce 401 / 429 / non-2xx messages and body echo from `http.sh`/`s8_expect_success`; ensure non-zero exit codes match so agents detect failures.
- **Existing bash installs** → Hard cut means users must re-install; document in README and CHANGELOG. Registry format preservation limits breakage to the scripts themselves.
- **Windows skill execution by agents** → Agents must invoke `node <path>`; verify the updated `SKILL.md` wording is unambiguous so agents don't try to `bash` the file.
- **Zero-dep prompt UX** → `node:readline` is plainer than `prompts`; acceptable trade-off to keep `npx` dependency-free.

## Migration Plan

1. Port core libs first: `env.js`, `http.js`, `output.js`, `install-config.js`, `release.js`.
2. Port the ~24 command scripts to `.js` against the new libs.
3. Update ~24 `SKILL.md` files to the `node <path>` contract.
4. Build the Node installer (install/uninstall/setup/doctor) and rewire `cli.js`.
5. Delete the bash scripts (`*.sh`, `install.sh`, `uninstall.sh`, `setup-env.sh`, `installer/common.sh`).
6. Update plugin manifests, `package.json` (`files`/`bin`), and README (EN + 中文).
7. **Rollback**: revert the change set; the deleted `.sh` files return via git. No persisted state changes beyond the registry, whose format is unchanged.

## Open Questions

- Should `validate-skills.sh` / `register-install.sh` / `installer/write-release.sh` also be ported to Node now, or left as repo-only dev tooling (not shipped to skill folders)? Leaning: port only what ships; keep dev-only bash if it never runs on a user's machine.
