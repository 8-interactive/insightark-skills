## MODIFIED Requirements

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
