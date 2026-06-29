#!/usr/bin/env node
"use strict";

const env = require("./lib/env.js");
const { apiRequest, expectSuccess } = require("./lib/http.js");
const { printJson } = require("./lib/output.js");

async function main() {
  let orgId = "";
  let customerId = "";
  let replyToken = "";
  let inboxToDone = false;
  let messageTag = "";
  let waTemplateId = "";

  const order = [];

  const argv = process.argv.slice(2);
  for (let i = 0; i < argv.length; i++) {
    switch (argv[i]) {
      case "--org-id":
        orgId = argv[++i] || "";
        break;
      case "--customer-id":
        customerId = argv[++i] || "";
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
      case "--reply-token":
        replyToken = argv[++i] || "";
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

  if (!customerId) {
    process.stderr.write("Missing required option: --customer-id\n");
    process.exit(1);
  }

  if (order.length === 0) {
    process.stderr.write(
      "Provide at least one --text, --image, or --video value.\n"
    );
    process.exit(1);
  }

  env.requireRuntimeEnv();
  orgId = env.resolveOrgId(orgId);

  const messages = [];
  for (const entry of order) {
    let message;
    if (entry.kind === "text") {
      message = { contentType: "text/plain", data: { content: entry.value } };
    } else if (entry.kind === "image") {
      message = { contentType: "application/x-image", data: { url: entry.value } };
    } else {
      message = { contentType: "application/x-video", data: { url: entry.value } };
    }

    if (messageTag) {
      message.messageTag = messageTag;
    }
    if (waTemplateId) {
      message.waTemplateId = waTemplateId;
    }

    messages.push(message);
  }

  const body = { orgId, messages };
  if (replyToken) {
    body.replyToken = replyToken;
  }
  if (inboxToDone) {
    body.inboxToDone = true;
  }

  const result = await apiRequest(
    "POST",
    `/developer/v1/customers/${customerId}/messages`,
    body
  );
  expectSuccess(result);
  printJson(result.text);
}

main().catch((err) => {
  process.stderr.write(`${err && err.message ? err.message : err}\n`);
  process.exit(1);
});
