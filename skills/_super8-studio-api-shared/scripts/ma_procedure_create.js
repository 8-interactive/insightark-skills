#!/usr/bin/env node
"use strict";

const fs = require("fs");
const path = require("path");
const env = require("./lib/env.js");
const { apiRequest, expectSuccess } = require("./lib/http.js");
const { printJson } = require("./lib/output.js");

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
      "JSON body must include orgId plus MA graph fields required by POST /automation.\n"
    );
    process.exit(1);
  }

  env.requireRuntimeEnv();

  const body = fs.readFileSync(jsonFile, "utf8");
  const result = await apiRequest(
    "POST",
    "/developer/v1/automation/procedures",
    body
  );
  expectSuccess(result);
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
