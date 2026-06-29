## 1. Core runtime libraries (Node)

- [x] 1.1 Port `lib/env.js` — `.env` parsing, load order (process/plugin-option → repo → skills-dir → user), `CLAUDE_PLUGIN_OPTION_S8_*` mapping, missing-credentials help, org-id resolution
- [x] 1.2 Port `lib/http.js` — `fetch` request with `_SessionToken` header; 401/429/non-2xx handling with body echo and non-zero exit
- [x] 1.3 Port `lib/output.js` — formatted JSON printing via stdlib (no `jq`)
- [x] 1.4 Port `lib/install-config.js` — read/write `~/.super8-studio.config` (`key=value`, mode 600), parse `skills_targets`
- [x] 1.5 Port `lib/release.js` and add date helpers (ISO-8601 UTC now / N-days-ago via `Date`)
- [x] 1.6 Add a focused test comparing `env.js` precedence against bash behavior across the source-combination matrix

## 2. Command scripts (.sh → .js)

- [x] 2.1 Port auth/session and org scripts: `auth_me.js`, `organizations.js`
- [x] 2.2 Port customer scripts: `customer_detail.js`, `customer_search.js`, `customer_update.js`, `customer_send_message.js`, `customer_tag_add.js`, `customer_tag_remove.js`
- [x] 2.3 Port conversation/message scripts: `conversations.js`, `conversation_detail.js`, `conversation_messages.js`, `message_search.js`
- [x] 2.4 Port broadcast scripts: `broadcast_create.js`, `broadcast_get.js`, `broadcast_list.js`
- [x] 2.5 Port marketing-automation scripts: `ma_procedure_create.js`, `ma_procedure_validate.js`, `ma_procedure_preflight.js`, `ma_procedure_start.js`, `ma_procedure_status.js`, `ma_procedure_list.js`, `ma_procedure_trigger.js`, `ma_procedure_pause.js`
- [x] 2.6 Add `#!/usr/bin/env node` and verify each script parses args, calls the API, and returns expected exit codes

## 3. SKILL.md invocation contract

- [x] 3.1 Update all ~24 `SKILL.md` files to reference `node <relative-path>.js` instead of `.sh`
- [x] 3.2 Verify each `SKILL.md` script path resolves to an existing `.js` file

## 4. Node installer

- [x] 4.1 Build agent registry (id → label → subpath) and target resolution `{base}/{agent-subpath}`
- [x] 4.2 Implement interactive flow: location (global/repo) → agent multi-select → confirm (via `node:readline`)
- [x] 4.3 Implement non-interactive flags: `--location`/`--base-dir`, `--agents`, `--target` (mutually exclusive with `--agents`)
- [x] 4.4 Implement copy semantics (remove existing bundle dirs, `fs.cpSync` recursive) and registry write
- [x] 4.5 Implement Node uninstall (remove bundle dirs per agent; clear registry option)
- [x] 4.6 Implement Node credential setup (write `~/.super8-studio.env`, load-priority guidance)
- [x] 4.7 Implement Node doctor health check (authenticated API call, success/failure reporting, exit codes)
- [x] 4.8 Rewire `scripts/super8-skills-cli.js` to call the Node installer/setup/doctor directly (no `bash` spawn)

## 5. Remove bash and update distribution

- [x] 5.1 Delete bash scripts: `skills/**/scripts/**/*.sh`, `install.sh`, `uninstall.sh`, `setup-env.sh`, `installer/common.sh`
- [x] 5.2 Update `.claude-plugin/` and `.codex-plugin/` manifests for the Node entry points
- [x] 5.3 Update `package.json` `files`/`bin` to reflect Node-only layout
- [x] 5.4 Update README (EN + 中文) install/setup sections and the npx flow
- [x] 5.5 Update CHANGELOG noting the BREAKING re-platform and re-install requirement

## 6. Cross-platform verification

- [x] 6.1 Verify install + setup + doctor + a representative skill on macOS/Linux
- [x] 6.2 Verify install + setup + doctor + a representative skill on native Windows (no bash) — verified via CI `windows-latest` (node 18 & 20): validate + env tests + cross-platform smoke (install/uninstall/runtime) all pass
- [x] 6.3 Confirm no `node_modules` is present in any installed agent skill folder
- [x] 6.4 Confirm `~/.super8-studio.config` format is byte-compatible with the previous registry
