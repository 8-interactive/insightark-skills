"use strict";

// Print an API response body as formatted JSON, falling back to the raw text
// when the body is not valid JSON. Replaces the jq-based s8_print_json_file.
function printJson(text) {
  try {
    process.stdout.write(JSON.stringify(JSON.parse(text), null, 2) + "\n");
  } catch (_err) {
    process.stdout.write(text.endsWith("\n") ? text : text + "\n");
  }
}

// Print a single status/step line to stdout.
function printStep(message) {
  process.stdout.write(String(message) + "\n");
}

module.exports = { printJson, printStep };
