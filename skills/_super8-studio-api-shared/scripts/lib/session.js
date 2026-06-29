"use strict";

// Login session store. Written by `login`, cleared by `logout`, and read by the
// runtime (env.js) as the highest-priority credential. Lives in the shared lib
// because both the runtime (shipped) and the installer read/write it.

const fs = require("fs");
const os = require("os");
const path = require("path");

const SESSION_FILENAME = ".super8-studio.session";

function sessionPath() {
  return path.join(os.homedir() || "", SESSION_FILENAME);
}

function readSession() {
  try {
    return JSON.parse(fs.readFileSync(sessionPath(), "utf8"));
  } catch (_err) {
    return null;
  }
}

// Persist a login session: { token, expiresAt, email, orgId, apiUrl }.
function writeSession(session) {
  fs.writeFileSync(sessionPath(), JSON.stringify(session, null, 2) + "\n", { mode: 0o600 });
  fs.chmodSync(sessionPath(), 0o600);
}

function clearSession() {
  try {
    fs.rmSync(sessionPath(), { force: true });
    return true;
  } catch (_err) {
    return false;
  }
}

function sessionPresent() {
  try {
    return fs.statSync(sessionPath()).isFile();
  } catch (_err) {
    return false;
  }
}

function isExpired(session) {
  if (!session || !session.expiresAt) return false; // no expiry info → treat as live
  const t = Date.parse(session.expiresAt);
  if (Number.isNaN(t)) return false;
  return t <= Date.now();
}

// A session is usable only when it has a token, is not expired, and was issued
// against the API root currently in effect (so a production token is not sent
// to staging after the channel changes).
function isSessionValid(session, apiRoot) {
  if (!session || !session.token) return false;
  if (isExpired(session)) return false;
  if (apiRoot) {
    const sessionRoot = (session.apiUrl || "").replace(/\/+$/, "");
    if (sessionRoot !== apiRoot.replace(/\/+$/, "")) return false;
  }
  return true;
}

module.exports = {
  SESSION_FILENAME,
  sessionPath,
  readSession,
  writeSession,
  clearSession,
  sessionPresent,
  isExpired,
  isSessionValid,
};
