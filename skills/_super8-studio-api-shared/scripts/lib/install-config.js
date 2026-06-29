"use strict";

const fs = require("fs");
const os = require("os");
const path = require("path");

const INSTALL_CONFIG_FILENAME = ".super8-studio.config";
const ENV_FILENAME = ".super8-studio.env";

function installConfigPath() {
  return path.join(os.homedir() || "", INSTALL_CONFIG_FILENAME);
}

function installConfigPresent() {
  try {
    return fs.statSync(installConfigPath()).isFile();
  } catch (_err) {
    return false;
  }
}

// Read the last value for `key` from the key=value registry file.
function readInstallConfigValue(key) {
  const configPath = installConfigPath();
  if (!installConfigPresent()) return undefined;
  const lines = fs.readFileSync(configPath, "utf8").split(/\r?\n/);
  let value;
  const prefix = key + "=";
  for (const line of lines) {
    if (line.startsWith(prefix)) {
      value = line.slice(prefix.length);
    }
  }
  return value;
}

// Resolve the recorded skills install target directories (may be empty).
function installSkillsTargets() {
  const csv = readInstallConfigValue("skills_targets");
  if (!csv) return [];
  return csv
    .split(",")
    .map((t) => t.replace(/\s+/g, ""))
    .filter((t) => t.length > 0);
}

// Write the install registry (key=value lines, mode 600). Format preserved
// byte-for-byte with the previous bash implementation.
function writeInstallConfig(layout, baseDir, agentsCsv, targets) {
  if (!targets || targets.length === 0) {
    throw new Error("No install targets to record in config.");
  }
  const targetsLine = targets.filter((t) => t && t.length > 0).join(",");
  const installedAt = new Date().toISOString().replace(/\.\d{3}Z$/, "Z");
  const body =
    "# Super 8 Studio install registry (managed by the installer)\n" +
    `layout=${layout}\n` +
    `base_dir=${baseDir || ""}\n` +
    `agents=${agentsCsv || ""}\n` +
    `skills_targets=${targetsLine}\n` +
    `installed_at=${installedAt}\n`;
  fs.writeFileSync(installConfigPath(), body, { mode: 0o600 });
  fs.chmodSync(installConfigPath(), 0o600);
}

function removeInstallConfig() {
  const configPath = installConfigPath();
  if (installConfigPresent()) {
    fs.rmSync(configPath, { force: true });
  }
}

module.exports = {
  INSTALL_CONFIG_FILENAME,
  ENV_FILENAME,
  installConfigPath,
  installConfigPresent,
  readInstallConfigValue,
  installSkillsTargets,
  writeInstallConfig,
  removeInstallConfig,
};
