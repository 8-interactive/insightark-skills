#!/usr/bin/env node
"use strict";

const fs = require("fs");
const path = require("path");
const env = require("./lib/env.js");
const { apiRequest } = require("./lib/http.js");
const { printJson } = require("./lib/output.js");
const { formatErrorBody } = require("./lib/http.js");

async function main() {
  let jsonFile = "";

  const argv = process.argv.slice(2);
  for (let i = 0; i < argv.length; i++) {
    switch (argv[i]) {
      case "--json-file":
        jsonFile = argv[++i] || "";
        break;
      default:
        process.stderr.write(`Unknown option: ${argv[i]}\n`);
        process.exit(1);
    }
  }

  if (!jsonFile || !isFile(jsonFile)) {
    process.stderr.write(`Usage: ${path.basename(process.argv[1])} --json-file PATH\n`);
    process.stderr.write(
      "Validates POST body against /developer/v1/automation/procedures/validate (HTTP 200 + data.valid).\n"
    );
    process.stderr.write("Exits 0 only when HTTP 2xx and data.valid is true.\n");
    process.exit(1);
  }

  env.requireRuntimeEnv();

  const body = fs.readFileSync(jsonFile, "utf8");
  const result = await apiRequest(
    "POST",
    "/developer/v1/automation/procedures/validate",
    body
  );

  if (!(result.status >= 200 && result.status < 300)) {
    process.stderr.write(
      `Validate request failed with HTTP status ${result.status}\n`
    );
    process.stderr.write(formatErrorBody(result.text) + "\n");
    process.exit(1);
  }

  let valid;
  try {
    const parsed = JSON.parse(result.text);
    valid = parsed && parsed.data ? parsed.data.valid : undefined;
  } catch (_err) {
    valid = undefined;
  }

  if (valid !== true) {
    process.stderr.write("Payload invalid (data.valid is not true)\n");
    process.stderr.write(formatErrorBody(result.text) + "\n");
    process.exit(1);
  }

  printJson(result.text);
}

function isFile(p) {
  try {
    return fs.statSync(p).isFile();
  } catch (_err) {
    return false;
  }
}

main().catch((err) => {
  process.stderr.write(`${err && err.message ? err.message : err}\n`);
  process.exit(1);
});
