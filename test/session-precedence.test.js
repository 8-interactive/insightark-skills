#!/usr/bin/env node
"use strict";

// Tests that a valid login session is the highest-priority credential, that
// expired / API-mismatched sessions fall through, and that the session orgId
// participates in org resolution. Stubs os.homedir() (the local `node` is a
// version-manager shim that resolves through $HOME).

const assert = require("assert");
const fs = require("fs");
const os = require("os");
const path = require("path");

const SCRIPTS = path.join(__dirname, "..", "skills", "_super8-studio-api-shared", "scripts");
const ENV_LIB = path.join(SCRIPTS, "lib", "env.js");
const SESSION_LIB = path.join(SCRIPTS, "lib", "session.js");
const INSTALL_CONFIG_LIB = path.join(SCRIPTS, "lib", "install-config.js");
const API = "https://api-next.no8.io";

let failures = 0;
function check(name, fn) {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "s8-sess-"));
  const home = path.join(root, "home");
  const cwd = path.join(root, "cwd");
  fs.mkdirSync(home);
  fs.mkdirSync(cwd);
  const realHomedir = os.homedir;
  const realCwd = process.cwd();
  const savedEnv = { ...process.env };
  os.homedir = () => home;
  process.chdir(cwd);
  for (const k of Object.keys(process.env)) {
    if (k.startsWith("S8_") || k.startsWith("CLAUDE_PLUGIN_OPTION_S8_")) delete process.env[k];
  }
  for (const m of [ENV_LIB, SESSION_LIB, INSTALL_CONFIG_LIB]) delete require.cache[require.resolve(m)];
  try {
    fn({ home, cwd });
    process.stdout.write(`PASS: ${name}\n`);
  } catch (err) {
    failures++;
    process.stdout.write(`FAIL: ${name}\n  ${err.message}\n`);
  } finally {
    os.homedir = realHomedir;
    process.chdir(realCwd);
    for (const k of Object.keys(process.env)) delete process.env[k];
    Object.assign(process.env, savedEnv);
    fs.rmSync(root, { recursive: true, force: true });
  }
}

// Registry pins the resolved API root to API.
function writeRegistry(home) {
  fs.writeFileSync(path.join(home, ".super8-studio.config"), `api_url=${API}\n`);
}
function writeSession(home, overrides) {
  const s = {
    token: "r:session",
    expiresAt: new Date(Date.now() + 3600e3).toISOString(),
    email: "dev@example.com",
    orgId: "org-session",
    apiUrl: API,
    ...overrides,
  };
  fs.writeFileSync(path.join(home, ".super8-studio.session"), JSON.stringify(s));
}

check("valid session beats S8_SESSION_TOKEN", ({ home }) => {
  writeRegistry(home);
  writeSession(home);
  process.env.S8_SESSION_TOKEN = "r:env";
  const env = require(ENV_LIB);
  assert.strictEqual(env.loadRuntimeEnv(), true);
  assert.strictEqual(process.env.S8_SESSION_TOKEN, "r:session");
  assert.strictEqual(process.env.S8_API_ROOT, API);
});

check("expired session falls through to env token", ({ home }) => {
  writeRegistry(home);
  writeSession(home, { expiresAt: new Date(Date.now() - 1000).toISOString() });
  process.env.S8_SESSION_TOKEN = "r:env";
  const env = require(ENV_LIB);
  assert.strictEqual(env.loadRuntimeEnv(), true);
  assert.strictEqual(process.env.S8_SESSION_TOKEN, "r:env");
});

check("session for another API root is ignored", ({ home }) => {
  writeRegistry(home);
  writeSession(home, { apiUrl: "https://stage-api-next.no8.io" });
  process.env.S8_SESSION_TOKEN = "r:env";
  const env = require(ENV_LIB);
  assert.strictEqual(env.loadRuntimeEnv(), true);
  assert.strictEqual(process.env.S8_SESSION_TOKEN, "r:env");
});

check("session orgId used over S8_ORG_ID", ({ home }) => {
  writeRegistry(home);
  writeSession(home);
  process.env.S8_SESSION_TOKEN = "r:env";
  process.env.S8_ORG_ID = "org-env";
  const env = require(ENV_LIB);
  env.loadRuntimeEnv();
  assert.strictEqual(env.resolveOrgId(""), "org-session");
});

check("explicit --org-id beats session orgId", ({ home }) => {
  writeRegistry(home);
  writeSession(home);
  process.env.S8_SESSION_TOKEN = "r:env";
  const env = require(ENV_LIB);
  env.loadRuntimeEnv();
  assert.strictEqual(env.resolveOrgId("org-explicit"), "org-explicit");
});

check("no session → env token used; resolveToken non-exiting", ({ home }) => {
  writeRegistry(home);
  process.env.S8_SESSION_TOKEN = "r:env";
  const env = require(ENV_LIB);
  assert.strictEqual(env.resolveToken(), "r:env");
});

check("resolveToken returns null when nothing available", ({ home }) => {
  writeRegistry(home);
  const env = require(ENV_LIB);
  assert.strictEqual(env.resolveToken(), null);
});

if (failures > 0) {
  process.stderr.write(`\n${failures} test failure(s).\n`);
  process.exit(1);
}
process.stdout.write("\nAll session precedence tests passed.\n");
