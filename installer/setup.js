"use strict";

const fs = require("fs");
const path = require("path");
const { spawnSync } = require("child_process");
const common = require("./common.js");

const SCRIPTS_DIR = path.join(common.BUNDLE_DIR, "_super8-studio-api-shared", "scripts");
const env = require(path.join(SCRIPTS_DIR, "lib", "env.js"));
const installConfig = require(path.join(SCRIPTS_DIR, "lib", "install-config.js"));
const DOCTOR_SCRIPT = path.join(SCRIPTS_DIR, "doctor.js");

function err(message) {
  process.stderr.write(message + "\n");
}

function printUsage() {
  process.stdout.write(
    [
      "Usage: setup [options]",
      "",
      "With no options, runs the interactive credential wizard (default).",
      "",
      "Options:",
      "  --check             Validate existing credentials (doctor)",
      "  --env-hints         Print shell export instructions only",
      "  --repo-only         Write project override file only (advanced)",
      "  --project-path PATH Project root for --repo-only",
      "  --no-open-browser   Do not open Console when creating a token",
      "  --console-url URL   Internal: override the Console base opened to create a token",
      "  --help              Show this help message",
      "",
      "The API URL is fixed at install time and is not configured here.",
      "",
    ].join("\n")
  );
}

function quoteSingle(value) {
  return "'" + String(value).replace(/'/g, "'\\''") + "'";
}

// API URL is fixed at install time and is never written here — only the token
// (and optional org).
function writeEnvFile(targetPath, sessionToken, orgId) {
  const lines = [`S8_SESSION_TOKEN=${quoteSingle(sessionToken)}`];
  if (orgId) lines.push(`S8_ORG_ID=${quoteSingle(orgId)}`);
  fs.writeFileSync(targetPath, lines.join("\n") + "\n", { mode: 0o600 });
  fs.chmodSync(targetPath, 0o600);
}

function writeRepoEnvFile(targetPath, orgId) {
  if (!orgId) {
    err("Nothing to write. Provide S8_ORG_ID for project config.");
    return false;
  }
  fs.writeFileSync(targetPath, `S8_ORG_ID=${quoteSingle(orgId)}\n`, { mode: 0o600 });
  fs.chmodSync(targetPath, 0o600);
  return true;
}

function collectEnvTargets() {
  const targets = [];
  if (installConfig.installConfigPresent()) {
    for (const skillsTarget of installConfig.installSkillsTargets()) {
      targets.push(path.join(skillsTarget.replace(/\/+$/, ""), ".super8-studio.env"));
    }
  }
  if (targets.length === 0) targets.push(env.userEnvPath());
  return targets;
}

// API URL is fixed at install time: read it from the registry, falling back to
// production when no registry exists. Setup never prompts for it.
function resolveApiUrl() {
  const apiUrl = installConfig.installApiUrl() || env.PRODUCTION_API_URL;
  const channel = installConfig.installChannel() || "production";
  err(`API environment: ${channel} (${apiUrl})`);
  err("");
  return apiUrl;
}

// Console base (where setup opens the browser to create a token) is independent
// of the API URL. It is normally derived from the API URL (production /
// staging); a custom endpoint has no Console mapping, so `--console-url` lets an
// internal caller point setup at the right Console (otherwise setup falls back
// to printing manual instructions).
function resolveConsoleUrl(apiUrl, consoleUrlOverride) {
  if (consoleUrlOverride) return consoleUrlOverride;
  return common.consoleBaseForApiUrl(apiUrl);
}

async function promptSessionToken(apiUrl, opts) {
  const consoleBase = resolveConsoleUrl(apiUrl, opts.consoleUrlOverride);
  if (consoleBase && !opts.noOpenBrowser) {
    const tokenUrl = common.buildConsoleTokenUrl(consoleBase);
    err("");
    err("Opening Super 8 Console to create a Developer API token...");
    err(tokenUrl);
    err("");
    common.openUrl(tokenUrl);
    err("Copy the token from the one-time modal, then paste it below.");
  } else {
    err("In Super 8 Console: Account Settings → Developer API → Create token.");
  }
  const token = (await common.promptHidden("Paste S8_SESSION_TOKEN: ")).trim();
  if (!token) {
    err("Session token is required.");
    return promptSessionToken(apiUrl, opts);
  }
  return token;
}

async function fetchEligibleOrgs(apiUrl, token) {
  const root = apiUrl.replace(/\/+$/, "");
  let response;
  try {
    response = await fetch(`${root}/developer/v1/auth/organizations`, {
      method: "GET",
      headers: { Accept: "application/json", _SessionToken: token },
    });
  } catch (e) {
    err(`Failed to list organizations: ${e && e.message ? e.message : e}`);
    return null;
  }
  const text = await response.text();
  if (response.status !== 200) {
    err(`Failed to list organizations (HTTP ${response.status}).`);
    try {
      err(JSON.stringify(JSON.parse(text), null, 2));
    } catch (_e) {
      err(text);
    }
    return null;
  }
  let data = {};
  try {
    data = JSON.parse(text);
  } catch (_e) {
    return [];
  }
  const list = data && data.data && Array.isArray(data.data.organizations) ? data.data.organizations : [];
  return list.filter((o) => o && o.developerApiEnabled === true);
}

async function promptOrgId(apiUrl, token) {
  const orgs = await fetchEligibleOrgs(apiUrl, token);
  if (orgs === null) return null;
  if (orgs.length === 0) {
    err("No organizations with Developer API enabled for this account.");
    err("Enable Developer API in Console organization settings, then retry.");
    return null;
  }
  if (orgs.length === 1) {
    const only = orgs[0];
    const name = only.displayName || only.id;
    err(`Using organization: ${name} (${only.id})`);
    return only.id;
  }
  err("");
  err("Select organization (Developer API enabled):");
  orgs.forEach((o, i) => err(`  ${i + 1}) ${o.displayName || o.id} (${o.id})`));
  const choice = (await common.prompt("Choice: ")).trim();
  if (!/^[0-9]+$/.test(choice) || Number(choice) < 1 || Number(choice) > orgs.length) {
    err("Invalid choice.");
    return null;
  }
  return orgs[Number(choice) - 1].id;
}

function runDoctor() {
  err("");
  process.stdout.write("Running doctor...\n");
  const result = spawnSync(process.execPath, [DOCTOR_SCRIPT], { stdio: "inherit" });
  return result.status === 0;
}

async function run(argv) {
  let mode = "user";
  let checkOnly = false;
  let envHintsOnly = false;
  let noOpenBrowser = false;
  let consoleUrlOverride = "";
  let projectPath = "";

  for (let i = 0; i < argv.length; i++) {
    switch (argv[i]) {
      case "--user-only":
        mode = "user";
        break;
      case "--repo-only":
        mode = "repo";
        break;
      case "--project-path":
        projectPath = argv[++i] || "";
        break;
      case "--check":
        checkOnly = true;
        break;
      case "--env-hints":
        envHintsOnly = true;
        break;
      case "--no-open-browser":
        noOpenBrowser = true;
        break;
      case "--console-url":
        consoleUrlOverride = (argv[++i] || "").trim();
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

  if (envHintsOnly) {
    env.printProcessEnvInstructions();
    return 0;
  }

  if (checkOnly) {
    return runDoctor() ? 0 : 1;
  }

  if (mode === "user") {
    err("Super 8 Studio API — credential setup");
    err("");
    err("Connect your Super 8 account so skills can call the API.");
    if (!installConfig.installConfigPresent()) {
      err("Tip: run install first if you have not installed skills yet.");
    }
    err("");

    const targets = collectEnvTargets();
    const existing = targets.find((t) => fs.existsSync(t));
    if (existing) {
      err(`Credential file already exists: ${common.formatDisplayPath(existing)}`);
      const answer = (await common.prompt("Overwrite? [y/N]: ")).trim();
      if (!["y", "Y", "yes", "YES"].includes(answer)) {
        err("Aborted.");
        return 0;
      }
    }

    const apiUrl = resolveApiUrl();
    const sessionToken = await promptSessionToken(apiUrl, { noOpenBrowser, consoleUrlOverride });
    let orgId = await promptOrgId(apiUrl, sessionToken);
    if (!orgId) {
      err("Warning: could not select organization. The token will be saved without S8_ORG_ID.");
      err("Set S8_ORG_ID later or re-run setup.");
      orgId = "";
    }
    err("");
    for (const target of targets) {
      common.ensureDirectory(path.dirname(target));
      writeEnvFile(target, sessionToken, orgId);
      process.stdout.write(`Wrote ${common.formatDisplayPath(target)} (mode 600)\n`);
    }
  } else if (mode === "repo") {
    if (!projectPath) {
      projectPath = (await common.prompt("Project path for .super8-studio.env: ")).trim();
    }
    const base = common.expandBaseDir(projectPath);
    const target = path.join(base, ".super8-studio.env");
    if (fs.existsSync(target)) {
      err(`File already exists: ${target}`);
      const answer = (await common.prompt("Overwrite? [y/N]: ")).trim();
      if (!["y", "Y", "yes", "YES"].includes(answer)) {
        err("Aborted.");
        return 0;
      }
    }
    err("Project config sets a per-project org. (API URL is fixed at install time.)");
    const orgId = (await common.prompt("S8_ORG_ID: ")).trim();
    common.ensureDirectory(base);
    if (!writeRepoEnvFile(target, orgId)) return 1;
    process.stdout.write(
      `Wrote ${common.formatDisplayPath(target)} (mode 600). Add this file to .gitignore.\n`
    );
  }

  return runDoctor() ? 0 : 1;
}

module.exports = { run };
