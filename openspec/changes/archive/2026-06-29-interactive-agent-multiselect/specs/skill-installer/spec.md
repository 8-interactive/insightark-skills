## MODIFIED Requirements

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
