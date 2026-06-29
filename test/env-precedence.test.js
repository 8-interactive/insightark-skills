#!/usr/bin/env node
"use strict";

// Focused test for env.js credential load order. Verifies precedence
// (highest first): process env / plugin options > repo file > skills-dir file
// > user file, matching the original bash env.sh behavior.
//
// Runs with the Node built-in test runner equivalents via plain asserts so it
// needs no dependencies. Avoids overriding $HOME (the local `node` is a
// version-manager shim that resolves through $HOME) by stubbing os.homedir().

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

let failures = 0;
function check(name, fn) {
  // Fresh sandbox per case.
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
  // Clear S8_* and plugin options so each case starts clean.
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

function writeEnv(file, lines) {
  fs.writeFileSync(file, lines.join("\n") + "\n");
}

check("user file supplies all credentials", ({ home }) => {
  writeEnv(path.join(home, ".super8-studio.env"), [
    "S8_API_URL='https://user.example'",
    "S8_SESSION_TOKEN='r:user'",
    "S8_ORG_ID='org-user'",
  ]);
  const env = require(ENV_LIB);
  assert.strictEqual(env.loadRuntimeEnv(), true);
  assert.strictEqual(process.env.S8_API_URL, "https://user.example");
  assert.strictEqual(process.env.S8_ORG_ID, "org-user");
  assert.strictEqual(process.env.S8_API_ROOT, "https://user.example");
});

check("repo file overrides user file", ({ home, cwd }) => {
  writeEnv(path.join(home, ".super8-studio.env"), [
    "S8_API_URL='https://user.example'",
    "S8_SESSION_TOKEN='r:user'",
    "S8_ORG_ID='org-user'",
  ]);
  writeEnv(path.join(cwd, ".super8-studio.env"), ["S8_ORG_ID='org-repo'"]);
  const env = require(ENV_LIB);
  assert.strictEqual(env.loadRuntimeEnv(), true);
  assert.strictEqual(process.env.S8_ORG_ID, "org-repo");
  // URL/token still come from the user file.
  assert.strictEqual(process.env.S8_API_URL, "https://user.example");
});

check("skills-dir file overrides user file", ({ home, skillsDir }) => {
  writeEnv(path.join(home, ".super8-studio.env"), [
    "S8_API_URL='https://user.example'",
    "S8_SESSION_TOKEN='r:user'",
    "S8_ORG_ID='org-user'",
  ]);
  writeEnv(path.join(skillsDir, ".super8-studio.env"), [
    "S8_ORG_ID='org-skills'",
  ]);
  // Registry points at the skills target.
  writeEnv(path.join(home, ".super8-studio.config"), [
    "layout=per-agent",
    "base_dir=" + home,
    "agents=claude-code",
    "skills_targets=" + skillsDir,
  ]);
  const env = require(ENV_LIB);
  assert.strictEqual(env.loadRuntimeEnv(), true);
  assert.strictEqual(process.env.S8_ORG_ID, "org-skills");
});

check("repo file overrides skills-dir file", ({ home, cwd, skillsDir }) => {
  writeEnv(path.join(home, ".super8-studio.env"), [
    "S8_API_URL='https://user.example'",
    "S8_SESSION_TOKEN='r:user'",
  ]);
  writeEnv(path.join(skillsDir, ".super8-studio.env"), [
    "S8_ORG_ID='org-skills'",
  ]);
  writeEnv(path.join(cwd, ".super8-studio.env"), ["S8_ORG_ID='org-repo'"]);
  writeEnv(path.join(home, ".super8-studio.config"), [
    "skills_targets=" + skillsDir,
  ]);
  const env = require(ENV_LIB);
  assert.strictEqual(env.loadRuntimeEnv(), true);
  assert.strictEqual(process.env.S8_ORG_ID, "org-repo");
});

check("process env beats every file", ({ home, cwd }) => {
  writeEnv(path.join(home, ".super8-studio.env"), [
    "S8_API_URL='https://user.example'",
    "S8_SESSION_TOKEN='r:user'",
    "S8_ORG_ID='org-user'",
  ]);
  writeEnv(path.join(cwd, ".super8-studio.env"), ["S8_ORG_ID='org-repo'"]);
  process.env.S8_ORG_ID = "org-process";
  const env = require(ENV_LIB);
  assert.strictEqual(env.loadRuntimeEnv(), true);
  assert.strictEqual(process.env.S8_ORG_ID, "org-process");
});

check("plugin option maps to S8_* when unset", ({ home }) => {
  writeEnv(path.join(home, ".super8-studio.env"), [
    "S8_API_URL='https://user.example'",
  ]);
  process.env.CLAUDE_PLUGIN_OPTION_S8_SESSION_TOKEN = "r:plugin";
  const env = require(ENV_LIB);
  assert.strictEqual(env.loadRuntimeEnv(), true);
  assert.strictEqual(process.env.S8_SESSION_TOKEN, "r:plugin");
});

check("process token beats plugin option", ({ home }) => {
  writeEnv(path.join(home, ".super8-studio.env"), [
    "S8_API_URL='https://user.example'",
  ]);
  process.env.S8_SESSION_TOKEN = "r:process";
  process.env.CLAUDE_PLUGIN_OPTION_S8_SESSION_TOKEN = "r:plugin";
  const env = require(ENV_LIB);
  assert.strictEqual(env.loadRuntimeEnv(), true);
  assert.strictEqual(process.env.S8_SESSION_TOKEN, "r:process");
});

check("missing credentials returns false", () => {
  const env = require(ENV_LIB);
  assert.strictEqual(env.loadRuntimeEnv(), false);
});

check("api root strips trailing slash", ({ home }) => {
  writeEnv(path.join(home, ".super8-studio.env"), [
    "S8_API_URL='https://user.example/'",
    "S8_SESSION_TOKEN='r:user'",
  ]);
  const env = require(ENV_LIB);
  assert.strictEqual(env.loadRuntimeEnv(), true);
  assert.strictEqual(process.env.S8_API_ROOT, "https://user.example");
});

check("unquoted legacy values parse", ({ home }) => {
  writeEnv(path.join(home, ".super8-studio.env"), [
    "S8_API_URL=https://legacy.example",
    "S8_SESSION_TOKEN=r:legacytoken",
  ]);
  const env = require(ENV_LIB);
  assert.strictEqual(env.loadRuntimeEnv(), true);
  assert.strictEqual(process.env.S8_API_URL, "https://legacy.example");
  assert.strictEqual(process.env.S8_SESSION_TOKEN, "r:legacytoken");
});

if (failures > 0) {
  process.stderr.write(`\n${failures} test failure(s).\n`);
  process.exit(1);
}
process.stdout.write("\nAll env precedence tests passed.\n");
