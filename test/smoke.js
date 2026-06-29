#!/usr/bin/env node
"use strict";

// Cross-platform smoke test for install / uninstall / runtime invocation.
// Pure Node, no network required (a live doctor check runs only when
// S8_API_URL + S8_SESSION_TOKEN are present). Safe to run locally: the
// install registry (~/.super8-studio.config) is backed up and restored.

const fs = require("fs");
const os = require("os");
const path = require("path");
const { spawnSync } = require("child_process");

const REPO = path.join(__dirname, "..");
const CLI = path.join(REPO, "scripts", "super8-skills-cli.js");
const SCRIPTS = path.join(REPO, "skills", "_super8-studio-api-shared", "scripts");

let failures = 0;
function check(name, cond, detail) {
  if (cond) {
    console.log(`PASS: ${name}`);
  } else {
    console.log(`FAIL: ${name}${detail ? "\n  " + detail : ""}`);
    failures++;
  }
}

function cli(args, opts) {
  return spawnSync(process.execPath, [CLI, ...args], { encoding: "utf8", ...opts });
}

function hasNodeModules(dir) {
  const stack = [dir];
  while (stack.length) {
    const cur = stack.pop();
    let entries;
    try {
      entries = fs.readdirSync(cur, { withFileTypes: true });
    } catch (_e) {
      continue;
    }
    for (const e of entries) {
      if (e.isDirectory()) {
        if (e.name === "node_modules") return true;
        stack.push(path.join(cur, e.name));
      }
    }
  }
  return false;
}

const cfgPath = path.join(os.homedir(), ".super8-studio.config");
const cfgBackup = fs.existsSync(cfgPath) ? fs.readFileSync(cfgPath) : null;
const work = fs.mkdtempSync(path.join(os.tmpdir(), "s8-smoke-"));

try {
  // 1. Direct install via --target.
  const target = path.join(work, "direct");
  let r = cli(["install", "--target", target]);
  check("install --target exits 0", r.status === 0, r.stderr);
  const shared = path.join(target, "_super8-studio-api-shared");
  check("shared bundle copied", fs.existsSync(shared));
  const dirs = fs.existsSync(target) ? fs.readdirSync(target) : [];
  check("skill dirs copied", dirs.some((d) => d.startsWith("super8-studio-")));
  check("no node_modules in installed bundle", !hasNodeModules(target));

  // 2. Per-agent install resolves each agent subpath.
  const base = path.join(work, "per");
  r = cli(["install", "--base-dir", base, "--agents", "claude-code,cursor"]);
  check("per-agent install exits 0", r.status === 0, r.stderr);
  check(
    "claude-code target created",
    fs.existsSync(path.join(base, ".claude", "skills", "_super8-studio-api-shared"))
  );
  check(
    "cursor target created",
    fs.existsSync(path.join(base, ".cursor", "skills", "_super8-studio-api-shared"))
  );

  // 3. Registry written in the expected key=value format.
  check("install registry written", fs.existsSync(cfgPath));
  if (fs.existsSync(cfgPath)) {
    const reg = fs.readFileSync(cfgPath, "utf8");
    check("registry has skills_targets", /\nskills_targets=/.test(reg), reg);
    check("registry has layout", /\nlayout=/.test(reg));
    check("registry records production channel by default", /\nchannel=production\n/.test(reg), reg);
    check("registry records api_url", /\napi_url=https:\/\/api-next\.no8\.io\n/.test(reg), reg);
  }

  // 3b. --staging records the staging endpoint.
  const stagingTarget = path.join(work, "staging");
  r = cli(["install", "--target", stagingTarget, "--staging"]);
  check("install --staging exits 0", r.status === 0, r.stderr);
  const stagingReg = fs.existsSync(cfgPath) ? fs.readFileSync(cfgPath, "utf8") : "";
  check("staging registry channel", /\nchannel=staging\n/.test(stagingReg), stagingReg);
  check(
    "staging registry api_url",
    /\napi_url=https:\/\/stage-api-next\.no8\.io\n/.test(stagingReg),
    stagingReg
  );
  cli(["uninstall", "--target", stagingTarget]);

  // 4. A skill runs via `node <path>` and handles a missing required arg
  //    deterministically (no credentials needed).
  r = spawnSync(process.execPath, [path.join(SCRIPTS, "customer_detail.js")], {
    encoding: "utf8",
  });
  check("skill missing-arg exits non-zero", r.status !== 0);
  check(
    "skill prints missing-arg message",
    /Missing required option: --customer-id/.test(r.stderr),
    r.stderr
  );

  // 5. Uninstall removes the bundle.
  r = cli(["uninstall", "--target", target]);
  check("uninstall --target exits 0", r.status === 0, r.stderr);
  check("bundle removed", !fs.existsSync(shared));

  // 5b. Interactive install via piped stdin exercises the non-TTY agent
  //     selection fallback (typed list). cwd is a temp dir so "repo" location
  //     installs there, not into this repo. Answers: 2=repo, 3=cursor, Y=confirm.
  const itmp = path.join(work, "interactive");
  fs.mkdirSync(itmp, { recursive: true });
  r = spawnSync(process.execPath, [CLI, "install"], {
    cwd: itmp,
    input: "2\n3\nY\n",
    encoding: "utf8",
  });
  check("interactive install exits 0", r.status === 0, r.stderr);
  check(
    "non-TTY agent fallback selected cursor",
    fs.existsSync(path.join(itmp, ".cursor", "skills", "_super8-studio-api-shared")),
    r.stderr
  );
  cli(["uninstall", "--target", path.join(itmp, ".cursor", "skills")]);

  // 6. Live doctor only when credentials are available (e.g. CI secret).
  //    The API URL is fixed at install time, so point the registry at the
  //    token's environment via the hidden --api-url before running doctor.
  if (process.env.S8_API_URL && process.env.S8_SESSION_TOKEN) {
    const liveTarget = path.join(work, "live");
    cli(["install", "--target", liveTarget, "--api-url", process.env.S8_API_URL]);
    r = cli(["doctor"]);
    const out = (r.stdout || "") + (r.stderr || "");
    // Server uptime is not under test: a 5xx / network error means the API is
    // down, so skip (don't fail). Only a real auth rejection (401) fails.
    const serverDown = /50\d|Service (Temporarily )?Unavailable|ECONN|ENOTFOUND|ETIMEDOUT|fetch failed/i.test(out);
    if (r.status === 0 && /Doctor status: ok/.test(r.stdout)) {
      check("live doctor reports ok", true);
      check("doctor prints API root", /API URL: /.test(r.stdout), r.stdout);
    } else if (serverDown) {
      console.log("SKIP: live doctor (API unreachable / 5xx — server uptime not under test)");
    } else {
      check("live doctor reports ok", false, out);
    }
  } else {
    console.log("SKIP: live doctor (S8_API_URL / S8_SESSION_TOKEN not set)");
  }
} finally {
  fs.rmSync(work, { recursive: true, force: true });
  if (cfgBackup !== null) {
    fs.writeFileSync(cfgPath, cfgBackup);
  } else if (fs.existsSync(cfgPath)) {
    fs.rmSync(cfgPath, { force: true });
  }
}

if (failures > 0) {
  console.error(`\n${failures} smoke failure(s).`);
  process.exit(1);
}
console.log("\nAll smoke checks passed.");
