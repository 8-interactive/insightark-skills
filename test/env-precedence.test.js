#!/usr/bin/env node
"use strict";

// Focused test for env.js credential load order and API-URL resolution.
//
// Credentials (token + org) precedence (highest first): process env / plugin
// options > repo file > skills-dir file > user file.
//
// API URL is NOT a credential: it is fixed at install time, resolved from the
// install registry's api_url, falling back to production when absent, and is
// never read from S8_API_URL in the environment or env files.
//
// Avoids overriding $HOME (the local `node` is a version-manager shim that
// resolves through $HOME) by stubbing os.homedir().

const assert = require("assert");
const fs = require("fs");
const os = require("os");
const path = require("path");

const SCRIPTS = path.join(
  __dirname,
  "..",
  "skills",
  "_super8-studio-api-shared",
  "scripts"
);
const ENV_LIB = path.join(SCRIPTS, "lib", "env.js");
const INSTALL_CONFIG_LIB = path.join(SCRIPTS, "lib", "install-config.js");
const PRODUCTION = "https://api-next.no8.io";

let failures = 0;
function check(name, fn) {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "s8-env-"));
  const home = path.join(root, "home");
  const cwd = path.join(root, "cwd");
  const skillsDir = path.join(root, "skills-target");
  fs.mkdirSync(home);
  fs.mkdirSync(cwd);
  fs.mkdirSync(skillsDir);

  const realHomedir = os.homedir;
  const realCwd = process.cwd();
  const savedEnv = { ...process.env };
  os.homedir = () => home;
  process.chdir(cwd);
  for (const k of Object.keys(process.env)) {
    if (k.startsWith("S8_") || k.startsWith("CLAUDE_PLUGIN_OPTION_S8_")) {
      delete process.env[k];
    }
  }
  delete require.cache[require.resolve(ENV_LIB)];
  delete require.cache[require.resolve(INSTALL_CONFIG_LIB)];

  try {
    fn({ home, cwd, skillsDir });
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

function writeFileLines(file, lines) {
  fs.writeFileSync(file, lines.join("\n") + "\n");
}
const tokenLine = "S8_SESSION_TOKEN='r:user'";

// ---- credential (token + org) precedence ----

check("user file supplies the token; API URL falls back to production", ({ home }) => {
  writeFileLines(path.join(home, ".super8-studio.env"), [tokenLine, "S8_ORG_ID='org-user'"]);
  const env = require(ENV_LIB);
  assert.strictEqual(env.loadRuntimeEnv(), true);
  assert.strictEqual(process.env.S8_SESSION_TOKEN, "r:user");
  assert.strictEqual(process.env.S8_ORG_ID, "org-user");
  assert.strictEqual(process.env.S8_API_ROOT, PRODUCTION);
});

check("repo file org overrides user file org", ({ home, cwd }) => {
  writeFileLines(path.join(home, ".super8-studio.env"), [tokenLine, "S8_ORG_ID='org-user'"]);
  writeFileLines(path.join(cwd, ".super8-studio.env"), ["S8_ORG_ID='org-repo'"]);
  const env = require(ENV_LIB);
  assert.strictEqual(env.loadRuntimeEnv(), true);
  assert.strictEqual(process.env.S8_ORG_ID, "org-repo");
});

check("skills-dir file org overrides user file org", ({ home, skillsDir }) => {
  writeFileLines(path.join(home, ".super8-studio.env"), [tokenLine, "S8_ORG_ID='org-user'"]);
  writeFileLines(path.join(skillsDir, ".super8-studio.env"), ["S8_ORG_ID='org-skills'"]);
  writeFileLines(path.join(home, ".super8-studio.config"), ["skills_targets=" + skillsDir]);
  const env = require(ENV_LIB);
  assert.strictEqual(env.loadRuntimeEnv(), true);
  assert.strictEqual(process.env.S8_ORG_ID, "org-skills");
});

check("process env token beats every file", ({ home }) => {
  writeFileLines(path.join(home, ".super8-studio.env"), ["S8_SESSION_TOKEN='r:file'"]);
  process.env.S8_SESSION_TOKEN = "r:process";
  const env = require(ENV_LIB);
  assert.strictEqual(env.loadRuntimeEnv(), true);
  assert.strictEqual(process.env.S8_SESSION_TOKEN, "r:process");
});

check("plugin option maps the token when unset", ({ home }) => {
  writeFileLines(path.join(home, ".super8-studio.env"), ["S8_ORG_ID='org-user'"]);
  process.env.CLAUDE_PLUGIN_OPTION_S8_SESSION_TOKEN = "r:plugin";
  const env = require(ENV_LIB);
  assert.strictEqual(env.loadRuntimeEnv(), true);
  assert.strictEqual(process.env.S8_SESSION_TOKEN, "r:plugin");
});

check("missing token returns false", () => {
  const env = require(ENV_LIB);
  assert.strictEqual(env.loadRuntimeEnv(), false);
});

// ---- API URL resolution (registry-driven, env ignored) ----

check("registry api_url is used as the API root", ({ home }) => {
  writeFileLines(path.join(home, ".super8-studio.env"), [tokenLine]);
  writeFileLines(path.join(home, ".super8-studio.config"), [
    "channel=staging",
    "api_url=https://stage-api-next.no8.io",
  ]);
  const env = require(ENV_LIB);
  assert.strictEqual(env.loadRuntimeEnv(), true);
  assert.strictEqual(process.env.S8_API_ROOT, "https://stage-api-next.no8.io");
});

check("S8_API_URL in env and env file is ignored", ({ home }) => {
  writeFileLines(path.join(home, ".super8-studio.env"), [
    tokenLine,
    "S8_API_URL='https://from-file.example'",
  ]);
  writeFileLines(path.join(home, ".super8-studio.config"), [
    "channel=staging",
    "api_url=https://stage-api-next.no8.io",
  ]);
  process.env.S8_API_URL = "https://from-process.example";
  const env = require(ENV_LIB);
  assert.strictEqual(env.loadRuntimeEnv(), true);
  assert.strictEqual(process.env.S8_API_ROOT, "https://stage-api-next.no8.io");
});

check("production fallback when no registry api_url", ({ home }) => {
  writeFileLines(path.join(home, ".super8-studio.env"), [tokenLine]);
  const env = require(ENV_LIB);
  assert.strictEqual(env.loadRuntimeEnv(), true);
  assert.strictEqual(process.env.S8_API_ROOT, PRODUCTION);
  assert.strictEqual(env.resolveApiRoot().source, "production-fallback");
});

check("registry api_url trailing slash is stripped", ({ home }) => {
  writeFileLines(path.join(home, ".super8-studio.env"), [tokenLine]);
  writeFileLines(path.join(home, ".super8-studio.config"), [
    "api_url=https://stage-api-next.no8.io/",
  ]);
  const env = require(ENV_LIB);
  assert.strictEqual(env.loadRuntimeEnv(), true);
  assert.strictEqual(process.env.S8_API_ROOT, "https://stage-api-next.no8.io");
});

if (failures > 0) {
  process.stderr.write(`\n${failures} test failure(s).\n`);
  process.exit(1);
}
process.stdout.write("\nAll env precedence tests passed.\n");
