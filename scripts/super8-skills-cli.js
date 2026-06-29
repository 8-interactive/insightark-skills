#!/usr/bin/env node
"use strict";

const path = require("path");
const { spawnSync } = require("child_process");

const root = path.resolve(__dirname, "..");

function usage() {
  process.stdout.write(
    [
      "Usage:",
      "  insightark-skills install [options]",
      "  insightark-skills uninstall [options]",
      "  insightark-skills login",
      "  insightark-skills logout",
      "  insightark-skills setup [options]   (deprecated; use login)",
      "  insightark-skills doctor",
      "",
      "Examples:",
      "  insightark-skills install                       # interactive",
      "  insightark-skills install --location global --agents claude-code,cursor",
      "  insightark-skills install --target ~/.agents/skills",
      "  insightark-skills setup",
      "  insightark-skills doctor",
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
    case "login": {
      const login = require(path.join(root, "installer", "login.js"));
      finish(await login.run(args));
      break;
    }
    case "logout": {
      const logout = require(path.join(root, "installer", "logout.js"));
      finish(await logout.run(args));
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
