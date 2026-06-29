## ADDED Requirements

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

## MODIFIED Requirements

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

### Requirement: Install registry management

The installer SHALL write a registry at `~/.super8-studio.config` recording `layout`, `base_dir`, `agents`, `skills_targets`, `installed_at`, and the API-environment keys `channel` (`production` | `staging` | `custom`) and `api_url`, as `key=value` lines with file mode `600`; and the runtime SHALL read this format. Uninstall SHALL remove installed bundle directories for the selected agents and SHALL be able to clear the registry.

#### Scenario: Registry records targets and API environment

- **WHEN** an install completes
- **THEN** `~/.super8-studio.config` contains the resolved `skills_targets`, a `channel`, and an `api_url`, and is mode 600

#### Scenario: Uninstall removes skills

- **WHEN** the user uninstalls for a selected agent
- **THEN** the bundle directories are removed from that agent's skills folder
