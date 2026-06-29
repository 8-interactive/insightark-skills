"use strict";

const fs = require("fs");
const os = require("os");
const path = require("path");
const installConfig = require("./install-config.js");
const sessionLib = require("./session.js");

const ENV_FILENAME = ".super8-studio.env";

// The validated login session in effect for this run (set by token resolution).
let activeSession = null;

// API URL is fixed at install time. Production is the built-in fallback used
// when no install registry records an api_url (e.g. plugin installs).
const PRODUCTION_API_URL = "https://api-next.no8.io";

function userEnvPath() {
  return path.join(os.homedir() || "", ENV_FILENAME);
}

// Resolve the fixed API root: install-registry api_url first, else production.
// Never reads S8_API_URL from the environment or env files.
function resolveApiRoot() {
  const fromRegistry = installConfig.installApiUrl();
  const url = (fromRegistry || PRODUCTION_API_URL).replace(/\/+$/, "");
  return { root: url, source: fromRegistry ? "registry" : "production-fallback" };
}

// Repo override file is resolved relative to the current working directory,
// matching the bash "./.super8-studio.env" behavior.
function repoEnvPath() {
  return path.join(process.cwd(), ENV_FILENAME);
}

// Display form for the repo env file, matching the bash "./.super8-studio.env".
function repoEnvDisplayPath() {
  return "./" + ENV_FILENAME;
}

// Strip surrounding single/double quotes and undo basic shell-style escaping.
// Handles the format written by this tool ('value' with '\'' escapes) and
// plain unquoted values written by older installs.
function unquoteValue(raw) {
  let value = raw;
  if (value.length >= 2 && value[0] === "'" && value[value.length - 1] === "'") {
    value = value.slice(1, -1).replace(/'\\''/g, "'");
    return value;
  }
  if (value.length >= 2 && value[0] === '"' && value[value.length - 1] === '"') {
    value = value.slice(1, -1).replace(/\\(["\\$`])/g, "$1");
    return value;
  }
  return value;
}

function parseEnvFile(filePath) {
  const result = {};
  const content = fs.readFileSync(filePath, "utf8");
  for (const rawLine of content.split(/\r?\n/)) {
    const line = rawLine.trim();
    if (!line || line.startsWith("#")) continue;
    let body = line;
    if (body.startsWith("export ")) body = body.slice("export ".length);
    const eq = body.indexOf("=");
    if (eq === -1) continue;
    const key = body.slice(0, eq).trim();
    if (!key) continue;
    result[key] = unquoteValue(body.slice(eq + 1));
  }
  return result;
}

// Apply a single env file onto process.env (overriding existing values, as
// `set -a; . file` would). Returns true when the file was present and read.
function applyEnvFileIfPresent(filePath) {
  try {
    if (!fs.statSync(filePath).isFile()) return false;
  } catch (_err) {
    return false;
  }
  const vars = parseEnvFile(filePath);
  for (const [key, value] of Object.entries(vars)) {
    process.env[key] = value;
  }
  return true;
}

// Replicates s8_load_env_files precedence (highest first):
//   process env / CLAUDE_PLUGIN_OPTION_* -> repo file -> skills-dir file -> user file
// Files are applied user -> skills -> repo so later overrides earlier, then the
// preserved process-environment values are restored on top.
function loadEnvFiles() {
  // Only the session token and org id are credentials. The API URL is fixed at
  // install time (see resolveApiRoot) and is NOT read from the environment,
  // env files, or plugin options.
  for (const key of ["S8_SESSION_TOKEN", "S8_ORG_ID"]) {
    const pluginKey = `CLAUDE_PLUGIN_OPTION_${key}`;
    if (!process.env[key] && process.env[pluginKey]) {
      process.env[key] = process.env[pluginKey];
    }
  }

  const saved = {};
  for (const key of ["S8_SESSION_TOKEN", "S8_ORG_ID"]) {
    if (process.env[key]) saved[key] = process.env[key];
  }

  const state = { user: false, skills: false, repo: false };

  if (applyEnvFileIfPresent(userEnvPath())) state.user = true;

  if (installConfig.installConfigPresent()) {
    for (const target of installConfig.installSkillsTargets()) {
      const skillsEnvPath = path.join(target.replace(/\/+$/, ""), ENV_FILENAME);
      if (applyEnvFileIfPresent(skillsEnvPath)) state.skills = true;
    }
  }

  if (applyEnvFileIfPresent(repoEnvPath())) state.repo = true;

  for (const [key, value] of Object.entries(saved)) {
    process.env[key] = value;
  }

  return state;
}

function printProcessEnvInstructions() {
  const shellName = path.basename(process.env.SHELL || "sh");
  const home = os.homedir() || "";
  let rcFile;
  switch (shellName) {
    case "zsh":
      rcFile = path.join(home, ".zshrc");
      break;
    case "bash":
      rcFile = fs.existsSync(path.join(home, ".bashrc"))
        ? path.join(home, ".bashrc")
        : path.join(home, ".bash_profile");
      break;
    case "fish":
      rcFile = path.join(home, ".config", "fish", "config.fish");
      break;
    default:
      rcFile = path.join(home, ".profile");
  }

  const lines = [
    "Alternative: process environment (highest priority — overrides config files)",
    `Detected shell: ${shellName} (from $SHELL)`,
    `Suggested profile file: ${rcFile}`,
    "",
  ];
  if (shellName === "fish") {
    lines.push(
      `Add to ${rcFile}:`,
      "  set -gx S8_SESSION_TOKEN 'r:your-token'",
      "  set -gx S8_ORG_ID 'your-org-id'  # optional",
      "",
      `Then run: source ${rcFile}`
    );
  } else {
    lines.push(
      `Add to ${rcFile}:`,
      "  export S8_SESSION_TOKEN='r:your-token'",
      "  export S8_ORG_ID='your-org-id'  # optional",
      "",
      `Then run: source ${rcFile}`,
      "Or for the current terminal session only:",
      "  export S8_SESSION_TOKEN='r:your-token'"
    );
  }
  lines.push(
    "",
    "Note: some agent sandboxes do not inherit shell exports. Prefer ~/.super8-studio.env for agents."
  );
  process.stderr.write(lines.join("\n") + "\n");
}

function printMissingCredentialsHelp(state) {
  const userPath = userEnvPath();
  const repoPath = repoEnvDisplayPath();
  const out = [];
  out.push("Missing SUPER 8 Studio session token.\n");
  out.push(
    `Token priority (highest first): CLAUDE_PLUGIN_OPTION_S8_SESSION_TOKEN / process environment > ${repoPath} > skills install dir > ${userPath}\n`
  );
  out.push(
    "(API URL is fixed at install time and is not configured here.)\n"
  );
  out.push("Checked:");
  if (state.skills) {
    out.push(
      `  - {skills-target}/${ENV_FILENAME} from ${installConfig.installConfigPath()} (loaded)`
    );
  } else if (installConfig.installConfigPresent()) {
    out.push(
      `  - {skills-target}/${ENV_FILENAME} from ${installConfig.installConfigPath()} (not found)`
    );
  }
  out.push(`  - ${userPath} (${state.user ? "loaded" : "not found"})`);
  out.push(`  - ${repoPath} (${state.repo ? "loaded" : "not found"})`);
  out.push(
    `  - process environment (S8_SESSION_TOKEN ${
      process.env.S8_SESSION_TOKEN ? "set" : "not set"
    })`
  );
  out.push("");
  out.push("Authenticate: insightark-skills login");
  out.push(`Or create ${userPath} with S8_SESSION_TOKEN — see .super8-studio.env.example`);
  out.push("");
  process.stderr.write(out.join("\n") + "\n");
  printProcessEnvInstructions();
}

// Load env files and verify required credentials. Returns true on success;
// on failure prints actionable help and returns false (callers exit non-zero).
// A valid login session is the highest-priority credential — it overrides the
// token from the environment/files. An expired session or one issued against a
// different API root is ignored (with a notice) and resolution falls through.
function applySessionOverride(apiRoot) {
  const session = sessionLib.readSession();
  if (session && sessionLib.isSessionValid(session, apiRoot)) {
    process.env.S8_SESSION_TOKEN = session.token;
    activeSession = session;
  } else {
    activeSession = null;
    if (session && sessionLib.sessionPresent()) {
      process.stderr.write(
        "Login session is expired or was issued for another API environment — run `login` again.\n"
      );
    }
  }
}

// Resolve the token without printing help or exiting (for callers like install
// that want to probe). Returns the token string or null.
function resolveToken() {
  loadEnvFiles();
  applySessionOverride(resolveApiRoot().root);
  return process.env.S8_SESSION_TOKEN || null;
}

function loadRuntimeEnv() {
  const state = loadEnvFiles();
  const apiRoot = resolveApiRoot().root;
  applySessionOverride(apiRoot);
  if (!process.env.S8_SESSION_TOKEN) {
    printMissingCredentialsHelp(state);
    return false;
  }
  // API URL is fixed (registry or production fallback), not a credential.
  process.env.S8_API_ROOT = apiRoot;
  return true;
}

// Convenience for command scripts: load env or exit(1).
function requireRuntimeEnv() {
  if (!loadRuntimeEnv()) {
    process.exit(1);
  }
}

function resolveOrgId(explicitOrgId) {
  if (explicitOrgId) return explicitOrgId;
  if (activeSession && activeSession.orgId) return activeSession.orgId;
  if (process.env.S8_ORG_ID) return process.env.S8_ORG_ID;
  process.stderr.write(
    `Missing organization context. Provide --org-id, run \`login\` to set a default org, or set S8_ORG_ID in ${repoEnvDisplayPath()} or ${userEnvPath()}.\n`
  );
  process.exit(1);
}

// Build a query string ("?a=b&c=d") from [key, value] pairs, skipping empty
// values. Values are URL-encoded.
function buildQuery(pairs) {
  const parts = [];
  for (const [key, value] of pairs) {
    if (value === undefined || value === null || value === "") continue;
    parts.push(`${key}=${encodeURIComponent(value)}`);
  }
  return parts.length ? "?" + parts.join("&") : "";
}

function isoNow() {
  return new Date().toISOString().replace(/\.\d{3}Z$/, "Z");
}

function isoDaysAgo(days) {
  const n = Number(days) || 0;
  const d = new Date(Date.now() - n * 24 * 60 * 60 * 1000);
  return d.toISOString().replace(/\.\d{3}Z$/, "Z");
}

module.exports = {
  ENV_FILENAME,
  PRODUCTION_API_URL,
  userEnvPath,
  repoEnvPath,
  parseEnvFile,
  resolveApiRoot,
  resolveToken,
  loadEnvFiles,
  loadRuntimeEnv,
  requireRuntimeEnv,
  resolveOrgId,
  buildQuery,
  isoNow,
  isoDaysAgo,
  printProcessEnvInstructions,
  printMissingCredentialsHelp,
};
