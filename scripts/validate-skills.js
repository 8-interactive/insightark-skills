#!/usr/bin/env node
"use strict";

const fs = require("fs");
const path = require("path");

const REPO_DIR = path.resolve(__dirname, "..");
let failures = 0;

function fail(msg) {
  process.stderr.write(`FAIL: ${msg}\n`);
  failures++;
}
function pass(msg) {
  process.stdout.write(`PASS: ${msg}\n`);
}

function readJson(relPath) {
  return JSON.parse(fs.readFileSync(path.join(REPO_DIR, relPath), "utf8"));
}

function requireFile(relPath) {
  if (fs.existsSync(path.join(REPO_DIR, relPath))) pass(`${relPath} exists`);
  else fail(`${relPath} is missing`);
}

function validateJson(relPath) {
  try {
    readJson(relPath);
    pass(`${relPath} is valid JSON`);
  } catch (_e) {
    fail(`${relPath} is not valid JSON`);
  }
}

function validateVersions() {
  let bundle;
  try {
    bundle = fs
      .readFileSync(path.join(REPO_DIR, "skills/_super8-studio-api-shared/VERSION"), "utf8")
      .trim();
  } catch (_e) {
    fail("bundle VERSION is missing");
    return;
  }
  let codex, claude, pkg;
  try {
    codex = readJson(".codex-plugin/plugin.json").version;
    claude = readJson(".claude-plugin/plugin.json").version;
    pkg = readJson("package.json").version;
  } catch (_e) {
    fail("a plugin/package version is missing");
    return;
  }
  if (bundle === codex && bundle === claude && bundle === pkg) {
    pass(`versions are synchronized (${bundle})`);
  } else {
    fail(`versions differ: bundle=${bundle} codex=${codex} claude=${claude} package=${pkg}`);
  }
}

function validatePluginSkillsPath(manifestPath, label) {
  let skillsPath;
  try {
    skillsPath = readJson(manifestPath).skills;
  } catch (_e) {
    fail(`${manifestPath} skills is missing`);
    return;
  }
  if (!skillsPath) {
    fail(`${manifestPath} skills is missing`);
    return;
  }
  const resolved = path.resolve(REPO_DIR, skillsPath);
  if (resolved === path.join(REPO_DIR, "skills")) {
    pass(`${label} skills path resolves to skills/`);
  } else {
    fail(`${label} skills path resolves to unexpected path: ${resolved}`);
  }
}

function validateMarketplaceSources() {
  try {
    const agentsSource = readJson(".agents/plugins/marketplace.json").plugins[0].source.path;
    if (agentsSource === "./") pass("agents marketplace source.path points to repository root");
    else fail(`agents marketplace source.path should be ./ but is ${agentsSource}`);
  } catch (_e) {
    fail(".agents/plugins/marketplace.json source.path is missing");
  }
  try {
    const claudeSource = readJson(".claude-plugin/marketplace.json").plugins[0].source;
    if (claudeSource === "./") pass("Claude marketplace source points to repository root");
    else fail(`Claude marketplace source should be ./ but is ${JSON.stringify(claudeSource)}`);
  } catch (_e) {
    fail(".claude-plugin/marketplace.json plugin source is missing");
  }
}

function validatePackageBin() {
  let binPath;
  try {
    binPath = readJson("package.json").bin["insightark-skills"];
  } catch (_e) {
    fail("package.json bin.insightark-skills is missing");
    return;
  }
  if (!binPath) {
    fail("package.json bin.insightark-skills is missing");
    return;
  }
  binPath = binPath.replace(/^\.\//, "");
  if (fs.existsSync(path.join(REPO_DIR, binPath))) pass(`package bin exists (${binPath})`);
  else fail(`package bin target is missing: ${binPath}`);
}

function frontmatterValue(file, key) {
  const text = fs.readFileSync(file, "utf8");
  const lines = text.split(/\r?\n/);
  if (lines[0] !== "---") return "";
  for (let i = 1; i < lines.length; i++) {
    if (lines[i] === "---") break;
    if (lines[i].startsWith(key + ":")) {
      return lines[i].slice(key.length + 1).trim();
    }
  }
  return "";
}

function validateSkills() {
  const skillsRoot = path.join(REPO_DIR, "skills");
  const dirs = fs
    .readdirSync(skillsRoot, { withFileTypes: true })
    .filter((e) => e.isDirectory() && e.name.startsWith("super8-studio-"))
    .map((e) => e.name)
    .sort();
  let count = 0;
  for (const folder of dirs) {
    count++;
    const skillFile = path.join(skillsRoot, folder, "SKILL.md");
    if (!fs.existsSync(skillFile)) {
      fail(`${folder} is missing SKILL.md`);
      continue;
    }
    const name = frontmatterValue(skillFile, "name");
    const description = frontmatterValue(skillFile, "description");
    if (name === folder) pass(`${folder} frontmatter name matches folder`);
    else fail(`${folder} frontmatter name mismatch: ${name || "<missing>"}`);
    if (description.length >= 40) pass(`${folder} description is present`);
    else fail(`${folder} description is missing or too short`);
  }
  if (count > 0) pass(`found ${count} skill directories`);
  else fail("no skill directories found under skills/");
}

function fileContains(relPath, needle) {
  try {
    return fs.readFileSync(path.join(REPO_DIR, relPath), "utf8").includes(needle);
  } catch (_e) {
    return false;
  }
}

function validateInstallContract() {
  if (fileContains("installer/install.js", "writeInstallConfig"))
    pass("installer/install.js writes install registry");
  else fail("installer/install.js does not call writeInstallConfig");

  if (fileContains("scripts/register-install.js", "writeInstallConfig"))
    pass("register-install.js writes install registry");
  else fail("register-install.js does not call writeInstallConfig");

  if (
    fileContains("scripts/super8-skills-cli.js", "installer") &&
    fileContains("scripts/super8-skills-cli.js", "install.js")
  )
    pass("npm adapter delegates install to the Node installer");
  else fail("npm adapter does not delegate install to the Node installer");

  // Ensure the bash installer scripts are fully removed (hard cut).
  for (const legacy of [
    "install.sh",
    "uninstall.sh",
    "setup-env.sh",
    "installer/common.sh",
  ]) {
    if (!fs.existsSync(path.join(REPO_DIR, legacy))) pass(`legacy ${legacy} removed`);
    else fail(`legacy bash script still present: ${legacy}`);
  }

  // Ensure no .sh files remain in the shipped skills bundle.
  const shInSkills = listShFiles(path.join(REPO_DIR, "skills"));
  if (shInSkills.length === 0) pass("no .sh files in skills/ bundle");
  else fail(`shipped bundle still contains .sh files: ${shInSkills.length}`);
}

function listShFiles(dir) {
  const out = [];
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) out.push(...listShFiles(full));
    else if (entry.name.endsWith(".sh")) out.push(full);
  }
  return out;
}

requireFile(".codex-plugin/plugin.json");
requireFile(".agents/plugins/marketplace.json");
requireFile(".claude-plugin/plugin.json");
requireFile(".claude-plugin/marketplace.json");
requireFile("package.json");
requireFile("LICENSE");
requireFile("SECURITY.md");
requireFile("CHANGELOG.md");
requireFile("CONTRIBUTING.md");
requireFile("scripts/register-install.js");
requireFile("installer/install.js");
requireFile("installer/uninstall.js");
requireFile("installer/setup.js");

validateJson(".codex-plugin/plugin.json");
validateJson(".agents/plugins/marketplace.json");
validateJson(".claude-plugin/plugin.json");
validateJson(".claude-plugin/marketplace.json");
validateJson("package.json");
validateVersions();
validatePluginSkillsPath(".codex-plugin/plugin.json", "Codex plugin");
validatePluginSkillsPath(".claude-plugin/plugin.json", "Claude plugin");
validateMarketplaceSources();
validatePackageBin();
validateSkills();
validateInstallContract();

if (failures > 0) {
  process.stderr.write(`\n${failures} validation failure(s).\n`);
  process.exit(1);
}
process.stdout.write("\nAll validations passed.\n");
