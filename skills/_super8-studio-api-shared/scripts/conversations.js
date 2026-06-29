#!/usr/bin/env node
"use strict";

const env = require("./lib/env.js");
const { apiRequest, expectSuccess } = require("./lib/http.js");
const { printJson } = require("./lib/output.js");

async function main() {
  let orgId = "";
  let customerId = "";
  let platform = "";
  let startAt = "";
  let endAt = "";
  let timeField = "";
  let cursor = "";
  let limit = "";
  let inbox = "";

  const argv = process.argv.slice(2);
  for (let i = 0; i < argv.length; i++) {
    switch (argv[i]) {
      case "--org-id":
        orgId = argv[++i] || "";
        break;
      case "--customer-id":
        customerId = argv[++i] || "";
        break;
      case "--platform":
        platform = argv[++i] || "";
        break;
      case "--inbox":
        inbox = argv[++i] || "";
        break;
      case "--start-at":
        startAt = argv[++i] || "";
        break;
      case "--end-at":
        endAt = argv[++i] || "";
        break;
      case "--time-field":
        timeField = argv[++i] || "";
        break;
      case "--cursor":
        cursor = argv[++i] || "";
        break;
      case "--limit":
        limit = argv[++i] || "";
        break;
      default:
        process.stderr.write(`Unknown option: ${argv[i]}\n`);
        process.exit(1);
    }
  }

  env.requireRuntimeEnv();
  orgId = env.resolveOrgId(orgId);

  const query = env.buildQuery([
    ["orgId", orgId],
    ["customerId", customerId],
    ["platform", platform],
    ["inbox", inbox],
    ["startAt", startAt],
    ["endAt", endAt],
    ["timeField", timeField],
    ["cursor", cursor],
    ["limit", limit],
  ]);

  const result = await apiRequest(
    "GET",
    `/developer/v1/conversations${query}`
  );
  expectSuccess(result);
  printJson(result.text);
}

main().catch((err) => {
  process.stderr.write(`${err && err.message ? err.message : err}\n`);
  process.exit(1);
});
