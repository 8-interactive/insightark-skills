"use strict";

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

function printUsage() {
  process.stdout.write(
    [
      "Usage: install [options]",
      "",
      "Options:",
      "  --location global|repo  Install location: global (~) or repo (current directory)",
      "  --base-dir PATH         Explicit base directory (advanced; overrides --location)",
      "  --agents LIST           Comma-separated agents: claude-code,opencode,cursor,github-copilot,codex (or \"all\")",
      "  --target PATH           Install directly to PATH (advanced; no agent subpaths; mutually exclusive with --agents)",
      "  --help                  Show this help message",
      "",
      "Interactive mode runs when --location, --base-dir, --agents, and --target are all omitted.",
      "",
    ].join("\n")
  );
}

function err(message) {
  process.stderr.write(message + "\n");
}

async function promptLocation() {
  err("------------------------------------------------------------");
  err("Step 1 of 3 — Install location");
  err("------------------------------------------------------------");
  err("");
  err("  1) Global — your home directory (~)");
  err("  2) Repo   — this project (current directory)");
  err("");
  const choice = (await common.prompt("Choice [1]: ")).trim();
  switch (choice || "1") {
    case "1":
    case "global":
    case "home":
    case "~":
      return os.homedir();
    case "2":
    case "repo":
    case "project":
      return process.cwd();
    default:
      err("Unknown choice. Enter 1 or 2.");
      return promptLocation();
  }
}

async function promptAgents() {
  err("------------------------------------------------------------");
  err("Step 2 of 3 — Which coding agents do you use?");
  err("------------------------------------------------------------");
  err("");
  err("Skills will be installed only for the agents you pick.");
  err('Enter comma-separated numbers, agent ids, or "all":');
  err("");
  common.AGENTS.forEach((a, i) => {
    err(`  ${i + 1}) ${a.label} (${a.id})`);
  });
  err("");
  const choice = (await common.prompt("Selection [e.g. 3 for Cursor, or 1,3,5]: ")).trim();
  if (!choice) {
    err("At least one agent is required.");
    return promptAgents();
  }
  if (choice === "all") return common.AGENTS.map((a) => a.id);

  const selected = [];
  for (const raw of choice.split(",")) {
    const item = raw.replace(/\s+/g, "");
    if (!item) continue;
    if (/^[0-9]+$/.test(item)) {
      const idx = Number(item);
      if (idx < 1 || idx > common.AGENTS.length) {
        err(`Invalid selection: ${item}`);
        return promptAgents();
      }
      selected.push(common.AGENTS[idx - 1].id);
    } else if (common.isSupportedAgent(item)) {
      selected.push(item);
    } else {
      err(`Invalid selection: ${item}`);
      return promptAgents();
    }
  }
  // De-duplicate while preserving order.
  return Array.from(new Set(selected));
}

function printPlan(layout, location, agents) {
  err("");
  err("============================================================");
  err("  Confirm installation");
  err("============================================================");
  err("");
  err("Super 8 Studio API skills will be installed to:");
  err("");
  if (layout === "direct") {
    err(`  • ${common.formatDisplayPath(location)}`);
  } else {
    for (const agent of agents) {
      const target = common.resolveInstallTarget(location, agent);
      err(`  • ${common.agentLabel(agent)} → ${common.formatDisplayPath(target)}`);
    }
  }
  err("");
}

async function confirm() {
  const answer = (await common.prompt("Proceed with installation? [Y/n]: ")).trim();
  switch (answer || "Y") {
    case "y":
    case "Y":
    case "yes":
    case "YES":
      return true;
    default:
      err("Installation cancelled.");
      return false;
  }
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

  let layout = "per-agent";
  let expandedBase = "";
  let selectedAgents = [];
  const installTargets = [];

  if (targetDir) {
    layout = "direct";
    expandedBase = common.expandBaseDir(targetDir);
    installTargets.push(expandedBase);
  } else if (interactive) {
    err("");
    err("============================================================");
    err("  Super 8 Studio API Skills — Installer");
    err("============================================================");
    err("");
    err(`Package: ${common.countBundleSkills(common.BUNDLE_DIR)} skill(s) from this bundle.`);
    err("");

    expandedBase = await promptLocation();
    selectedAgents = await promptAgents();
    if (selectedAgents.length === 0) {
      err("No agents selected.");
      return 1;
    }
    for (const agent of selectedAgents) {
      installTargets.push(common.resolveInstallTarget(expandedBase, agent));
    }
    printPlan(layout, expandedBase, selectedAgents);
    if (!(await confirm())) return 0;
  } else {
    // Non-interactive: resolve base from --base-dir or --location.
    if (baseDir) {
      expandedBase = common.expandBaseDir(baseDir);
    } else if (location === "repo") {
      expandedBase = process.cwd();
    } else if (location === "global" || location === "") {
      expandedBase = os.homedir();
    } else {
      err('--location must be "global" or "repo".');
      return 1;
    }
    if (!agentsCsv) {
      err("Either --agents or --target is required in non-interactive mode.");
      printUsage();
      return 1;
    }
    selectedAgents = common.parseAgents(agentsCsv);
    selectedAgents = Array.from(new Set(selectedAgents));
    for (const agent of selectedAgents) {
      installTargets.push(common.resolveInstallTarget(expandedBase, agent));
    }
  }

  if (installTargets.length === 0) {
    err("No install targets resolved.");
    return 1;
  }

  const agentsForConfig = layout === "direct" ? "" : selectedAgents.join(",");
  installConfig.writeInstallConfig(layout, expandedBase, agentsForConfig, installTargets);
  err(`Wrote install registry ${common.formatDisplayPath(installConfig.installConfigPath())}`);

  err("");
  err("Installing Super 8 Studio API skills...");
  err("");
  for (const target of installTargets) {
    err(`  → ${common.formatDisplayPath(target)}`);
    common.ensureDirectory(target);
    common.removeBundleDirs(target);
    common.copyBundle(common.BUNDLE_DIR, target);
  }

  err("");
  err(`Done. Installed to ${installTargets.length} location(s).`);
  err("");
  err("Next: run `setup` to configure credentials and verify with doctor:");
  err("  super8-studio-api-skills setup");
  return 0;
}

module.exports = { run };
