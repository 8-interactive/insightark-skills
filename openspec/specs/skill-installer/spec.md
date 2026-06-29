# skill-installer Specification

## Purpose

Defines the npx-based Node installer for the Super 8 Studio skill bundle: its entry point, interactive and non-interactive flows, supported coding agents, copy semantics, and install registry management.

## Requirements

### Requirement: npx install entry point

The package SHALL expose a Node `bin` that runs the installer without spawning bash, so `npx <package> install` works on macOS, Linux, and native Windows.

#### Scenario: Install via npx on Windows

- **WHEN** a user runs `npx <package> install` on native Windows
- **THEN** the installer runs as a Node process and completes without invoking bash

### Requirement: Interactive install flow

The interactive installer SHALL prompt in this order: (1) install location — global (`~`) or repo (current working directory); (2) which coding agent(s) to install for; (3) confirmation before copying. Skills SHALL be installed to `{base}/{agent-subpath}` for each selected agent. After copying, an interactive install SHALL verify authentication: it resolves the token and checks it against `/developer/v1/auth/me`; on success it reports the authenticated account; when no token is resolvable or the check returns `401`, it SHALL prompt "Log in now? [Y/n]" (default yes) and, if accepted, run the `login` flow; on a network/5xx/429 error it SHALL warn without launching login. A non-interactive install (flags, `--target`, or no TTY) SHALL NOT launch login and SHALL instead print guidance to run `login`.

#### Scenario: Global install for selected agents

- **WHEN** the user chooses global, selects Claude Code and Cursor, and confirms
- **THEN** skills are installed to `~/.claude/skills` and `~/.cursor/skills`

#### Scenario: Repo install uses current directory

- **WHEN** the user chooses repo and selects Codex
- **THEN** skills are installed to `<cwd>/.codex/skills`

#### Scenario: Cancel at confirmation

- **WHEN** the user declines at the confirmation step
- **THEN** no files are copied and no registry is written

#### Scenario: Verify existing token after install

- **WHEN** an interactive install finishes and a resolvable token passes `/developer/v1/auth/me`
- **THEN** the installer reports the authenticated account and does not prompt to log in

#### Scenario: Offer login when token missing or invalid

- **WHEN** an interactive install finishes and there is no token, or the token returns `401`
- **THEN** the installer asks "Log in now? [Y/n]" and runs `login` if accepted

#### Scenario: Non-interactive install does not launch login

- **WHEN** install runs with `--agents`/`--target` or without a TTY
- **THEN** it does not launch login and prints guidance to run `login`

### Requirement: Agent selection

The installer SHALL support the agents claude-code, opencode, cursor, github-copilot, and codex, each mapped to its skills subpath (`.claude/skills`, `.opencode/skills`, `.cursor/skills`, `.copilot/skills`, `.codex/skills`). Agent selection SHALL be multi-select and SHALL require at least one agent.

On a TTY, selection SHALL be an interactive checkbox picker: `↑/↓` (and `j/k`) move, `space` toggles an item, `a` toggles all, `enter` confirms, and `Ctrl-C` aborts. On entry it SHALL pre-check detected agents — for install, agents whose configuration directory exists under the chosen base (e.g. `~/.claude` → claude-code); for uninstall, agents that have the bundle installed (per the install registry, or a present `_super8-studio-api-shared` directory). Confirming with nothing selected SHALL re-prompt.

When stdin is not a TTY (CI, piped input), selection SHALL fall back to a typed prompt accepting comma-separated numbers, agent ids, or `all`, and SHALL reject unknown agents. The same selection mechanism SHALL be used by both install and uninstall.

#### Scenario: Checkbox multi-select on a TTY

- **WHEN** a user on a terminal moves with the arrow keys and presses `space` on Claude Code and Cursor, then `enter`
- **THEN** claude-code and cursor are selected

#### Scenario: Pre-checked from detection (install)

- **WHEN** the interactive picker opens for install and `~/.claude` already exists under the chosen base
- **THEN** claude-code starts checked

#### Scenario: At least one required

- **WHEN** the user confirms with no agent checked
- **THEN** the picker reports that at least one agent is required and does not proceed

#### Scenario: Select all

- **WHEN** the user enters `all` (non-TTY) or presses `a` then `enter` (TTY)
- **THEN** all five supported agents are selected

#### Scenario: Non-TTY fallback to typed list

- **WHEN** stdin is not a TTY and the input `1,3,5` is provided
- **THEN** the corresponding agents are selected without the checkbox UI

#### Scenario: Reject unknown agent

- **WHEN** the user enters an unsupported agent id in the typed fallback
- **THEN** the installer reports the invalid selection and does not install

### Requirement: API environment selection at install

Install SHALL decide the API URL and record it in the registry. It SHALL default to production (`https://api-next.no8.io`), select staging (`https://stage-api-next.no8.io`) when `--staging` is given, and use a caller-supplied endpoint when `--api-url <url>` is given. When both `--staging` and `--api-url` are supplied, `--api-url` SHALL take precedence. `--api-url` with an empty value SHALL be rejected. `--staging` and `--api-url` are internal options: they SHALL appear in `install --help`/usage output and in code comments, but SHALL NOT be documented in the README.

#### Scenario: Default is production

- **WHEN** `npx … install` runs without `--staging` or `--api-url`
- **THEN** the recorded `api_url` is `https://api-next.no8.io` and `channel` is `production`

#### Scenario: Staging flag

- **WHEN** `npx … install --staging` runs
- **THEN** the recorded `api_url` is `https://stage-api-next.no8.io` and `channel` is `staging`

#### Scenario: Hidden custom endpoint

- **WHEN** `npx … install --api-url https://localhost:8080` runs
- **THEN** the recorded `api_url` is `https://localhost:8080` and `channel` is `custom`

#### Scenario: --api-url wins over --staging

- **WHEN** `npx … install --staging --api-url https://localhost:8080` runs
- **THEN** the recorded `api_url` is `https://localhost:8080`

#### Scenario: Internal flags appear in help but not the README

- **WHEN** `install --help` is shown
- **THEN** the usage lists `--staging` and `--api-url`, while the README documents neither

### Requirement: Non-interactive flags

The installer SHALL support non-interactive operation: `--location global|repo` (or `--base-dir PATH`), `--agents LIST` (comma-separated or `all`), and `--target PATH` for an advanced shared folder that bypasses per-agent subpaths. `--target` SHALL be mutually exclusive with `--agents`. The installer SHALL also accept the internal API-environment options `--staging` and `--api-url <url>` (see "API environment selection at install").

#### Scenario: Non-interactive per-agent install

- **WHEN** the installer runs with `--location global --agents claude-code,cursor`
- **THEN** it installs to `~/.claude/skills` and `~/.cursor/skills` without prompting

#### Scenario: Advanced shared folder

- **WHEN** the installer runs with `--target ~/.agents/skills`
- **THEN** it installs directly into that folder with no agent subpath

#### Scenario: Conflicting flags rejected

- **WHEN** the installer runs with both `--target` and `--agents`
- **THEN** it reports the conflict and exits non-zero

#### Scenario: Staging applies in non-interactive mode

- **WHEN** the installer runs with `--location global --agents claude-code --staging`
- **THEN** it installs without prompting and records `channel=staging`

### Requirement: Copy semantics

The installer SHALL copy the `super8-studio-*` and `_super8-studio-*` skill directories into each target, removing any existing same-named directories first so installs are clean replacements.

#### Scenario: Clean replacement on reinstall

- **WHEN** a target already contains a previous version of the bundle directories
- **THEN** the installer removes them and copies the current bundle

### Requirement: Install registry management

The installer SHALL write a registry at `~/.super8-studio.config` recording `layout`, `base_dir`, `agents`, `skills_targets`, `installed_at`, and the API-environment keys `channel` (`production` | `staging` | `custom`) and `api_url`, as `key=value` lines with file mode `600`; and the runtime SHALL read this format. Uninstall SHALL remove installed bundle directories for the selected agents and SHALL be able to clear the registry.

#### Scenario: Registry records targets and API environment

- **WHEN** an install completes
- **THEN** `~/.super8-studio.config` contains the resolved `skills_targets`, a `channel`, and an `api_url`, and is mode 600

#### Scenario: Uninstall removes skills

- **WHEN** the user uninstalls for a selected agent
- **THEN** the bundle directories are removed from that agent's skills folder
