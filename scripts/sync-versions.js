#!/usr/bin/env node
"use strict";

// Runs as the npm `version` lifecycle script (during `npm version <x>`):
// propagate the just-bumped package.json version to the bundle VERSION file and
// both plugin manifests, then stage them so they ride in the same version
// commit/tag. This keeps the four version sources that `validate` enforces in
// lockstep, and — because `npm version` also creates the matching git tag —
// the git tag and package.json can never drift.

const fs = require("fs");
const path = require("path");
const { execFileSync } = require("child_process");

const root = path.resolve(__dirname, "..");
const version = require(path.join(root, "package.json")).version;

const staged = [];

// Plain-text VERSION file.
const versionFile = path.join(root, "skills", "_super8-studio-api-shared", "VERSION");
fs.writeFileSync(versionFile, version + "\n");
staged.push(versionFile);

// Plugin manifests: replace only the top-level "version" value to preserve the
// rest of the file's formatting exactly.
for (const manifest of [".claude-plugin/plugin.json", ".codex-plugin/plugin.json"]) {
  const p = path.join(root, manifest);
  const text = fs.readFileSync(p, "utf8");
  const re = /("version"\s*:\s*")[^"]*(")/;
  if (!re.test(text)) {
    throw new Error(`Could not find a "version" field to update in ${manifest}`);
  }
  fs.writeFileSync(p, text.replace(re, `$1${version}$2`));
  staged.push(p);
}

execFileSync("git", ["add", ...staged], { cwd: root, stdio: "inherit" });
process.stdout.write(
  `synced version ${version} → VERSION, .claude-plugin/plugin.json, .codex-plugin/plugin.json\n`
);
