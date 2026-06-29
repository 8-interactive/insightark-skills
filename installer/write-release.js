#!/usr/bin/env node
"use strict";

// Writes the RELEASE file at CI pack time based on the build branch.
// CI-only tool; not part of the user install flow.

const fs = require("fs");
const path = require("path");

const releaseFile = path.join(
  __dirname,
  "..",
  "skills",
  "_super8-studio-api-shared",
  "RELEASE"
);
const branch = process.env.DRONE_BRANCH || "";

let lines;
switch (branch) {
  case "staging":
    lines = [
      "channel=staging",
      "api_url=https://stage-api-next.no8.io",
      "console_url=https://stage-console.no8.io",
      "built_from_branch=staging",
    ];
    break;
  case "main":
    lines = [
      "channel=production",
      "api_url=https://api-next.no8.io",
      "console_url=https://console.no8.io",
      "built_from_branch=main",
    ];
    break;
  default:
    process.stderr.write(`Unsupported branch for skills release: ${branch}\n`);
    process.exit(1);
}

fs.writeFileSync(releaseFile, lines.join("\n") + "\n");
process.stderr.write(`Wrote ${releaseFile} for branch ${branch}\n`);
