#!/usr/bin/env node
"use strict";

const env = require("./lib/env.js");
const { apiRequest, expectSuccess } = require("./lib/http.js");
const { printJson } = require("./lib/output.js");

async function main() {
  let orgId = "";
  let nameFilter = "";
  let skipVal = "";
  let limitVal = "";

  const argv = process.argv.slice(2);
  for (let i = 0; i < argv.length; i++) {
    switch (argv[i]) {
      case "--org-id":
        orgId = argv[++i] || "";
        break;
      case "--name":
        nameFilter = argv[++i] || "";
        break;
      case "--skip":
        skipVal = argv[++i] || "";
        break;
      case "--limit":
        limitVal = argv[++i] || "";
        break;
      default:
        process.stderr.write(`Unknown option: ${argv[i]}\n`);
        process.exit(1);
    }
  }

  env.requireRuntimeEnv();
  orgId = env.resolveOrgId(orgId);

  if (!limitVal) limitVal = "20";

  const query = env.buildQuery([
    ["orgId", orgId],
    ["name", nameFilter],
    ["skip", skipVal],
    ["limit", limitVal],
  ]);
  const result = await apiRequest(
    "GET",
    `/developer/v1/automation/procedures${query}`
  );
  expectSuccess(result);
  printJson(result.text);
}

main().catch((err) => {
  process.stderr.write(`${err && err.message ? err.message : err}\n`);
  process.exit(1);
});
