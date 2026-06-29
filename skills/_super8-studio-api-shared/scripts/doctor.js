#!/usr/bin/env node
"use strict";

// Health check: verifies credentials work against the Developer API and
// reports bundle/account context. Mirrors doctor.sh, including --soft-fail.

const fs = require("fs");
const path = require("path");
const env = require("./lib/env.js");
const { apiRequest, formatErrorBody } = require("./lib/http.js");

async function main() {
  let softFail = false;
  const argv = process.argv.slice(2);
  for (let i = 0; i < argv.length; i++) {
    switch (argv[i]) {
      case "--soft-fail":
        softFail = true;
        break;
      default:
        process.stderr.write(`Unknown option: ${argv[i]}\n`);
        process.exit(1);
    }
  }

  function fail(message) {
    process.stderr.write(message + "\n");
    if (softFail) {
      process.stdout.write("Doctor status: failed (soft)\n");
      process.exit(0);
    }
    process.exit(1);
  }

  function isSuccess(result) {
    return result.status >= 200 && result.status < 300;
  }

  function reportFailureBody(result) {
    const body = formatErrorBody(result.text);
    if (body) process.stderr.write(body + "\n");
  }

  if (!env.loadRuntimeEnv()) fail("Runtime environment is not ready");

  const me = await apiRequest("GET", "/developer/v1/auth/me");
  if (!isSuccess(me)) {
    reportFailureBody(me);
    fail("Current session is not usable");
  }

  let meData = {};
  try {
    meData = JSON.parse(me.text);
  } catch (_err) {
    meData = {};
  }

  const versionFile = path.join(__dirname, "..", "VERSION");
  let installedVersion = "unknown";
  try {
    installedVersion = fs.readFileSync(versionFile, "utf8").trim() || "unknown";
  } catch (_err) {
    installedVersion = "unknown";
  }
  const latestSkillVersion =
    meData && meData.data && meData.data.latestSkillVersion
      ? meData.data.latestSkillVersion
      : "";

  process.stdout.write(`API URL: ${process.env.S8_API_ROOT}\n`);
  process.stdout.write("Session token: present\n");
  const userEmail =
    meData && meData.data && meData.data.user && meData.data.user.email
      ? meData.data.user.email
      : "unknown";
  process.stdout.write(`User: ${userEmail}\n`);
  process.stdout.write(`Installed skill bundle version: ${installedVersion}\n`);
  if (latestSkillVersion) {
    process.stdout.write(`Latest skill bundle version: ${latestSkillVersion}\n`);
    if (installedVersion !== latestSkillVersion && installedVersion !== "unknown") {
      process.stderr.write(
        "Warning: skill bundle is outdated. Re-run install to update.\n"
      );
    }
  }

  const orgs = await apiRequest("GET", "/developer/v1/auth/organizations");
  if (isSuccess(orgs)) {
    let orgsData = {};
    try {
      orgsData = JSON.parse(orgs.text);
    } catch (_err) {
      orgsData = {};
    }
    const list =
      orgsData && orgsData.data && Array.isArray(orgsData.data.organizations)
        ? orgsData.data.organizations
        : [];
    const enabled = list.filter((o) => o && o.developerApiEnabled === true);
    process.stdout.write(`Organizations in account: ${list.length}\n`);
    process.stdout.write(`Developer API enabled: ${enabled.length}\n`);
  } else {
    reportFailureBody(orgs);
    fail("Failed to reach auth/organizations endpoint");
  }

  if (process.env.S8_ORG_ID) {
    process.stdout.write(`Default org: ${process.env.S8_ORG_ID}\n`);
  } else {
    process.stdout.write("Default org: not set\n");
  }

  process.stdout.write("Doctor status: ok\n");
}

main().catch((err) => {
  process.stderr.write(`${err && err.message ? err.message : err}\n`);
  process.exit(1);
});
