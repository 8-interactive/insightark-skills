#!/usr/bin/env node
"use strict";

const env = require("./lib/env.js");
const { apiRequest, expectSuccess } = require("./lib/http.js");
const { printJson } = require("./lib/output.js");

async function main() {
  let orgId = "";
  let procedureId = "";
  let customerId = "";
  let triggerType = "api";

  const argv = process.argv.slice(2);
  for (let i = 0; i < argv.length; i++) {
    switch (argv[i]) {
      case "--org-id":
        orgId = argv[++i] || "";
        break;
      case "--procedure-id":
        procedureId = argv[++i] || "";
        break;
      case "--customer-id":
        customerId = argv[++i] || "";
        break;
      case "--type":
        triggerType = argv[++i] || "";
        break;
      default:
        process.stderr.write(`Unknown option: ${argv[i]}\n`);
        process.exit(1);
    }
  }

  env.requireRuntimeEnv();
  orgId = env.resolveOrgId(orgId);

  if (!procedureId || !customerId) {
    process.stderr.write("--procedure-id and --customer-id are required.\n");
    process.exit(1);
  }

  const body = {
    orgId: orgId,
    customerId: customerId,
    type: triggerType,
  };

  const result = await apiRequest(
    "POST",
    `/developer/v1/automation/procedures/${procedureId}/trigger`,
    body
  );
  expectSuccess(result);
  printJson(result.text);
}

main().catch((err) => {
  process.stderr.write(`${err && err.message ? err.message : err}\n`);
  process.exit(1);
});
