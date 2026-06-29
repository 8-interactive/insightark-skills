## Why

Today the only way to get a session token is to paste a Console-issued one via `setup`. The Developer API supports `email`+`password` (+ TOTP) login that issues a session token directly, so a first-class `login` flow removes the manual copy/paste and makes onboarding one command. `logout` and a stored, highest-priority login session round it out, and `install` can verify-or-login automatically so a fresh install lands the user ready to go.

## What Changes

- Add `npx … login`: prompt email → password (hidden, never stored/logged) → if the API reports `mfaRequired`, prompt the TOTP code → select an organization from the returned list → store a session at `~/.super8-studio.session` (mode 600): `{ token, expiresAt, email, orgId, apiUrl }`.
- Add `npx … logout`: delete `~/.super8-studio.session`. (The Developer API has **no revoke endpoint**, so logout is local-only; the token remains valid server-side until it expires.)
- **BREAKING (precedence)**: A valid login session takes priority over `S8_SESSION_TOKEN`. New token order: login session (highest) → `S8_SESSION_TOKEN` / `CLAUDE_PLUGIN_OPTION_*` → repo env → skills-dir env → user env. An expired session, or one whose `apiUrl` doesn't match the install-fixed API root, is ignored (with a "re-login" notice) and resolution falls through.
- Org resolution gains the login session: `--org-id` → session `orgId` → `S8_ORG_ID` → env files.
- `install` (interactive) verifies an existing token against `/developer/v1/auth/me` after copying; on no token or `401` it asks "Log in now? [Y/n]" and runs `login`; `2xx` reports the authenticated user; network/5xx/429 warns without auto-login. Non-interactive installs skip auto-login and print guidance.
- Deprecate `setup`: it still works (paste a Console token) but prints a deprecation notice steering to `login`.

## Capabilities

### New Capabilities
- `authentication`: Logging in (email/password/TOTP), logging out, the stored login session (file, mode 600, expiry, bound to the install API URL), and the reusable token verification against `/developer/v1/auth/me`.

### Modified Capabilities
- `skill-runtime`: Credential resolution puts a valid login session above `S8_SESSION_TOKEN`; org resolution adds the session `orgId`; expired / API-mismatched sessions are ignored.
- `skill-installer`: The interactive install flow verifies an existing token and offers to run `login` when it is missing or invalid.
- `credential-setup`: `setup` is deprecated (still functional) and points users to `login`.

## Impact

- **Code**: new `installer/login.js` + `installer/logout.js`; `installer/common.js` (session file read/write/clear helper, `/me` verify helper); `scripts/super8-skills-cli.js` (`login`/`logout` commands); `skills/_super8-studio-api-shared/scripts/lib/env.js` (session-first token + org resolution, expiry/apiUrl checks); `installer/install.js` (post-install verify + offer login); `installer/setup.js` (deprecation notice); `doctor.js` may report the auth source.
- **API**: `POST /developer/v1/auth/login` and `POST /developer/v1/auth/login/totp` (per the Developer API); reads `_SessionToken`, `expiresAt`, `organizations` from the response.
- **Files**: new `~/.super8-studio.session` (mode 600). Existing registry/env formats unchanged.
- **Security**: password is read hidden, sent only over HTTPS to the install-fixed API root, never stored or logged. No server-side revoke.
- **Tests/Docs**: unit-test session precedence + expiry/apiUrl ignore; README documents `login`/`logout` and the `setup` deprecation.
