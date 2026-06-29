#!/usr/bin/env node
"use strict";

// Unit tests for common.multiSelect's interactive (TTY) checkbox logic, driven
// by an injected fake keypress stream — no real terminal needed. The non-TTY
// typed fallback is covered separately by the smoke test (real piped stdin).

const assert = require("assert");
const { EventEmitter } = require("events");
const common = require("../installer/common.js");

const UP = "\x1b[A";
const DOWN = "\x1b[B";
const SPACE = " ";
const ENTER = "\r";

const ITEMS = [
  { id: "a", label: "Agent A" },
  { id: "b", label: "Agent B" },
  { id: "c", label: "Agent C" },
];

// Fake stdin: an EventEmitter with the stream methods multiSelect calls.
function makeInput() {
  const e = new EventEmitter();
  e.setRawMode = () => {};
  e.resume = () => {};
  e.pause = () => {};
  e.setEncoding = () => {};
  return e;
}
const sink = { write: () => {} };

// Run multiSelect with isTTY and feed the given keys after the listener attaches.
async function drive(keys, preselected) {
  const input = makeInput();
  const p = common.multiSelect("pick", ITEMS, {
    input,
    output: sink,
    isTTY: true,
    preselected,
  });
  for (const k of keys) input.emit("data", k);
  return p;
}

let failures = 0;
async function check(name, fn) {
  try {
    await fn();
    process.stdout.write(`PASS: ${name}\n`);
  } catch (err) {
    failures++;
    process.stdout.write(`FAIL: ${name}\n  ${err.message}\n`);
  }
}

(async () => {
  await check("down then space selects the second item", async () => {
    const result = await drive([DOWN, SPACE, ENTER]);
    assert.deepStrictEqual(result, ["b"]);
  });

  await check("j/k navigation works like arrows", async () => {
    const result = await drive(["j", "j", SPACE, ENTER]); // cursor → c
    assert.deepStrictEqual(result, ["c"]);
  });

  await check("up from top wraps to the last item", async () => {
    const result = await drive([UP, SPACE, ENTER]); // cursor 0 → wraps to c
    assert.deepStrictEqual(result, ["c"]);
  });

  await check("space toggles multiple; order follows items", async () => {
    const result = await drive([SPACE, DOWN, DOWN, SPACE, ENTER]); // a and c
    assert.deepStrictEqual(result, ["a", "c"]);
  });

  await check("'a' selects all", async () => {
    const result = await drive(["a", ENTER]);
    assert.deepStrictEqual(result, ["a", "b", "c"]);
  });

  await check("preselected items start checked", async () => {
    const result = await drive([ENTER], ["b"]);
    assert.deepStrictEqual(result, ["b"]);
  });

  await check("enter with none selected does not resolve until one is picked", async () => {
    // First ENTER must be ignored (zero selected); then pick A and confirm.
    const result = await drive([ENTER, SPACE, ENTER]);
    assert.deepStrictEqual(result, ["a"]);
  });

  await check("space then space deselects (toggle off)", async () => {
    const result = await drive([SPACE, SPACE, DOWN, SPACE, ENTER]); // a off, b on
    assert.deepStrictEqual(result, ["b"]);
  });

  await check("'a' twice clears all then requires a pick", async () => {
    // preselected a; 'a' selects all, 'a' again clears → empty → ENTER ignored
    // → pick b → confirm.
    const result = await drive(["a", "a", DOWN, SPACE, ENTER], ["a"]);
    assert.deepStrictEqual(result, ["b"]);
  });

  if (failures > 0) {
    process.stderr.write(`\n${failures} test failure(s).\n`);
    process.exit(1);
  }
  process.stdout.write("\nAll multiSelect tests passed.\n");
})();
