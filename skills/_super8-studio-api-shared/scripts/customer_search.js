#!/usr/bin/env node
"use strict";

const env = require("./lib/env.js");
const { apiRequest, expectSuccess } = require("./lib/http.js");
const { printJson } = require("./lib/output.js");

async function main() {
  let orgId = "";
  const customerIds = [];
  let displayName = "";
  let originalDisplayName = "";
  let email = "";
  let cellPhone = "";
  const platforms = [];
  const includeTags = [];
  const excludeTags = [];
  let joinedStartAt = "";
  let joinedEndAt = "";
  let lastInboundStartAt = "";
  let lastInboundEndAt = "";
  let lastMessageStartAt = "";
  let lastMessageEndAt = "";
  let limit = "";
  let skip = "";

  const argv = process.argv.slice(2);
  for (let i = 0; i < argv.length; i++) {
    switch (argv[i]) {
      case "--org-id":
        orgId = argv[++i] || "";
        break;
      case "--customer-id":
        customerIds.push(argv[++i] || "");
        break;
      case "--display-name":
        displayName = argv[++i] || "";
        break;
      case "--original-display-name":
        originalDisplayName = argv[++i] || "";
        break;
      case "--email":
        email = argv[++i] || "";
        break;
      case "--cell-phone":
        cellPhone = argv[++i] || "";
        break;
      case "--platform":
        platforms.push(argv[++i] || "");
        break;
      case "--include-tag":
        includeTags.push(argv[++i] || "");
        break;
      case "--exclude-tag":
        excludeTags.push(argv[++i] || "");
        break;
      case "--joined-start-at":
        joinedStartAt = argv[++i] || "";
        break;
      case "--joined-end-at":
        joinedEndAt = argv[++i] || "";
        break;
      case "--last-inbound-start-at":
        lastInboundStartAt = argv[++i] || "";
        break;
      case "--last-inbound-end-at":
        lastInboundEndAt = argv[++i] || "";
        break;
      case "--last-message-start-at":
        lastMessageStartAt = argv[++i] || "";
        break;
      case "--last-message-end-at":
        lastMessageEndAt = argv[++i] || "";
        break;
      case "--limit":
        limit = argv[++i] || "";
        break;
      case "--skip":
        skip = argv[++i] || "";
        break;
      default:
        process.stderr.write(`Unknown option: ${argv[i]}\n`);
        process.exit(1);
    }
  }

  env.requireRuntimeEnv();
  orgId = env.resolveOrgId(orgId);

  const body = { orgId };
  if (customerIds.length > 0) body.customerIds = customerIds;
  if (displayName !== "") body.displayName = displayName;
  if (originalDisplayName !== "") body.originalDisplayName = originalDisplayName;
  if (email !== "") body.email = email;
  if (cellPhone !== "") body.cellPhone = cellPhone;
  if (platforms.length > 0) body.platforms = platforms;
  if (includeTags.length > 0) body.includeTags = includeTags;
  if (excludeTags.length > 0) body.excludeTags = excludeTags;
  if (joinedStartAt !== "" || joinedEndAt !== "") {
    const joinedAt = {};
    if (joinedStartAt !== "") joinedAt.startAt = joinedStartAt;
    if (joinedEndAt !== "") joinedAt.endAt = joinedEndAt;
    body.joinedAt = joinedAt;
  }
  if (lastInboundStartAt !== "" || lastInboundEndAt !== "") {
    const lastInboundAt = {};
    if (lastInboundStartAt !== "") lastInboundAt.startAt = lastInboundStartAt;
    if (lastInboundEndAt !== "") lastInboundAt.endAt = lastInboundEndAt;
    body.lastInboundAt = lastInboundAt;
  }
  if (lastMessageStartAt !== "" || lastMessageEndAt !== "") {
    const lastMessageAt = {};
    if (lastMessageStartAt !== "") lastMessageAt.startAt = lastMessageStartAt;
    if (lastMessageEndAt !== "") lastMessageAt.endAt = lastMessageEndAt;
    body.lastMessageAt = lastMessageAt;
  }
  if (limit !== "") body.limit = Number(limit);
  if (skip !== "") body.skip = Number(skip);

  const result = await apiRequest("POST", "/developer/v1/customers/search", body);
  expectSuccess(result);
  printJson(result.text);
}

main().catch((err) => {
  process.stderr.write(`${err && err.message ? err.message : err}\n`);
  process.exit(1);
});
