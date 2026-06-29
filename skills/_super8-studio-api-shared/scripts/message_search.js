#!/usr/bin/env node
"use strict";

const env = require("./lib/env.js");
const { apiRequest, expectSuccess } = require("./lib/http.js");
const { printJson } = require("./lib/output.js");

async function main() {
  let orgId = "";
  let conversationId = "";
  let platform = "";
  let startAt = "";
  let endAt = "";
  let limit = "";
  let skip = "";
  const keywords = [];
  const senderTypes = [];
  const senderIds = [];

  const argv = process.argv.slice(2);
  for (let i = 0; i < argv.length; i++) {
    switch (argv[i]) {
      case "--org-id":
        orgId = argv[++i] || "";
        break;
      case "--conversation-id":
        conversationId = argv[++i] || "";
        break;
      case "--platform":
        platform = argv[++i] || "";
        break;
      case "--start-at":
        startAt = argv[++i] || "";
        break;
      case "--end-at":
        endAt = argv[++i] || "";
        break;
      case "--limit":
        limit = argv[++i] || "";
        break;
      case "--skip":
        skip = argv[++i] || "";
        break;
      case "--keyword":
        keywords.push(argv[++i] || "");
        break;
      case "--sender-type":
        senderTypes.push(argv[++i] || "");
        break;
      case "--sender-id":
        senderIds.push(argv[++i] || "");
        break;
      default:
        process.stderr.write(`Unknown option: ${argv[i]}\n`);
        process.exit(1);
    }
  }

  env.requireRuntimeEnv();
  orgId = env.resolveOrgId(orgId);

  if (keywords.length === 0) {
    process.stderr.write("Missing required option: at least one --keyword\n");
    process.exit(1);
  }

  let keyword = null;
  if (keywords.length === 1) {
    keyword = keywords[0];
  } else if (keywords.length > 1) {
    keyword = keywords.slice();
  }

  let senderType = null;
  if (senderTypes.length === 1) {
    senderType = senderTypes[0];
  } else if (senderTypes.length > 1) {
    senderType = senderTypes.slice();
  }

  let senderIdsValue = null;
  if (senderIds.length === 1) {
    senderIdsValue = [senderIds[0]];
  } else if (senderIds.length > 1) {
    senderIdsValue = senderIds.slice();
  }

  const body = { orgId };
  if (conversationId !== "") {
    body.conversationId = conversationId;
  }
  if (platform !== "") {
    body.platform = platform;
  }
  if (keyword !== null) {
    body.keyword = keyword;
  }
  if (startAt !== "") {
    body.startAt = startAt;
  }
  if (endAt !== "") {
    body.endAt = endAt;
  }
  if (senderType !== null) {
    body.senderType = senderType;
  }
  if (senderIdsValue !== null) {
    body.senderIds = senderIdsValue;
  }
  if (limit !== "") {
    body.limit = Number(limit);
  }
  if (skip !== "") {
    body.skip = Number(skip);
  }

  const result = await apiRequest("POST", "/developer/v1/messages/search", body);
  expectSuccess(result);
  printJson(result.text);
}

main().catch((err) => {
  process.stderr.write(`${err && err.message ? err.message : err}\n`);
  process.exit(1);
});
