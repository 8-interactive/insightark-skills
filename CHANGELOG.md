# Changelog

## Unreleased

- **BREAKING**: Re-platform the entire skill bundle from bash to Node (zero
  dependencies, Node 18+). All `.sh` scripts are replaced by `.js`; `curl`,
  `jq`, and `date` are no longer required. Skills, install, credential setup,
  and the doctor health check now run on macOS, Linux, and **native Windows**.
- **BREAKING**: Skill invocation contract changed — `SKILL.md` files now run
  `node <path>` instead of a `.sh` script. Existing bash installs must be
  re-installed.
- Add a pure-Node `npx` installer with a simplified flow: choose location
  (global `~` or repo) → choose coding agent(s) → confirm → install. The
  advanced shared-folder mode remains available via `--target`.
- The `~/.super8-studio.config` install-registry format is preserved.

## 1.0.0

- Add canonical skill bundle installer for direct skills installation.
- Add shared runtime scripts for Super 8 Studio Developer API workflows.
- Add plugin, marketplace, npm, and validation metadata for multi-channel
  installation readiness.
