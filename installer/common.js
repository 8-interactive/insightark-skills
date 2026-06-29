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

// ---- agent detection (for multi-select pre-checking) ----

function dirExists(p) {
  try {
    return fs.statSync(p).isDirectory();
  } catch (_err) {
    return false;
  }
}

// Install context: agents the user appears to use — their config dir (the
// parent of the skills subpath, e.g. ".claude") exists under `base`.
function detectAgentsAtBase(base) {
  return AGENTS.filter((a) => dirExists(path.join(base, path.dirname(a.subpath)))).map(
    (a) => a.id
  );
}

// Uninstall context: agents that actually have the bundle installed under `base`.
function detectAgentsWithBundle(base) {
  return AGENTS.filter((a) =>
    dirExists(path.join(base, a.subpath, "_super8-studio-api-shared"))
  ).map((a) => a.id);
}

// ---- multi-select picker (checkbox on a TTY, typed list otherwise) ----

const ARROW_UP = "\x1b[A";
const ARROW_DOWN = "\x1b[B";

// Typed fallback used when stdin is not a TTY (CI, pipes, smoke). Prints the
// numbered list once, then reads a comma-separated answer (numbers / ids /
// "all"), rejecting unknown agents and requiring at least one.
async function multiSelectTyped(title, items, output) {
  const w = (s) => output && output.write && output.write(s);
  w(title + "\n");
  items.forEach((it, i) => w(`  ${i + 1}) ${it.label} (${it.id})\n`));
  const ask = async () => {
    const choice = (await prompt('Selection [e.g. 1,3,5 or "all"]: ')).trim();
    if (!choice) {
      w("At least one agent is required.\n");
      return ask();
    }
    if (choice === "all") return items.map((it) => it.id);
    const out = [];
    for (const raw of choice.split(",")) {
      const item = raw.replace(/\s+/g, "");
      if (!item) continue;
      if (/^[0-9]+$/.test(item)) {
        const idx = Number(item);
        if (idx < 1 || idx > items.length) {
          w(`Invalid selection: ${item}\n`);
          return ask();
        }
        out.push(items[idx - 1].id);
      } else if (items.some((it) => it.id === item)) {
        out.push(item);
      } else {
        w(`Invalid selection: ${item}\n`);
        return ask();
      }
    }
    if (out.length === 0) {
      w("At least one agent is required.\n");
      return ask();
    }
    return Array.from(new Set(out));
  };
  return ask();
}

// Interactive checkbox picker. Returns the selected ids (>=1).
function multiSelectInteractive(title, items, input, output, preselected) {
  closeRl(); // raw mode needs exclusive stdin; release the shared line reader
  const checked = new Set(preselected);
  let cursor = 0;
  let rendered = 0;
  const hint = "↑/↓ (j/k) move · space toggle · a all · enter confirm";
  const w = (s) => output && output.write && output.write(s);

  function render(status) {
    if (rendered > 0) w(`\x1b[${rendered}A`);
    const lines = [title, hint];
    items.forEach((it, i) => {
      const cur = i === cursor ? "❯" : " ";
      const box = checked.has(it.id) ? "[x]" : "[ ]";
      lines.push(`${cur} ${box} ${it.label} (${it.id})`);
    });
    lines.push(status || `selected: ${[...checked].join(", ") || "(none)"}`);
    w(lines.map((l) => `\x1b[2K${l}`).join("\n") + "\n");
    rendered = lines.length;
  }

  return new Promise((resolve) => {
    if (input.setRawMode) input.setRawMode(true);
    if (input.resume) input.resume();
    if (input.setEncoding) input.setEncoding("utf8");
    w("\x1b[?25l"); // hide cursor
    render();

    const cleanup = () => {
      input.removeListener("data", onData);
      if (input.setRawMode) input.setRawMode(false);
      if (input.pause) input.pause();
      w("\x1b[?25h"); // restore cursor
    };

    const onData = (data) => {
      const key = data.toString();
      if (key === ARROW_UP || key === "k") {
        cursor = (cursor - 1 + items.length) % items.length;
        render();
      } else if (key === ARROW_DOWN || key === "j") {
        cursor = (cursor + 1) % items.length;
        render();
      } else if (key === " ") {
        const id = items[cursor].id;
        if (checked.has(id)) checked.delete(id);
        else checked.add(id);
        render();
      } else if (key === "a") {
        if (checked.size === items.length) checked.clear();
        else items.forEach((it) => checked.add(it.id));
        render();
      } else if (key === "\r" || key === "\n") {
        if (checked.size === 0) {
          render("At least one agent is required.");
          return;
        }
        cleanup();
        resolve(items.filter((it) => checked.has(it.id)).map((it) => it.id));
      } else if (key === "\x03") {
        // Ctrl-C
        cleanup();
        w("\n");
        process.exit(1);
      }
    };

    input.on("data", onData);
  });
}

// title: header line; items: [{id,label}]; opts: { input, output, isTTY, preselected }
function multiSelect(title, items, opts = {}) {
  const input = opts.input || process.stdin;
  const output = opts.output || process.stderr;
  const isTTY = opts.isTTY !== undefined ? opts.isTTY : Boolean(input.isTTY);
  const preselected =
    opts.preselected instanceof Set ? opts.preselected : new Set(opts.preselected || []);
  if (!isTTY) return multiSelectTyped(title, items, output);
  return multiSelectInteractive(title, items, input, output, preselected);
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

// API environments. Production is the default; staging is internal-only.
const PRODUCTION_API_URL = "https://api-next.no8.io";
const STAGING_API_URL = "https://stage-api-next.no8.io";

// Resolve the install-time API environment from the (internal) flags.
// Precedence: explicit --api-url > --staging > production default.
function resolveApiEnvironment({ staging, apiUrl } = {}) {
  if (apiUrl) return { channel: "custom", apiUrl };
  if (staging) return { channel: "staging", apiUrl: STAGING_API_URL };
  return { channel: "production", apiUrl: PRODUCTION_API_URL };
}

// Verify a token against /developer/v1/auth/me. Non-throwing: returns
// { ok, status, email, error } so callers can branch on 401 vs network errors.
async function verifyToken(apiRoot, token) {
  let res;
  try {
    res = await fetch(`${apiRoot.replace(/\/+$/, "")}/developer/v1/auth/me`, {
      method: "GET",
      headers: { Accept: "application/json", _SessionToken: token },
    });
  } catch (e) {
    return { ok: false, status: 0, error: e && e.message ? e.message : String(e) };
  }
  let email;
  try {
    const data = await res.json();
    email = data && data.data && data.data.user && data.data.user.email;
  } catch (_e) {
    // ignore body parse errors
  }
  return { ok: res.status >= 200 && res.status < 300, status: res.status, email };
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
  multiSelect,
  detectAgentsAtBase,
  detectAgentsWithBundle,
  verifyToken,
  closeRl,
  openUrl,
  PRODUCTION_API_URL,
  STAGING_API_URL,
  resolveApiEnvironment,
  consoleBaseForApiUrl,
  buildConsoleTokenUrl,
};
