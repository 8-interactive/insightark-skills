#!/usr/bin/env node
"use strict";

// Records installed SUPER 8 Studio skills paths in ~/.super8-studio.config.
// For package managers that already copied skills/ themselves. Prefer
// `insightark-skills install` when the flow can copy files directly.

const path = require("path");
const common = require(path.join(__dirname, "..", "installer", "common.js"));
const installConfig = require(path.join(
  common.BUNDLE_DIR,
  "_super8-studio-api-shared",
  "scripts",
  "lib",
  "install-config.js"
));

function err(message) {
  process.stderr.write(message + "\n");
}

function printUsage() {
  process.stdout.write(
    [
      "Usage: register-install.js [options]",
      "",
      "Records installed SUPER 8 Studio skills paths in ~/.super8-studio.config.",
      "",
      "Options:",
      "  --target PATH     Installed skills directory to record",
      "  --base-dir PATH   Base directory for per-agent installs",
      "  --agents LIST     Comma-separated agents: claude-code,opencode,cursor,github-copilot,codex",
      "  --help            Show this help message",
      "",
    ].join("\n")
  );
}

function main() {
  let baseDir = "";
  let agentsCsv = "";
  let targetDir = "";
  let layout = "direct";

  const argv = process.argv.slice(2);
  for (let i = 0; i < argv.length; i++) {
    switch (argv[i]) {
      case "--target":
        targetDir = argv[++i] || "";
        layout = "direct";
        break;
      case "--base-dir":
        baseDir = argv[++i] || "";
        layout = "per-agent";
        break;
      case "--agents":
        agentsCsv = argv[++i] || "";
        layout = "per-agent";
        break;
      case "--help":
        printUsage();
        return 0;
      default:
        err(`Unknown option: ${argv[i]}`);
        printUsage();
        return 1;
    }
  }

  const installTargets = [];
  let expandedBase = "";

  if (targetDir) {
    if (agentsCsv || baseDir) {
      err("--target cannot be combined with --base-dir or --agents.");
      return 1;
    }
    expandedBase = common.expandBaseDir(targetDir);
    installTargets.push(expandedBase);
    layout = "direct";
  } else {
    if (!agentsCsv) {
      err("Either --target or --agents is required.");
      printUsage();
      return 1;
    }
    expandedBase = common.expandBaseDir(baseDir || "~");
    for (const agent of common.parseAgents(agentsCsv)) {
      installTargets.push(common.resolveInstallTarget(expandedBase, agent));
    }
    layout = "per-agent";
  }

  if (installTargets.length === 0) {
    err("No install targets resolved.");
    return 1;
  }

  installConfig.writeInstallConfig(layout, expandedBase, agentsCsv, installTargets);
  process.stdout.write(
    `Recorded SUPER 8 Studio skills install registry: ${common.formatDisplayPath(
      installConfig.installConfigPath()
    )}\n`
  );
  for (const target of installTargets) {
    process.stdout.write(`  - ${common.formatDisplayPath(target)}\n`);
  }
  return 0;
}

process.exit(main());
