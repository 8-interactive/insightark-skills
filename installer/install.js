"use strict";

const os = require("os");
const path = require("path");
const common = require("./common.js");
const SCRIPTS_DIR = path.join(common.BUNDLE_DIR, "_super8-studio-api-shared", "scripts");
const installConfig = require(path.join(SCRIPTS_DIR, "lib", "install-config.js"));
const env = require(path.join(SCRIPTS_DIR, "lib", "env.js"));

// After install, verify any existing token against the API; offer login when
// interactive and the token is missing or invalid. Never launches login in
// non-interactive mode (CI/flags/--target).
async function verifyOrLogin(interactive) {
  const apiRoot = env.resolveApiRoot().root;
  const token = env.resolveToken();
  err("");

  if (!interactive) {
    if (token) {
      const v = await common.verifyToken(apiRoot, token);
      if (v.ok) err(`Authenticated as ${v.email || "your account"}.`);
      else err("A token is present but could not be verified. Run `login` to authenticate.");
    } else {
      err("Next: authenticate with `super8-studio-api-skills login`.");
    }
    return;
  }

  err("Verifying credentials...");
  if (token) {
    const v = await common.verifyToken(apiRoot, token);
    if (v.ok) {
      err(`Authenticated as ${v.email || "your account"}.`);
      return;
    }
    if (v.status === 401) {
      err("Stored token is invalid or expired.");
    } else {
      err(`Could not verify credentials (${v.error || "HTTP " + v.status}). Run \`login\` or \`doctor\` later.`);
      return;
    }
  } else {
    err("No credentials found yet.");
  }

  const answer = (await common.prompt("Log in now? [Y/n]: ")).trim();
  if (["", "y", "Y", "yes", "YES"].includes(answer || "Y")) {
    const login = require("./login.js");
    await login.run([]);
  } else {
    err("You can authenticate later with `super8-studio-api-skills login`.");
  }
}

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
      "  --staging               Internal: use the staging API endpoint instead of production",
      "  --api-url URL           Internal: use a custom API endpoint (overrides --staging)",
      "  --help                  Show this help message",
      "",
      "Interactive mode runs when --location, --base-dir, --agents, and --target are all omitted.",
      "API environment is fixed at install time (default: production).",
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

async function promptAgents(base) {
  err("------------------------------------------------------------");
  err("Step 2 of 3 — Which coding agents do you use?");
  err("------------------------------------------------------------");
  const items = common.AGENTS.map((a) => ({ id: a.id, label: a.label }));
  // Pre-check agents the user appears to use (their config dir exists under base).
  const preselected = common.detectAgentsAtBase(base);
  return common.multiSelect("Skills will be installed for the agents you pick:", items, {
    preselected,
  });
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
  let staging = false;
  let apiUrlFlag = "";
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
      // Internal API-environment options. They do NOT force non-interactive
      // mode, so they compose with the interactive location/agents prompts.
      case "--staging":
        staging = true;
        break;
      case "--api-url":
        apiUrlFlag = (argv[++i] || "").trim();
        if (!apiUrlFlag) {
          err("--api-url requires a URL value.");
          return 1;
        }
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
    selectedAgents = await promptAgents(expandedBase);
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
  // API environment is fixed at install time: --api-url > --staging > production.
  const apiEnv = common.resolveApiEnvironment({ staging, apiUrl: apiUrlFlag });
  installConfig.writeInstallConfig(layout, expandedBase, agentsForConfig, installTargets, {
    channel: apiEnv.channel,
    apiUrl: apiEnv.apiUrl,
  });
  err(`Wrote install registry ${common.formatDisplayPath(installConfig.installConfigPath())}`);
  err(`API environment: ${apiEnv.channel} (${apiEnv.apiUrl})`);

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
  await verifyOrLogin(interactive);
  return 0;
}

module.exports = { run };
