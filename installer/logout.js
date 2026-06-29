"use strict";

const path = require("path");
const common = require("./common.js");

const SCRIPTS_DIR = path.join(common.BUNDLE_DIR, "_super8-studio-api-shared", "scripts");
const session = require(path.join(SCRIPTS_DIR, "lib", "session.js"));

async function run(argv) {
  if (argv.includes("--help")) {
    process.stdout.write("Usage: logout\n\nRemove the stored login session.\n");
    return 0;
  }
  if (!session.sessionPresent()) {
    process.stdout.write("Not logged in (no session to remove).\n");
    return 0;
  }
  session.clearSession();
  process.stdout.write(
    `Logged out — removed ${common.formatDisplayPath(session.sessionPath())}.\n`
  );
  // The Developer API has no revoke endpoint; the token stays valid server-side
  // until it expires.
  process.stdout.write(
    "Note: the token remains valid on the server until it expires; this only clears it locally.\n"
  );
  return 0;
}

module.exports = { run };
