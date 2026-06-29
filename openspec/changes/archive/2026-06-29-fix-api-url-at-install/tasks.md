## 1. Registry & channel mapping

- [x] 1.1 Extend `install-config.js` to read/write `channel` and `api_url` keys (preserve existing keys and format/mode 600)
- [x] 1.2 Add a channel→(api_url, console_url) map and a production constant in `installer/common.js`

## 2. Install-time API URL selection

- [x] 2.1 Parse `--staging` and `--api-url <url>` in `installer/install.js`; resolve precedence `--api-url` > `--staging` > production; reject empty `--api-url`
- [x] 2.2 Derive `channel` (`production`|`staging`|`custom`) and write `channel`+`api_url` into the registry on install
- [x] 2.3 Document `--staging`/`--api-url` in `install --help`/usage and in code comments; keep them out of the README only (internal options)

## 3. Runtime API URL resolution

- [x] 3.1 In `env.js`, resolve `S8_API_ROOT` from registry `api_url`, falling back to the production constant when absent
- [x] 3.2 Remove `S8_API_URL` from credential loading and from the `CLAUDE_PLUGIN_OPTION_*` mapping; stop reading it from env/env files
- [x] 3.3 Update missing-credentials help to be token-centric (API URL is always resolved, never a missing-credential cause)

## 4. Setup changes

- [x] 4.1 Remove the Production/Custom API-URL prompt and the `--api-url` option from `setup.js`
- [x] 4.2 Read `channel`/`api_url` from the registry (production fallback) to choose Console + org-listing API
- [x] 4.3 Stop writing `S8_API_URL` to env files (write only token + optional org); update load-priority guidance text

## 5. Doctor & plugin manifests

- [x] 5.1 `doctor.js` prints the resolved API root and whether it came from the registry or the production fallback
- [x] 5.2 Remove `S8_API_URL` from `.claude-plugin/plugin.json` and `.codex-plugin/plugin.json` `userConfig`

## 6. Docs, tests & cleanup

- [x] 6.1 Retire RELEASE `api_url`/`console_url` usage in runtime/setup (Console derived from channel)
- [x] 6.2 Update env-precedence and smoke tests for registry-driven API URL (registry api_url used; env `S8_API_URL` ignored; production fallback)
- [x] 6.3 Update CHANGELOG (BREAKING: API URL fixed at install; `S8_API_URL` env/.env ignored; plugin always production)
- [x] 6.4 Verify CI matrix (ubuntu/macos/windows) stays green
