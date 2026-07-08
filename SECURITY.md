# Security Policy

## Reporting

Report suspected security issues through the private SUPER 8 Studio engineering
support channel or the approved internal incident process. Do not open public
issues with tokens, customer data, request logs, or exploit details.

## Token Handling

- Never commit `.insightark.env`, `_SessionToken`, or `S8_SESSION_TOKEN`.
- Never paste Developer API tokens into chat, email, screenshots, or tickets.
- `./setup-env.sh` writes credential files (project `.insightark.env`, user
  `~/.insightark.env`) with mode `600`.
- `install.sh` writes the install registry (`~/.insightark.config`) with mode
  `600`. The registry records install targets and layout only — never a token.
- Rotate a token immediately if it may have been exposed.

## Skill Behavior

Skills must not ask for passwords, TOTP codes, browser session cookies, or any
credential other than a SUPER 8 Studio Developer API token. Skills read
credentials only through the shared resolver
(`skills/_insightark-shared/scripts/lib/env.sh`), which checks process
environment variables, then `.insightark.env` (project, then skills-directory,
then `~/.insightark.env`) in that order.

## Destructive Actions

Skills that send messages, mutate customer data, or trigger broadcasts /
marketing-automation runs must confirm intent with the user before calling a
write endpoint. Read-only investigation must never require confirmation.
