"use strict";

// Format an API error body for stderr: pretty JSON when possible, else raw.
function formatErrorBody(text) {
  if (!text) return "";
  try {
    return JSON.stringify(JSON.parse(text), null, 2);
  } catch (_err) {
    return text;
  }
}

// Perform a Developer API request using fetch. Returns { status, text }.
// Mirrors s8_api_request: sends the _SessionToken header and JSON body.
async function apiRequest(method, requestPath, body) {
  const url = process.env.S8_API_ROOT + requestPath;
  const headers = {
    Accept: "application/json",
    _SessionToken: process.env.S8_SESSION_TOKEN || "",
  };
  const options = { method, headers };
  if (body !== undefined && body !== null && body !== "") {
    headers["Content-Type"] = "application/json";
    options.body = typeof body === "string" ? body : JSON.stringify(body);
  }

  let response;
  try {
    response = await fetch(url, options);
  } catch (err) {
    process.stderr.write(
      `API request failed: ${err && err.message ? err.message : err}\n`
    );
    process.exit(1);
  }
  const text = await response.text();
  return { status: response.status, text };
}

// Mirrors s8_expect_success. On non-2xx, prints an actionable message and the
// response body to stderr, then exits non-zero. Returns normally on success.
function expectSuccess(result) {
  const { status, text } = result;
  if (status >= 200 && status < 300) return;

  if (status === 401) {
    process.stderr.write("Developer API session is invalid or expired.\n");
    process.stderr.write(
      "Create a new token in Super 8 Console: Account Settings → Developer API.\n"
    );
    process.stderr.write("Do not commit tokens to version control.\n");
  } else if (status === 429) {
    process.stderr.write("Developer API rate limit exceeded.\n");
  } else {
    process.stderr.write(`API request failed with status ${status}\n`);
  }
  const formatted = formatErrorBody(text);
  if (formatted) process.stderr.write(formatted + "\n");
  process.exit(1);
}

module.exports = { apiRequest, expectSuccess, formatErrorBody };
