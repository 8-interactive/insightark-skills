"use strict";

const fs = require("fs");
const os = require("os");
const path = require("path");
const readline = require("readline");
const { spawn } = require("child_process");

const ROOT = path.join(__dirname, "..");
const BUNDLE_DIR = path.join(ROOT, "skills");

// Supported coding agents and their per-agent skills subpaths.
const AGENTS = [
  { id: "claude-code", label: "Claude Code", subpath: ".claude/skills" },
  { id: "opencode", label: "OpenCode", subpath: ".opencode/skills" },
  { id: "cursor", label: "Cursor", subpath: ".cursor/skills" },
  { id: "github-copilot", label: "GitHub Copilot", subpath: ".copilot/skills" },
  { id: "codex", label: "Codex", subpath: ".codex/skills" },
];

function agentById(id) {
  return AGENTS.find((a) => a.id === id);
}

function agentLabel(id) {
  const a = agentById(id);
  return a ? a.label : id;
}

function agentSubpath(id) {
  const a = agentById(id);
  if (!a) throw new Error(`Unsupported agent: ${id}`);
  return a.subpath;
}

function isSupportedAgent(id) {
  return Boolean(agentById(id));
}

// Expand a leading "~" to the home directory and strip trailing slashes.
function expandBaseDir(input) {
  if (!input) throw new Error("Base directory is required.");
  const home = os.homedir() || "";
  let expanded;
  if (input === "~") {
    expanded = home;
  } else if (input.startsWith("~/")) {
    expanded = home + input.slice(1);
  } else {
    expanded = input;
  }
  if (!expanded) {
    throw new Error(`Could not resolve home directory for path: ${input}`);
  }
  return expanded.replace(/\/+$/, "");
}

function resolveInstallTarget(baseDir, agentId) {
  return path.join(baseDir, agentSubpath(agentId));
}

function formatDisplayPath(p) {
  if (!p) return "";
  const home = os.homedir() || "";
  if (home && p === home) return "~";
  if (home && p.startsWith(home + path.sep)) {
    return "~" + path.sep + p.slice(home.length + 1);
  }
  return p;
}

// Parse a comma-separated agents value (or "all"); returns an array of ids.
function parseAgents(csv) {
  if (!csv) throw new Error("At least one agent is required.");
  if (csv === "all") return AGENTS.map((a) => a.id);
  const out = [];
  for (const raw of csv.split(",")) {
    const item = raw.replace(/\s+/g, "");
    if (!item) continue;
    if (!isSupportedAgent(item)) throw new Error(`Unsupported agent: ${item}`);
    out.push(item);
  }
  return out;
}

function listBundleDirs(bundleDir) {
  let entries;
  try {
    entries = fs.readdirSync(bundleDir, { withFileTypes: true });
  } catch (_err) {
    return [];
  }
  return entries
    .filter((e) => e.isDirectory())
    .map((e) => e.name)
    .filter((n) => n.startsWith("super8-studio-") || n.startsWith("_super8-studio-"))
    .sort();
}

function countBundleSkills(bundleDir) {
  return listBundleDirs(bundleDir).filter((n) => n.startsWith("super8-studio-")).length;
}

function ensureDirectory(dir) {
  fs.mkdirSync(dir, { recursive: true });
}

function removeBundleDirs(targetDir) {
  for (const name of listBundleDirs(targetDir)) {
    fs.rmSync(path.join(targetDir, name), { recursive: true, force: true });
  }
}

function copyBundle(bundleDir, targetDir) {
  ensureDirectory(targetDir);
  for (const name of listBundleDirs(bundleDir)) {
    const dest = path.join(targetDir, name);
    fs.rmSync(dest, { recursive: true, force: true });
    fs.cpSync(path.join(bundleDir, name), dest, { recursive: true });
  }
}

// ---- interactive prompts (readline, zero-dependency) ----

// A persistent line reader. All "line" events are queued so that piped,
// multi-line input is never dropped between asynchronous prompts (the classic
// readline pitfall). On a TTY this behaves like a normal line prompt.
let sharedRl = null;
let lineQueue = [];
let lineWaiters = [];
let rlClosed = false;

function startRl() {
  if (sharedRl) return;
  rlClosed = false;
  sharedRl = readline.createInterface({ input: process.stdin, output: process.stderr });
  sharedRl.on("line", (line) => {
    const waiter = lineWaiters.shift();
    if (waiter) waiter(line);
    else lineQueue.push(line);
  });
  sharedRl.on("close", () => {
    rlClosed = true;
    while (lineWaiters.length) lineWaiters.shift()("");
  });
}

function closeRl() {
  if (sharedRl) {
    sharedRl.close();
    sharedRl = null;
  }
  lineQueue = [];
  lineWaiters = [];
  rlClosed = false;
}

function prompt(question) {
  startRl();
  process.stderr.write(question);
  if (lineQueue.length) return Promise.resolve(lineQueue.shift());
  if (rlClosed) return Promise.resolve("");
  return new Promise((resolve) => lineWaiters.push(resolve));
}

// Prompt without echoing input (for secrets). Falls back to a plain prompt
// when stdin is not a TTY.
const CTRL_C = 3;
const CTRL_D = 4;
const BACKSPACE = 8;
const DELETE = 127;

function promptHidden(question) {
  if (!process.stdin.isTTY) return prompt(question);
  // Raw-mode read needs exclusive control of stdin; release the shared
  // readline first. The next prompt() lazily recreates it.
  closeRl();
  return new Promise((resolve) => {
    process.stderr.write(question);
    const stdin = process.stdin;
    let buffer = "";
    const finish = (value) => {
      stdin.setRawMode(false);
      stdin.pause();
      stdin.removeListener("data", onData);
      process.stderr.write("\n");
      resolve(value);
    };
    const onData = (char) => {
      const code = char.charCodeAt(0);
      if (char === "\n" || char === "\r" || code === CTRL_D) {
        finish(buffer);
      } else if (code === CTRL_C) {
        stdin.setRawMode(false);
        process.stderr.write("\n");
        process.exit(1);
      } else if (code === BACKSPACE || code === DELETE) {
        buffer = buffer.slice(0, -1);
      } else {
        buffer += char;
      }
    };
    stdin.setRawMode(true);
    stdin.resume();
    stdin.setEncoding("utf8");
    stdin.on("data", onData);
  });
}

function openUrl(url) {
  let cmd;
  let args;
  if (process.platform === "darwin") {
    cmd = "open";
    args = [url];
  } else if (process.platform === "win32") {
    cmd = "cmd";
    args = ["/c", "start", "", url];
  } else {
    cmd = "xdg-open";
    args = [url];
  }
  try {
    const child = spawn(cmd, args, { stdio: "ignore", detached: true });
    child.on("error", () => {});
    child.unref();
  } catch (_err) {
    process.stderr.write(`Open this URL in your browser:\n${url}\n`);
  }
}

function consoleBaseForApiUrl(apiUrl) {
  const trimmed = (apiUrl || "").replace(/\/+$/, "");
  switch (trimmed) {
    case "https://api-next.no8.io":
      return "https://console.no8.io";
    case "https://stage-api-next.no8.io":
      return "https://stage-console.no8.io";
    default:
      return "";
  }
}

function buildConsoleTokenUrl(consoleBase, label) {
  const base = (consoleBase || "").replace(/\/+$/, "");
  const l = label || "super8-studio-skills";
  return `${base}/account-setting/user-info?setup=developer-api-skills&action=create-token&label=${l}`;
}

module.exports = {
  ROOT,
  BUNDLE_DIR,
  AGENTS,
  agentById,
  agentLabel,
  agentSubpath,
  isSupportedAgent,
  expandBaseDir,
  resolveInstallTarget,
  formatDisplayPath,
  parseAgents,
  listBundleDirs,
  countBundleSkills,
  ensureDirectory,
  removeBundleDirs,
  copyBundle,
  prompt,
  promptHidden,
  closeRl,
  openUrl,
  consoleBaseForApiUrl,
  buildConsoleTokenUrl,
};
