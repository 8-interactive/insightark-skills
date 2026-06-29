"use strict";

const path = require("path");
const common = require("./common.js");

const SCRIPTS_DIR = path.join(common.BUNDLE_DIR, "_super8-studio-api-shared", "scripts");
const env = require(path.join(SCRIPTS_DIR, "lib", "env.js"));
const session = require(path.join(SCRIPTS_DIR, "lib", "session.js"));

function err(message) {
  process.stderr.write(message + "\n");
}

function printUsage() {
  process.stdout.write(
    [
      "Usage: login",
      "",
      "Authenticate with your Super 8 account (email + password, plus TOTP if",
      "enabled) and store a session token. The session takes priority over",
      "S8_SESSION_TOKEN and is used by all skills until it expires or you log out.",
      "",
    ].join("\n")
  );
}

async function postJson(url, body) {
  let res;
  try {
    res = await fetch(url, {
      method: "POST",
      headers: { Accept: "application/json", "Content-Type": "application/json" },
      body: JSON.stringify(body),
    });
  } catch (e) {
    return { ok: false, status: 0, data: null, error: e && e.message ? e.message : String(e) };
  }
  let data = null;
  try {
    data = JSON.parse(await res.text());
  } catch (_e) {
    // ignore
  }
  return { ok: res.status >= 200 && res.status < 300, status: res.status, data };
}

function errorMessage(result) {
  if (result.error) return result.error;
  const d = result.data;
  return (d && (d.message || d.code)) || `HTTP ${result.status}`;
}

async function selectOrg(orgs) {
  if (!orgs || orgs.length === 0) {
    err("No organizations are available for this account.");
    return "";
  }
  if (orgs.length === 1) {
    const only = orgs[0];
    err(`Using organization: ${only.displayName || only.name || only.id} (${only.id})`);
    return only.id;
  }
  err("");
  err("Select an organization:");
  orgs.forEach((o, i) => err(`  ${i + 1}) ${o.displayName || o.name || o.id} (${o.id})`));
  const choice = (await common.prompt("Choice: ")).trim();
  const idx = Number(choice);
  if (!/^[0-9]+$/.test(choice) || idx < 1 || idx > orgs.length) {
    err("Invalid choice; leaving org unset (set later with --org-id or re-run login).");
    return "";
  }
  return orgs[idx - 1].id;
}

async function run(argv) {
  if (argv.includes("--help")) {
    printUsage();
    return 0;
  }

  const apiRoot = env.resolveApiRoot().root;
  err(`Logging in to ${apiRoot}`);
  const email = (await common.prompt("Email: ")).trim();
  if (!email) {
    err("Email is required.");
    return 1;
  }
  const password = await common.promptHidden("Password: ");
  if (!password) {
    err("Password is required.");
    return 1;
  }

  let result = await postJson(`${apiRoot}/developer/v1/auth/login`, { email, password });
  if (!result.ok) {
    err(`Login failed: ${errorMessage(result)}`);
    return 1;
  }

  let payload = result.data && result.data.data;
  if (payload && payload.mfaRequired) {
    const code = (await common.prompt(`Enter ${payload.method || "TOTP"} code: `)).trim();
    if (!code) {
      err("A verification code is required.");
      return 1;
    }
    result = await postJson(`${apiRoot}/developer/v1/auth/login/totp`, {
      tempId: payload.tempId,
      code,
    });
    if (!result.ok) {
      err(`Verification failed: ${errorMessage(result)}`);
      return 1;
    }
    payload = result.data && result.data.data;
  }

  if (!payload || !payload._SessionToken) {
    err("Login succeeded but no session token was returned.");
    return 1;
  }

  const orgId = await selectOrg(payload.organizations);
  session.writeSession({
    token: payload._SessionToken,
    expiresAt: payload.expiresAt,
    email,
    orgId,
    apiUrl: apiRoot,
  });

  err("");
  process.stdout.write(
    `Logged in as ${email}. Session saved to ${common.formatDisplayPath(session.sessionPath())}.\n`
  );
  if (orgId) process.stdout.write(`Default organization: ${orgId}\n`);
  if (payload.expiresAt) process.stdout.write(`Session expires: ${payload.expiresAt}\n`);
  return 0;
}

module.exports = { run };
