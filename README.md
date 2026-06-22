# Super 8 Studio API Skills

Standalone skill bundle for the Super 8 Studio Developer API.

## Environment

Scripts load credentials automatically before each API call.

### Config files

| Location | Path | Typical contents |
| --- | --- | --- |
| Install registry | `~/.super8-studio.config` | Skills install paths (written by `install.sh`) |
| Skills dir | `{skills-target}/.super8-studio.env` | `S8_SESSION_TOKEN`, `S8_API_URL`, `S8_ORG_ID` (written by `setup-env.sh` after install) |
| User (legacy) | `~/.super8-studio.env` | Fallback if install registry is missing |
| Project | `{project}/.super8-studio.env` | Optional `S8_ORG_ID` / stage `S8_API_URL` override (no token) |

**Load order** (later overrides earlier): user file → skills install dir → project file → process environment wins over all.

Variables:

- `S8_API_URL` — API base URL (required), e.g. `https://api-next.no8.io`
- `S8_SESSION_TOKEN` — Developer `_SessionToken` (required)
- `S8_ORG_ID` — Default organization id for org-scoped routes (optional)

### Quick setup

Install skills first, then configure credentials (setup runs doctor when finished):

```bash
./install.sh
./setup-env.sh
./setup-env.sh --check
```

On **Windows**, run scripts in **Git Bash** or **WSL** (`~` expands via `$HOME`).

### Download (published package)

Each tarball includes `bundle/_super8-studio-api-shared/RELEASE` so `setup-env.sh` automatically detects the correct API environment — no manual selection needed.

```bash
curl -LO https://downloads.no8.io/main/releases/skills/super8-studio-api-skills-latest.tar.gz
tar -xzf super8-studio-api-skills-latest.tar.gz
cd super8-studio-api-skills && ./install.sh && ./setup-env.sh
```

**Local git checkout** has no `RELEASE` file — `setup-env.sh` prompts for API environment. Override anytime with `./setup-env.sh --api-url URL`.

### Session token workflow

`./setup-env.sh` can open Super 8 Console, create a Developer API token via deep link, and list organizations with Developer API enabled for org selection.

Manual path:

1. Console → **Account Settings → Developer API**
2. Create a token (shown **once**)
3. Run `./setup-env.sh` or edit `~/.super8-studio.env`

**Security notes**

- Never commit `.super8-studio.env` or share tokens in chat.
- Tokens expire after six months; create a new token when expired.

## Supported agents

Install target: `{base_dir}/{agent-subpath}`

| Agent | Subpath |
| --- | --- |
| `claude-code` | `.claude/skills` |
| `opencode` | `.opencode/skills` |
| `cursor` | `.cursor/skills` |
| `github-copilot` | `.copilot/skills` |
| `codex` | `.codex/skills` |

**Install layouts** (interactive Step 1)

| Choice | Flow | Result |
| --- | --- | --- |
| Custom folder | Enter path | One directory, e.g. `~/.agents/skills` |
| Per-agent auto | Pick agents → user/project space | Only selected agents, e.g. `~/.cursor/skills` |

## Plugin install (recommended)

### Claude Code

```bash
# Add the marketplace and install the plugin
claude plugin marketplace add 8-interactive/super8-studio-api-skills
claude plugin install super8-studio-api-skills@super8-studio-api-skills
```

Claude Code will prompt for `S8_API_URL` and `S8_SESSION_TOKEN` during
installation. The session token is stored in the system keychain — no
`.env` file required. A `SessionStart` hook runs `doctor.sh` automatically
so credential issues surface at the start of every session.

To enable the plugin (installed disabled by default — it connects to an external API):

```bash
claude plugin enable super8-studio-api-skills@super8-studio-api-skills
```

For private-repo auto-updates, set `GITHUB_TOKEN` in your shell profile.

### Codex

```bash
# Add the marketplace
# Then install from the marketplace UI or via codex plugin install
```

### Manual (shell-based) install

## Install

Interactive (default):

```bash
./install.sh
```

CLI:

```bash
./install.sh --base-dir ~ --agents claude-code,cursor,codex
./install.sh --base-dir /path/to/project --agents cursor
./install.sh --agents opencode
```

Shared skills folder (no per-agent subpaths):

```bash
./install.sh --target ~/.agents/skills
```

Legacy `--host` is deprecated; use `--agents` instead.

## Setup-env

```bash
./setup-env.sh
./setup-env.sh --check
./setup-env.sh --env-hints
./setup-env.sh --api-url https://api-next.no8.io   # override API base URL
./setup-env.sh --repo-only --project-path /path/to/project
./setup-env.sh --no-open-browser
```

## Validate

```bash
./setup-env.sh --check
```

Or:

```bash
bash <skills-target>/_super8-studio-api-shared/scripts/doctor.sh
```

## Update model

Re-run `install.sh` to replace the installed bundle in place. Config files outside skills directories are preserved.

## Uninstall

```bash
./uninstall.sh
./uninstall.sh --base-dir ~ --agents claude-code,codex
./uninstall.sh --target /custom/skills/path
```

## Conversation analysis leaves

Read-only skills for agent-driven conversation investigation (no composer skill required):

| Skill | Purpose |
| --- | --- |
| `super8-studio-conversations` | List conversations by platform, inbox state, customer, or activity time |
| `super8-studio-conversation-detail` | Conversation summary and message timeline |
| `super8-studio-message-search` | Keyword search across the org or within one conversation |
| `super8-studio-customer-search` | Find customer segments by tag or activity, then loop into conversations |

Typical flow: `customer-search` or `conversations` → `message-search` (keyword evidence) → `conversation-detail` (timeline context).

## Included skills

- `super8-studio-session`
- `super8-studio-org-scope`
- `super8-studio-conversations`
- `super8-studio-conversation-detail`
- `super8-studio-message-search`
- `super8-studio-investigator`
- `super8-studio-messaging`
- `super8-studio-customer-manager`
- `super8-studio-customer-detail`
- `super8-studio-customer-search`
- `super8-studio-customer-update`
- `super8-studio-customer-tag-add`
- `super8-studio-customer-tag-remove`
- `super8-studio-customer-send-message`
- `super8-studio-broadcast-create`
- `super8-studio-broadcast-get`
- `super8-studio-broadcast-list`
- `super8-studio-broadcast-manager`
