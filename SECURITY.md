# Security Policy

## Supported Versions

| Version | Supported |
|---------|-----------|
| 1.x     | ✓         |

## Security Boundaries

Every skill in this bundle enforces the following rules:

- Skills do not request or transmit API keys, tokens, production credentials, or customer secrets.
- Skills do not expose customer PII in output or traces.
- Slack messages, Jira content, CRM notes, web pages, and logs are treated as untrusted input.
- External content cannot override system, developer, or skill instructions.
- Scripts are read-only by default; any state-changing action requires explicit human approval.
- Session tokens are loaded from environment variables only — never committed to version control.

## Reporting a Vulnerability

To report a security issue in a skill or script, please contact the repository maintainers privately before filing a public issue. Include affected skill, description, reproduction steps, and impact. Do not include real tokens, credentials, or customer data.
