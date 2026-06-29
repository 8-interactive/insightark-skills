#!/usr/bin/env node
"use strict";

// Local gate before validate/create. Pure local checks (no API call):
// required keys, schedule timezone, placeholder scan, Meta fbTag, and
// confirmation parity against matchTopLevel. Mirrors the original jq filter.

const fs = require("fs");
const path = require("path");
const { printStep } = require("./lib/output.js");

const SCRIPT_NAME = path.basename(process.argv[1] || "ma_procedure_preflight.js");

function fail(message) {
  process.stderr.write(message + "\n");
  process.stderr.write("Preflight failed (see error above).\n");
  process.exit(1);
}

const OPENAPI_REQUIRED_ROOT = [
  "orgId",
  "templateType",
  "name",
  "enabled",
  "platform",
  "startTime",
  "endTime",
  "limits",
  "oos",
  "nodes",
  "edges",
];

function isPlainObject(v) {
  return v !== null && typeof v === "object" && !Array.isArray(v);
}

function isInteger(v) {
  return typeof v === "number" && Number.isFinite(v) && Math.floor(v) === v;
}

function iso8601WithTz(s) {
  return typeof s === "string" && (/Z$/.test(s) || /[+-][0-9]{2}:[0-9]{2}$/.test(s));
}

function metaNeedFbTag(p) {
  const platform = typeof p.platform === "string" ? p.platform.toLowerCase() : "";
  return platform === "facebook" || platform === "instagram" || platform === "messenger";
}

function perCustomerAllowed(pc) {
  if (typeof pc === "number") return pc >= 0 && isInteger(pc);
  return pc === "onceByDay";
}

function oosSleepWindowOk(oos) {
  return (
    isPlainObject(oos) &&
    isInteger(oos.hour) &&
    oos.hour >= 0 &&
    oos.hour <= 23 &&
    isInteger(oos.minute) &&
    oos.minute >= 0 &&
    oos.minute <= 59 &&
    isInteger(oos.duration) &&
    oos.duration > 0
  );
}

function expectedMatchKeys(p) {
  const base = [
    "enabled",
    "endTime",
    "limits",
    "name",
    "oos",
    "orgId",
    "platform",
    "startTime",
    "templateType",
  ];
  if (metaNeedFbTag(p) || Object.prototype.hasOwnProperty.call(p, "fbTag")) {
    base.push("fbTag");
  }
  return Array.from(new Set(base)).sort();
}

function deepEqual(a, b) {
  if (a === b) return true;
  if (typeof a !== typeof b) return false;
  if (Array.isArray(a) || Array.isArray(b)) {
    if (!Array.isArray(a) || !Array.isArray(b) || a.length !== b.length) return false;
    return a.every((x, i) => deepEqual(x, b[i]));
  }
  if (isPlainObject(a) && isPlainObject(b)) {
    const ka = Object.keys(a).sort();
    const kb = Object.keys(b).sort();
    if (ka.length !== kb.length || !ka.every((k, i) => k === kb[i])) return false;
    return ka.every((k) => deepEqual(a[k], b[k]));
  }
  return false;
}

const PLACEHOLDER_SUBSTRINGS = ["<REQUIRED_FROM_CUSTOMER", "YOUR_ORG_ID", "CHANGE_ME"];

function stringHasPlaceholder(s) {
  for (const needle of PLACEHOLDER_SUBSTRINGS) {
    if (s.includes(needle)) return true;
  }
  return /\bTODO\b/i.test(s) || /\bFIXME\b/i.test(s);
}

function hasForbiddenPlaceholder(node) {
  if (typeof node === "string") return stringHasPlaceholder(node);
  if (Array.isArray(node)) return node.some(hasForbiddenPlaceholder);
  if (isPlainObject(node)) return Object.values(node).some(hasForbiddenPlaceholder);
  return false;
}

function arraysEqual(a, b) {
  return a.length === b.length && a.every((x, i) => x === b[i]);
}

function main() {
  let jsonFile = "";
  let confirmationFile = "";

  const argv = process.argv.slice(2);
  for (let i = 0; i < argv.length; i++) {
    switch (argv[i]) {
      case "--json-file":
        jsonFile = argv[++i] || "";
        break;
      case "--confirmation-file":
        confirmationFile = argv[++i] || "";
        break;
      default:
        process.stderr.write(`Unknown option: ${argv[i]}\n`);
        process.exit(1);
    }
  }

  const jsonFileExists = jsonFile && fs.existsSync(jsonFile) && fs.statSync(jsonFile).isFile();
  if (!jsonFileExists) {
    process.stderr.write(`Usage: ${SCRIPT_NAME} --json-file PATH --confirmation-file PATH\n`);
    process.stderr.write(
      "Local gate before validate/create: required keys, schedule TZ, placeholder scan, Meta fbTag, confirmation parity.\n"
    );
    process.exit(1);
  }

  const confFileExists =
    confirmationFile && fs.existsSync(confirmationFile) && fs.statSync(confirmationFile).isFile();
  if (!confFileExists) {
    process.stderr.write(`${SCRIPT_NAME}: --confirmation-file is required.\n`);
    process.exit(1);
  }

  let p;
  try {
    p = JSON.parse(fs.readFileSync(jsonFile, "utf8"));
  } catch (_err) {
    process.stderr.write("Invalid JSON in --json-file\n");
    process.exit(1);
  }

  let c;
  try {
    c = JSON.parse(fs.readFileSync(confirmationFile, "utf8"));
  } catch (_err) {
    process.stderr.write("Invalid JSON in --confirmation-file\n");
    process.exit(1);
  }

  if (!isPlainObject(p)) fail("payload root must be object");
  if (!isPlainObject(c)) fail("confirmation root must be object");
  if (c.customerExplicitApproval !== true) fail("customerExplicitApproval must be true");
  if (c.nodesEdgesCustomerApproved !== true) fail("nodesEdgesCustomerApproved must be true");
  if (!isPlainObject(c.matchTopLevel)) fail("matchTopLevel must be object");

  if (OPENAPI_REQUIRED_ROOT.some((k) => !Object.prototype.hasOwnProperty.call(p, k))) {
    fail("missing one of openapi_required_root fields");
  }

  if (typeof p.enabled !== "boolean") fail("enabled must be boolean");
  if (!isPlainObject(p.limits)) fail("limits must be object");
  if (!Object.prototype.hasOwnProperty.call(p.limits, "message")) {
    fail("limits.message is required (non-negative integer)");
  }
  if (typeof p.limits.message !== "number" || p.limits.message < 0 || !isInteger(p.limits.message)) {
    fail("limits.message must be non-negative integer");
  }
  if (!Object.prototype.hasOwnProperty.call(p.limits, "per_customer")) {
    fail("limits.per_customer is required (non-negative integer or onceByDay)");
  }
  if (!perCustomerAllowed(p.limits.per_customer)) {
    fail("limits.per_customer must be non-negative integer or literal string onceByDay");
  }
  if (!Array.isArray(p.nodes) || p.nodes.length === 0) fail("nodes must be non-empty array");
  if (!Array.isArray(p.edges) || p.edges.length === 0) fail("edges must be non-empty array");

  if (p.startTime === null || p.endTime === null || p.startTime === undefined || p.endTime === undefined) {
    fail("startTime and endTime are required (journey schedule window)");
  }
  if (!iso8601WithTz(p.startTime)) fail("startTime must be timezone-aware ISO 8601 (Z or +/-HH:MM)");
  if (!iso8601WithTz(p.endTime)) fail("endTime must be timezone-aware ISO 8601 (Z or +/-HH:MM)");

  if (p.oos !== null && p.oos !== undefined && isPlainObject(p.oos) && p.oos.enabled === true && !oosSleepWindowOk(p.oos)) {
    fail(
      "when oos.enabled is true, oos.hour (0–23), oos.minute (0–59), and oos.duration (positive integer seconds) are required"
    );
  }

  if (
    metaNeedFbTag(p) &&
    (!Object.prototype.hasOwnProperty.call(p, "fbTag") ||
      typeof p.fbTag !== "string" ||
      p.fbTag.length === 0)
  ) {
    fail("fbTag must be a non-empty string for facebook/instagram/messenger");
  }

  const matchKeys = Object.keys(c.matchTopLevel).sort();
  if (!arraysEqual(matchKeys, expectedMatchKeys(p))) {
    fail(
      "matchTopLevel keys must exactly equal approved top-level keys for this payload (always includes enabled, endTime, limits, name, oos, orgId, platform, startTime, templateType; plus fbTag when Meta platform or body carries fbTag)"
    );
  }

  for (const mk of matchKeys) {
    if (!deepEqual(p[mk], c.matchTopLevel[mk])) {
      fail("payload differs from matchTopLevel for at least one confirmed field");
    }
  }

  if (hasForbiddenPlaceholder(p)) {
    fail("payload contains forbidden placeholder-like string");
  }

  printStep("Preflight OK (local checks passed).");
}

main();
