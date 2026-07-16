# Security

## Authentication

Production InsightArk plugins authenticate with host-managed MCP OAuth only. The packaged manifests supply a static public client id per host and a channel-baked MCP URL. Customers do not paste SessionTokens, write local credential files, or export OAuth access/refresh tokens from the host credential store.

Server-side `/mcp` may still accept `_SessionToken` for non-plugin consumers. That transport compatibility is not part of the marketplace plugin customer contract.

## Credentials and revocation

- OAuth access and refresh tokens are stored by the host.
- Revoke a connected app from SUPER 8 Console → Connected Apps when a device or integration should lose access.
- Host logout / clear-auth clears local credentials; marketplace plugin removal removes the package. Do not assume one action implies the other unless verified for that host version.

## Release integrity

Customer release trees contain only allowlisted plugin metadata, MCP manifests, skills, assets, and customer docs. Release/CI tooling, contributor docs, and hooks are excluded from the published package.

## Reporting

Report security issues through your SUPER 8 Studio support channel.
