## Context

After the bash→Node re-platform, API URL flows through three sources resolved at `setup` time (`--api-url` → RELEASE file → interactive Production/Custom prompt), is stored as `S8_API_URL` in `.super8-studio.env`, and is overridable at runtime by the `S8_API_URL` environment variable (process env has highest precedence in `env.js`). The install registry (`~/.super8-studio.config`) records install layout/targets but not the API URL.

This change makes the API URL an install-time constant recorded in the registry, removes it from the credential surface, and fixes it at runtime. Decisions below were settled during exploration (`/opsx:explore`).

## Goals / Non-Goals

**Goals:**
- API URL is decided once at install and cannot be changed by environment variables or env files afterward.
- `npx … install` defaults to production; `--staging` selects the internal staging endpoint; a hidden `--api-url` allows custom endpoints. Neither flag is documented in the README.
- Users provide only a session token (+ optional org); never an API URL.
- Plugin installs are always production with no API-URL configuration.

**Non-Goals:**
- No change to the agent set, install layout, copy semantics, or registry file format mechanics (only new keys).
- No per-skill or per-call API URL overrides.
- No change to session-token or org-id resolution (those still come from env / env files / plugin options).
- No README documentation of `--staging` / `--api-url`.

## Decisions

### D1: API URL resolved and recorded at install time
`install.js` resolves the API URL with precedence `--api-url <url>` > `--staging` > production default, and writes both `channel` (`production` | `staging` | `custom`) and the resolved `api_url` into `~/.super8-studio.config`.
- **Why**: Install is the single decision point and already owns the registry. Recording both lets the runtime use `api_url` directly while `channel` drives Console/display derivation.
- **Alternatives**: Store only `channel` and derive `api_url` everywhere (rejected — `custom` has no channel mapping); store only `api_url` (rejected — loses the channel label for Console/display).

### D2: Runtime API root is fixed, registry-first with a production fallback
`env.js` resolves `S8_API_ROOT` from registry `api_url`; when no registry / no `api_url` (plugin installs, or pre-change installs), it falls back to a built-in production constant. Skills no longer read `S8_API_URL` from process env, `.super8-studio.env`, or `CLAUDE_PLUGIN_OPTION_S8_API_URL`.
- **Why**: "Fixed" must mean not overridable; a stray env var must not redirect a production install to staging.
- **Trade-off**: Loses runtime flexibility — intentional. The hidden `--api-url` at install covers legitimate custom-endpoint needs.

### D3: Credentials narrow to token (+ org)
`S8_SESSION_TOKEN` and optional `S8_ORG_ID` still load from process env / env files / plugin options with the existing precedence. Only `S8_API_URL` is removed from that resolution. `setup` writes only the token (+ org); never `S8_API_URL`.
- **Why**: Token/org remain legitimately per-user/per-environment; only the endpoint becomes a constant.

### D4: Setup derives targets from the registry channel
`setup` reads `channel`/`api_url` from the registry to pick the Console base (`production` → `https://console.no8.io`, `staging` → `https://stage-console.no8.io`, `custom` → none → manual instructions) and the API to query for orgs. It drops the Production/Custom prompt and the `--api-url` flag. The Console base is a distinct concern from the API URL, so the internal `--console-url` override is **retained** — it lets a caller using a custom `--api-url` endpoint (which has no derivable Console) point setup at the right Console.
- **Why**: The endpoint is already decided at install; setup should follow it, not re-ask. Console URL ≠ API URL, so its override stays.

### D5: Plugin installs are always production
Remove `S8_API_URL` from `.claude-plugin` and `.codex-plugin` `userConfig`. Plugin-path runtime hits the built-in production constant (no registry). Internal staging testing uses `npx … install --staging`.
- **Why**: Plugin marketplace installs never run `npx install`, so there is no registry; production is the only sensible fixed value, and `--staging` is an internal-only path anyway.

### D6: RELEASE file API/Console role retired
The Console base is derived from `channel` (`consoleBaseForApiUrl` already maps both endpoints). RELEASE `api_url`/`console_url` are no longer consulted by runtime or setup.
- **Why**: Channel is sufficient to derive both; one source of truth.

### D7: Flag conflict handling
If both `--staging` and `--api-url` are supplied, `--api-url` wins (it is the more specific escape hatch). `--api-url` with an empty/invalid value is rejected.
- **Alternative**: Hard error on conflict (rejected — `--api-url` is unambiguous intent; precedence is simpler).

## Risks / Trade-offs

- **Existing installs silently change endpoint** → A pre-change install (registry without `api_url`, or `S8_API_URL` only in `.super8-studio.env`) falls back to production; a staging tester who upgrades without re-running `install --staging` flips to production. Mitigation: document as BREAKING in CHANGELOG; internal testers re-install. Optionally `doctor` prints the resolved API root and its source so the active environment is visible.
- **Lost runtime override** → No `S8_API_URL` escape at runtime. Mitigation: the hidden `--api-url` at install covers custom endpoints; staging is a first-class flag.
- **Plugin users cannot reach staging** → Intended; staging is internal-only via npx. Mitigation: none needed.
- **Custom channel has no Console mapping** → `setup` on a `custom` api_url cannot open a Console; fall back to printing manual token-creation instructions (existing behavior when no Console base).
- **Registry tampering / hand-edits** → `api_url` read from a user-writable file. Acceptable: same trust level as the rest of the registry; not a security boundary.

## Migration Plan

1. Extend `install-config.js` to read/write `channel` and `api_url` (keep existing keys; preserve format).
2. Add channel→(api_url, console_url) mapping in `common.js`; resolve in `install.js` (`--api-url` > `--staging` > production) and write to the registry.
3. Update `env.js`: resolve `S8_API_ROOT` from registry `api_url` with a production fallback; remove `S8_API_URL` from credential loading and the plugin-option mapping; update missing-credentials help (token-centric).
4. Update `setup.js`: drop the API-URL prompt and `--api-url`; read channel/api_url from registry; derive Console; stop writing `S8_API_URL`.
5. Remove `S8_API_URL` from both plugin manifests' `userConfig`.
6. Update env/smoke tests and CHANGELOG; leave README silent on the internal flags.
7. **Rollback**: revert the change set; registry simply carries unused `channel`/`api_url` keys, which older code ignores.

## Open Questions

- Should `doctor` explicitly print the resolved API root and whether it came from the registry or the production fallback? Leaning yes — cheap visibility that directly mitigates the silent-endpoint-change risk.
