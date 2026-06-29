"use strict";

const fs = require("fs");
const os = require("os");
const path = require("path");
const common = require("./common.js");
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
      "Usage: uninstall [options]",
      "",
      "Options:",
      "  --location global|repo  Where skills were installed: global (~) or repo (current directory)",
      "  --base-dir PATH         Explicit base directory (advanced; overrides --location)",
      "  --agents LIST           Comma-separated agents (or \"all\")",
      "  --target PATH           Remove directly from PATH (advanced; mutually exclusive with --agents)",
      "  --help                  Show this help message",
      "",
      "Interactive mode runs when --location, --base-dir, --agents, and --target are all omitted.",
      "",
    ].join("\n")
  );
}

async function promptLocation() {
  err("  1) Global — your home directory (~)");
  err("  2) Repo   — this project (current directory)");
  err("");
  const choice = (await common.prompt("Choice [1]: ")).trim();
  switch (choice || "1") {
    case "1":
    case "global":
      return os.homedir();
    case "2":
    case "repo":
      return process.cwd();
    default:
      err("Unknown choice. Enter 1 or 2.");
      return promptLocation();
  }
}

async function promptAgents(base) {
  const items = common.AGENTS.map((a) => ({ id: a.id, label: a.label }));
  // Pre-check agents that actually have the bundle installed under base.
  const preselected = common.detectAgentsWithBundle(base);
  return common.multiSelect(
    "Select agents to remove SUPER 8 Studio InsightArk Skills from:",
    items,
    { preselected }
  );
}

async function run(argv) {
  let location = "";
  let baseDir = "";
  let agentsCsv = "";
  let targetDir = "";
  let interactive = true;

  for (let i = 0; i < argv.length; i++) {
    switch (argv[i]) {
      case "--location":
        location = argv[++i] || "";
        interactive = false;
        break;
      case "--base-dir":
        baseDir = argv[++i] || "";
        interactive = false;
        break;
      case "--agents":
        agentsCsv = argv[++i] || "";
        interactive = false;
        break;
      case "--target":
        targetDir = argv[++i] || "";
        interactive = false;
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

  if (targetDir && (agentsCsv || location || baseDir)) {
    err("--target cannot be combined with --agents, --location, or --base-dir.");
    return 1;
  }

  const removeTargets = [];

  if (targetDir) {
    removeTargets.push(common.expandBaseDir(targetDir));
  } else if (interactive) {
    err("");
    err("============================================================");
    err("  SUPER 8 Studio InsightArk Skills — Uninstaller");
    err("============================================================");
    err("");

    let usedRegistry = false;
    if (installConfig.installConfigPresent()) {
      err(
        `Found install registry: ${common.formatDisplayPath(installConfig.installConfigPath())}`
      );
      const answer = (await common.prompt("Use saved install locations? [Y/n]: ")).trim();
      if (["", "y", "Y", "yes", "YES"].includes(answer || "Y") || answer === "") {
        for (const target of installConfig.installSkillsTargets()) {
          removeTargets.push(target);
        }
        if (removeTargets.length === 0) {
          err("No targets in install registry.");
          return 1;
        }
        usedRegistry = true;
      }
    }

    if (!usedRegistry) {
      const base = await promptLocation();
      const agents = await promptAgents(base);
      if (agents.length === 0) {
        err("No agents selected.");
        return 1;
      }
      for (const agent of agents) {
        removeTargets.push(common.resolveInstallTarget(base, agent));
      }
    }
  } else {
    let expandedBase;
    if (baseDir) {
      expandedBase = common.expandBaseDir(baseDir);
    } else if (location === "repo") {
      expandedBase = process.cwd();
    } else {
      expandedBase = os.homedir();
    }
    if (!agentsCsv) {
      err("Either --agents or --target is required in non-interactive mode.");
      printUsage();
      return 1;
    }
    for (const agent of common.parseAgents(agentsCsv)) {
      removeTargets.push(common.resolveInstallTarget(expandedBase, agent));
    }
  }

  if (removeTargets.length === 0) {
    err("No uninstall targets resolved.");
    return 1;
  }

  for (const target of removeTargets) {
    let exists = false;
    try {
      exists = fs.statSync(target).isDirectory();
    } catch (_err) {
      exists = false;
    }
    if (exists) {
      common.removeBundleDirs(target);
      process.stdout.write(
        `Removed SUPER 8 Studio InsightArk Skills from ${common.formatDisplayPath(target)}\n`
      );
      const envFile = path.join(target.replace(/\/+$/, ""), ".super8-studio.env");
      if (fs.existsSync(envFile)) {
        fs.rmSync(envFile, { force: true });
        process.stdout.write(`Removed ${common.formatDisplayPath(envFile)}\n`);
      }
    } else {
      err(`Skipped missing directory: ${common.formatDisplayPath(target)}`);
    }
  }

  if (installConfig.installConfigPresent()) {
    installConfig.removeInstallConfig();
    process.stdout.write(
      `Removed install registry ${common.formatDisplayPath(installConfig.installConfigPath())}\n`
    );
  }
  return 0;
}

module.exports = { run };
