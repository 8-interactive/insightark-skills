## 1. Session storage & verification helpers

- [x] 1.1 Add session helpers to `installer/common.js` (or a lib): read/write/clear `~/.super8-studio.session` JSON `{ token, expiresAt, email, orgId, apiUrl }`, mode 600
- [x] 1.2 Add a `verifyToken(apiRoot, token)` helper that calls `GET /developer/v1/auth/me` → `{ ok, status, email }`
- [x] 1.3 Add a session-validity check (not expired AND `apiUrl` matches the resolved API root)

## 2. Runtime precedence (env.js)

- [x] 2.1 Make a valid login session the highest token source; fall through (with a re-login notice) when expired or API-mismatched
- [x] 2.2 Add session `orgId` to org resolution: `--org-id` → session `orgId` → `S8_ORG_ID` → env files
- [x] 2.3 Update missing-token help to mention `login`
- [x] 2.4 Keep the existing env/plugin/file chain intact below the session

## 3. login / logout commands

- [x] 3.1 `installer/login.js`: prompt email → hidden password → `POST /auth/login`; if `mfaRequired`, prompt TOTP → `POST /auth/login/totp`; never store/log the password
- [x] 3.2 Org selection from the login response; write the session file
- [x] 3.3 Handle auth failure (401/invalid TOTP) with a clear message and retry/abort
- [x] 3.4 `installer/logout.js`: delete the session file; note no server-side revoke; no-op message when absent
- [x] 3.5 Wire `login` and `logout` into `scripts/super8-skills-cli.js` (usage/help)

## 4. install integration & setup deprecation

- [x] 4.1 `install.js` (interactive): after copy/registry, verify token via `/auth/me`; on missing/401 prompt "Log in now? [Y/n]" → run login; on network/5xx/429 warn without login
- [x] 4.2 `install.js` (non-interactive): skip auto-login; print guidance to run `login`
- [x] 4.3 `setup.js`: print a deprecation notice recommending `login` (keep it working)
- [x] 4.4 `doctor.js`: report the auth source (login session vs env) and session `expiresAt`

## 5. Tests, docs & verification

- [x] 5.1 Unit-test session precedence: session beats `S8_SESSION_TOKEN`; expired/API-mismatched session falls through; session `orgId` vs `--org-id`/`S8_ORG_ID`
- [x] 5.2 Confirm `validate` + `npm test` + `smoke` stay green (smoke still covers non-interactive install with no auto-login)
- [x] 5.3 README (EN + 中文): document `login`/`logout`, the session precedence, and `setup` deprecation; keep internal flags out
- [x] 5.4 CHANGELOG entry (BREAKING precedence note); CI matrix stays green
- [ ] 5.5 Manually verify a real login (password + TOTP) and that a skill then authenticates — pending: needs staging up + real account/TOTP (manual)
