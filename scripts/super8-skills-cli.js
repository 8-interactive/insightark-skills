#!/usr/bin/env node
"use strict";

const path = require("path");
const { spawnSync } = require("child_process");

const root = path.resolve(__dirname, "..");

function usage() {
  process.stdout.write(
    [
      "Usage:",
      "  super8-studio-api-skills install [options]",
      "  super8-studio-api-skills uninstall [options]",
      "  super8-studio-api-skills setup [options]",
      "  super8-studio-api-skills doctor",
      "",
      "Examples:",
      "  super8-studio-api-skills install                       # interactive",
      "  super8-studio-api-skills install --location global --agents claude-code,cursor",
      "  super8-studio-api-skills install --target ~/.agents/skills",
      "  super8-studio-api-skills setup",
      "  super8-studio-api-skills doctor",
      "",
    ].join("\n")
  );
}

async function main() {
  const [command, ...args] = process.argv.slice(2);

  const common = require(path.join(root, "installer", "common.js"));
  const finish = (code) => {
    common.closeRl();
    process.exit(code);
  };

  switch (command) {
    case "install": {
      const install = require(path.join(root, "installer", "install.js"));
      finish(await install.run(args));
      break;
    }
    case "uninstall": {
      const uninstall = require(path.join(root, "installer", "uninstall.js"));
      finish(await uninstall.run(args));
      break;
    }
    case "setup": {
      const setup = require(path.join(root, "installer", "setup.js"));
      finish(await setup.run(args));
      break;
    }
    case "doctor": {
      const doctorScript = path.join(
        root,
        "skills",
        "_super8-studio-api-shared",
        "scripts",
        "doctor.js"
      );
      const result = spawnSync(process.execPath, [doctorScript, ...args], {
        stdio: "inherit",
      });
      process.exit(result.status === null ? 1 : result.status);
      break;
    }
    case undefined:
    case "-h":
    case "--help":
    case "help":
      usage();
      break;
    default:
      process.stderr.write(`Unknown command: ${command}\n`);
      usage();
      process.exit(1);
  }
}

main().catch((err) => {
  process.stderr.write(`${err && err.message ? err.message : err}\n`);
  process.exit(1);
});
