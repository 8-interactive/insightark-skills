"use strict";

const fs = require("fs");
const path = require("path");

// RELEASE is written at CI pack time. Not committed to git. It lives two
// directories up from this lib file (scripts/lib -> scripts -> bundle root).
function releaseFilePath() {
  return path.join(__dirname, "..", "..", "RELEASE");
}

function releasePresent() {
  try {
    return fs.statSync(releaseFilePath()).isFile();
  } catch (_err) {
    return false;
  }
}

function readReleaseValue(key) {
  if (!releasePresent()) return undefined;
  const lines = fs.readFileSync(releaseFilePath(), "utf8").split(/\r?\n/);
  let value;
  const prefix = key + "=";
  for (const line of lines) {
    if (line.startsWith(prefix)) {
      value = line.slice(prefix.length);
    }
  }
  return value;
}

function releaseChannelLabel() {
  const channel = readReleaseValue("channel");
  switch (channel) {
    case "staging":
      return "Staging";
    case "production":
      return "Production";
    default:
      return channel || "";
  }
}

module.exports = {
  releaseFilePath,
  releasePresent,
  readReleaseValue,
  releaseChannelLabel,
};
