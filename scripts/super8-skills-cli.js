#!/usr/bin/env node

const fs = require("fs");
const path = require("path");
const { spawnSync } = require("child_process");

const root = path.resolve(__dirname, "..");
const installScript = path.join(root, "install.sh");
const setupScript = path.join(root, "setup-env.sh");

function usage() {
  console.log(`Usage:
  super8-studio-api-skills install [install.sh options]
  super8-studio-api-skills setup [setup-env.sh options]
  super8-studio-api-skills doctor

Examples:
  super8-studio-api-skills install --base-dir ~ --agents codex
  super8-studio-api-skills install --target ~/.agents/skills
  super8-studio-api-skills setup --check`);
}

function run(script, args) {
  if (!fs.existsSync(script)) {
    console.error(`Missing script: ${script}`);
    process.exit(1);
  }

  const result = spawnSync("bash", [script, ...args], {
    cwd: root,
    stdio: "inherit",
  });
  process.exit(result.status === null ? 1 : result.status);
}

const [command, ...args] = process.argv.slice(2);

switch (command) {
  case "install":
    run(installScript, args);
    break;
  case "setup":
    run(setupScript, args);
    break;
  case "doctor":
    run(setupScript, ["--check", ...args]);
    break;
  case undefined:
  case "-h":
  case "--help":
  case "help":
    usage();
    break;
  default:
    console.error(`Unknown command: ${command}`);
    usage();
    process.exit(1);
}
