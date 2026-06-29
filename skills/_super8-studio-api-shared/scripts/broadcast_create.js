#!/usr/bin/env node
"use strict";

const fs = require("fs");
const env = require("./lib/env.js");
const { apiRequest, expectSuccess } = require("./lib/http.js");
const { printJson } = require("./lib/output.js");

async function main() {
  let orgId = "";
  let platform = "";
  let whereFile = "";
  let scheduleAt = "";
  let inboxToDone = false;
  let messageTag = "";
  let waTemplateId = "";

  const customerIds = [];
  const order = [];

  const argv = process.argv.slice(2);
  for (let i = 0; i < argv.length; i++) {
    switch (argv[i]) {
      case "--org-id":
        orgId = argv[++i] || "";
        break;
      case "--platform":
        platform = argv[++i] || "";
        break;
      case "--customer-id":
        customerIds.push(argv[++i] || "");
        break;
      case "--where-file":
        whereFile = argv[++i] || "";
        break;
      case "--text":
        order.push({ kind: "text", value: argv[++i] || "" });
        break;
      case "--image":
        order.push({ kind: "image", value: argv[++i] || "" });
        break;
      case "--video":
        order.push({ kind: "video", value: argv[++i] || "" });
        break;
      case "--schedule-at":
        scheduleAt = argv[++i] || "";
        break;
      case "--inbox-to-done":
        inboxToDone = true;
        break;
      case "--message-tag":
        messageTag = argv[++i] || "";
        break;
      case "--wa-template-id":
        waTemplateId = argv[++i] || "";
        break;
      default:
        process.stderr.write(`Unknown option: ${argv[i]}\n`);
        process.exit(1);
    }
  }

  if (!platform) {
    process.stderr.write(
      "Provide --platform (one of line, facebook, instagram, whatsapp).\n"
    );
    process.exit(1);
  }

  switch (platform) {
    case "line":
    case "facebook":
    case "instagram":
    case "whatsapp":
      break;
    default:
      process.stderr.write(
        `--platform must be one of line, facebook, instagram, whatsapp (got: ${platform}).\n`
      );
      process.exit(1);
  }

  if (customerIds.length === 0 && !whereFile) {
    process.stderr.write("Provide at least one --customer-id OR --where-file.\n");
    process.exit(1);
  }

  if (customerIds.length > 0 && whereFile) {
    process.stderr.write("--customer-id and --where-file are mutually exclusive.\n");
    process.exit(1);
  }

  if (order.length === 0) {
    process.stderr.write("Provide at least one --text, --image, or --video value.\n");
    process.exit(1);
  }

  env.requireRuntimeEnv();
  orgId = env.resolveOrgId(orgId);

  const messages = [];
  for (const entry of order) {
    switch (entry.kind) {
      case "text":
        messages.push({
          contentType: "text/plain",
          data: { content: entry.value },
        });
        break;
      case "image":
        messages.push({
          contentType: "application/x-image",
          data: { url: entry.value },
        });
        break;
      case "video":
        messages.push({
          contentType: "application/x-video",
          data: { url: entry.value },
        });
        break;
    }
  }

  let recipients;
  if (customerIds.length > 0) {
    recipients = { customerIds: customerIds };
  } else {
    if (!isFile(whereFile)) {
      process.stderr.write(`${whereFile} does not exist.\n`);
      process.exit(1);
    }
    const whereJson = JSON.parse(fs.readFileSync(whereFile, "utf8"));
    recipients = { where: whereJson };
  }

  const body = {
    orgId: orgId,
    platform: platform,
    recipients: recipients,
    messages: messages,
  };

  if (scheduleAt) body.scheduleAt = scheduleAt;
  if (inboxToDone) body.inboxToDone = true;
  if (messageTag) body.messageTag = messageTag;
  if (waTemplateId) body.waTemplateId = waTemplateId;

  const result = await apiRequest("POST", "/developer/v1/broadcasts", body);
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
