#!/usr/bin/env node
"use strict";

const env = require("./lib/env.js");
const { apiRequest, expectSuccess } = require("./lib/http.js");
const { printJson } = require("./lib/output.js");

async function main() {
  let orgId = "";
  let customerId = "";
  const tags = [];

  const argv = process.argv.slice(2);
  for (let i = 0; i < argv.length; i++) {
    switch (argv[i]) {
      case "--org-id":
        orgId = argv[++i] || "";
        break;
      case "--customer-id":
        customerId = argv[++i] || "";
        break;
      case "--tag":
        tags.push(argv[++i] || "");
        break;
      default:
        process.stderr.write(`Unknown option: ${argv[i]}\n`);
        process.exit(1);
    }
  }

  if (!customerId) {
    process.stderr.write("Missing required option: --customer-id\n");
    process.exit(1);
  }

  if (tags.length === 0) {
    process.stderr.write("Provide at least one --tag value.\n");
    process.exit(1);
  }

  env.requireRuntimeEnv();
  orgId = env.resolveOrgId(orgId);

  const body = { orgId, tags };

  const result = await apiRequest(
    "POST",
    `/developer/v1/customers/${customerId}/tags`,
    body
  );
  expectSuccess(result);
  printJson(result.text);
}

main().catch((err) => {
  process.stderr.write(`${err && err.message ? err.message : err}\n`);
  process.exit(1);
});
