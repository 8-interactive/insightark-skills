## Context

Credentials today: `setup` writes `S8_SESSION_TOKEN` (a pasted Console token) into `~/.super8-studio.env`; `env.js` resolves the token with process env highest, then repo / skills-dir / user env files; the API root is fixed at install time (registry `api_url`, production fallback). The Developer API (`server/lib/cluster/api/routes/developer.js`) exposes a password login that issues a real session token:

- `POST {apiRoot}/developer/v1/auth/login` `{ email, password }` → either `{ _SessionToken, expiresAt, user, organizations }` or, when TOTP MFA is enabled, `{ mfaRequired: true, method: "totp", tempId, organizations }`.
- `POST {apiRoot}/developer/v1/auth/login/totp` `{ tempId, code }` → `{ _SessionToken, expiresAt, user, organizations }`.
- There is **no logout/revoke endpoint**. The issued `_SessionToken` is the same token skills send as the `_SessionToken` header.

This change adds `login`/`logout`, stores the resulting session as the highest-priority credential, deprecates `setup`, and makes `install` verify-or-login.

## Goals / Non-Goals

**Goals:**
- One-command authentication via email/password (+TOTP), no manual token copy.
- A stored login session that overrides `S8_SESSION_TOKEN`, with safe expiry/environment handling.
- `install` lands the user authenticated (interactive), or clearly guided (non-interactive).
- Password never stored or logged.

**Non-Goals:**
- No server-side token revoke (the API has none) — `logout` is local-only.
- No change to the install-fixed API URL model, the agent set, or copy semantics.
- No auto-login in non-interactive/CI installs.
- Not removing `setup` — only deprecating it.

## Decisions

### D1: Session stored in a dedicated, highest-priority file
Write `~/.super8-studio.session` (JSON, mode 600): `{ token, expiresAt, email, orgId, apiUrl }`. `env.js` checks it before any other source.
- **Why**: A login session must beat `S8_SESSION_TOKEN` (per the requirement). A separate file (vs `.super8-studio.env`) cleanly separates "logged-in state" from a manually-set token, carries `expiresAt`, and lets `logout` remove only the session.
- **Alternative**: write into `.super8-studio.env` (rejected — can't express "above the env var", no expiry, logout would clobber user data).

### D2: Session validity gates — expiry and API binding
A session is used only if it is unexpired AND its `apiUrl` equals the currently-resolved API root. Otherwise it is ignored, a one-line "session expired / for another environment — run `login`" notice is printed, and resolution falls through to the next source.
- **Why**: Prevents a stale token from silently blocking, and prevents a production token from being sent to staging after `install --staging` switches the channel.

### D3: New token & org precedence
Token: login session → `S8_SESSION_TOKEN` / `CLAUDE_PLUGIN_OPTION_*` → repo env → skills-dir env → user env. Org: `--org-id` → session `orgId` → `S8_ORG_ID` → env files.
- **Why**: The login session is the most explicit, freshest credential; explicit `--org-id` still wins for one-off targeting.
- **Footgun acknowledged**: a leftover session overrides an exported `S8_SESSION_TOKEN`. Interactive login does not happen in CI, so CI machines won't have a session file; expiry + API binding + `logout` mitigate the rest.

### D4: `login` flow and storage
`login`: prompt email; `promptHidden` for password; `POST /auth/login`; if `mfaRequired`, prompt the TOTP code and `POST /auth/login/totp` with `tempId`; from the session response, let the user pick an org from `organizations`; write the session file. The API root is the install-fixed root (registry / production). On auth failure (401), report and allow retry/abort.
- **Why**: Mirrors the API's two-step MFA exactly; reuses the fixed-API-root model and `promptHidden`.

### D5: `logout` is local-only
Delete `~/.super8-studio.session`. Print that the token remains valid server-side until expiry (no revoke endpoint). Does not touch `setup`'s env file.

### D6: `install` verify-or-login (interactive only)
After copy + registry write, in interactive mode: resolve the token; if present, `GET /auth/me`. `2xx` → "Authenticated as <email>". No token or `401` → prompt "Log in now? [Y/n]" (default yes) → run `login`. Network / 5xx / 429 → warn, no auto-login (login would also fail). Non-interactive installs (flags / `--target` / no TTY) skip auto-login and print "run `npx … login`".
- **Why**: A fresh install ends ready, but never blocks automation on an interactive prompt.

### D7: Deprecate, don't remove, `setup`
`setup` keeps working (paste a Console token → user env file) but prints a deprecation notice recommending `login`. At runtime, a login session naturally overrides a setup-written env token.

## Risks / Trade-offs

- **Precedence inversion footgun** → see D3; mitigated by expiry (D2), API binding (D2), and `logout`.
- **Password handling** → read with `promptHidden`; sent only over HTTPS to the fixed API root; never written to disk or logs; not echoed. The session file stores only the issued token, not the password.
- **No server revoke** → `logout` cannot invalidate the token server-side; document this. Short-lived sessions (per `expiresAt`) limit exposure.
- **Network dependency at install tail** → `/me` needs connectivity; offline → "couldn't verify" warning, install still succeeds.
- **TOTP intermediate state** → `tempId` is held only in memory between the two prompts (server TTL ~300s); never persisted.
- **Clock skew vs expiry** → expiry compared to local time; minor skew could prematurely ignore a session → falls through to env/login, which is safe.

## Migration Plan

1. `env.js`: add session-file read with expiry + apiUrl checks; make it the highest token source and add session `orgId` to org resolution; keep the existing chain below it.
2. `common.js`: session read/write/clear helper; a `verifyToken` helper that calls `/auth/me`.
3. `login.js` / `logout.js`; wire `login` / `logout` commands into `super8-skills-cli.js`.
4. `install.js`: interactive post-install verify-or-login; non-interactive guidance.
5. `setup.js`: deprecation notice.
6. Tests: session precedence + expiry/apiUrl ignore (unit, stubbed homedir); keep smoke green. README updates.
7. **Rollback**: revert; the session file becomes inert (nothing reads it) and the previous precedence resumes.

## Open Questions

- Should `doctor` print the auth source (login session vs env) and the session's `expiresAt`? Leaning yes — cheap visibility that complements the API-root source it already prints.
