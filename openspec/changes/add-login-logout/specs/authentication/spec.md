## ADDED Requirements

### Requirement: Password login

`login` SHALL authenticate against the Developer API using email and password, completing TOTP when required, and SHALL obtain a session token. It SHALL read the password without echoing it, and SHALL NOT store or log the password. Requests SHALL go to the install-fixed API root.

#### Scenario: Login without MFA

- **WHEN** the user runs `login`, enters email and password, and the API returns a session (`_SessionToken`, `expiresAt`, `organizations`)
- **THEN** a session is established without asking for a TOTP code

#### Scenario: Login with TOTP

- **WHEN** the API responds `mfaRequired` with a `tempId`
- **THEN** `login` prompts for the TOTP code and posts `{ tempId, code }` to complete authentication

#### Scenario: Password is hidden and not persisted

- **WHEN** the user types the password
- **THEN** it is not echoed to the terminal and is never written to disk or logs

#### Scenario: Invalid credentials

- **WHEN** the API rejects the email/password (or TOTP code)
- **THEN** `login` reports the failure and does not write a session

### Requirement: Organization selection during login

After authenticating, `login` SHALL let the user choose an organization from the list returned by the API and record it in the session.

#### Scenario: Pick an org at login

- **WHEN** the login response includes multiple organizations
- **THEN** the user selects one and it is stored as the session `orgId`

### Requirement: Login session storage

`login` SHALL write the session to `~/.super8-studio.session` as JSON with file mode `600`, containing the token, its `expiresAt`, the account email, the chosen `orgId`, and the API URL the session was issued against.

#### Scenario: Session file written with restricted permissions

- **WHEN** login succeeds
- **THEN** `~/.super8-studio.session` is created mode `600` with the token, `expiresAt`, email, `orgId`, and `apiUrl`

### Requirement: Logout

`logout` SHALL remove `~/.super8-studio.session`. Because the Developer API exposes no revoke endpoint, `logout` SHALL be local-only and SHALL inform the user that the token remains valid server-side until it expires.

#### Scenario: Logout removes the session

- **WHEN** the user runs `logout` with a session present
- **THEN** `~/.super8-studio.session` is deleted and the user is told the token is still valid server-side until expiry

#### Scenario: Logout with no session

- **WHEN** the user runs `logout` with no session file
- **THEN** it reports that there is nothing to log out from and exits zero

### Requirement: Token verification

A reusable verification SHALL test a token against `GET /developer/v1/auth/me` at the install-fixed API root, returning success with the account identity on `2xx`, and reporting an invalid/expired token on `401`.

#### Scenario: Valid token verifies

- **WHEN** a valid token is checked against `/developer/v1/auth/me`
- **THEN** verification succeeds and the authenticated email is available

#### Scenario: Invalid token detected

- **WHEN** the token is rejected with `401`
- **THEN** verification reports the token is invalid or expired
