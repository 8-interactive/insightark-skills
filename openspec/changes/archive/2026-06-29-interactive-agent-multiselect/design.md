## Context

`installer/install.js` and `installer/uninstall.js` select agents through `promptAgents`, which prints a numbered list and parses a typed comma-separated answer (numbers / ids / `all`). Prompts use a shared persistent `readline` line-queue in `installer/common.js` (so piped multi-line input isn't dropped); `promptHidden` already demonstrates the raw-mode pattern (it calls `closeRl()` before taking exclusive control of stdin). The bundle is strictly zero-dependency and runs on macOS, Linux, and native Windows. CI and the smoke test drive the interactive flow via piped stdin.

This change adds a checkbox-style multi-select for TTYs while keeping the typed list as the non-TTY fallback.

## Goals / Non-Goals

**Goals:**
- Ergonomic checkbox multi-select on a real terminal, zero dependencies.
- Preserve a working non-TTY path (CI, pipes, smoke) — no behavior change there.
- Pre-select sensible defaults by detecting the user's agents (install) / installed bundle (uninstall).
- Make the picker logic unit-testable without a real terminal.

**Non-Goals:**
- No new dependency (no inquirer/prompts).
- No change to the agent set, subpaths, registry, non-interactive flags, or copy semantics.
- No attempt to unit-test the raw terminal layer itself in CI (covered manually).

## Decisions

### D1: One reusable, stream-injectable `multiSelect`
Add `multiSelect(items, { input = process.stdin, output = process.stderr, isTTY = input.isTTY, preselected })` to `common.js`, returning the chosen ids (≥1). Both install and uninstall call it.
- **Why**: One implementation, one set of tests, consistent UX. Injectable streams let tests feed a fake keypress sequence and assert the result without a TTY.
- **Alternative**: inline per-caller (rejected — duplicated raw-mode code, untestable).

### D2: TTY checkbox; non-TTY falls back to the comma list
When `isTTY` is false, delegate to the existing comma-separated prompt (numbers / ids / `all`, reject unknown). When true, run the raw-mode checkbox.
- **Why**: CI/smoke/pipes must keep working; the typed parser already handles them. Only real terminals get the TUI.
- **Keys**: `↑/↓` and `j/k` move; `space` toggles; `a` toggles all; `enter` confirms (re-prompts if zero selected); `Ctrl-C` aborts (exit non-zero). Output to stderr; hide the cursor on entry and restore on exit.
- **readline interaction**: like `promptHidden`, call `closeRl()` before entering raw mode; the next `prompt()` lazily recreates the line reader.

### D3: Detection-based pre-selection, context-specific
A helper resolves which agents to pre-check:
- Install — agent "present" if `{base}/{configDir}` exists, where `configDir` is the parent of the skills subpath (`.claude`, `.opencode`, `.cursor`, `.copilot`, `.codex`). `base` is the location chosen in Step 1.
- Uninstall — agent pre-checked if the bundle is actually installed for it: its target appears in the registry `skills_targets`, or `{base}/{subpath}/_super8-studio-api-shared` exists.
- **Why**: Install should pre-check "agents you use" to save keystrokes; uninstall should pre-check "agents that actually have it" to avoid targeting empty dirs. Detection is pure filesystem/registry reads — testable against a temp base.
- **When nothing is detected**: nothing pre-checked; the user must pick at least one.

### D4: Minimum one selection
Confirming with zero selected re-prompts (TTY) or errors and re-asks (non-TTY), matching today's "at least one agent is required".

### D5: Rendering approach
Print the list once, then on each keypress move the cursor up N lines and rewrite (ANSI). Keep it line-based and simple; no full-screen alternate buffer. Degrade to the fallback if `output` is not a TTY.

## Risks / Trade-offs

- **Windows raw-mode compatibility** → Arrow-key escape sequences and ANSI redraw differ between ConPTY (modern Windows Terminal) and legacy conhost. Mitigation: support `j/k` as arrow alternatives; keep the comma-list fallback; verify manually on Windows. If raw mode misbehaves, the fallback path still installs correctly.
- **CI cannot exercise the TUI** → CI/smoke use piped stdin → fallback. Mitigation: unit-test the picker via injected keypress streams (D1); treat the real-terminal layer as manually verified. Note this gap explicitly.
- **Terminal redraw glitches** (resize, very small terminals) → Keep rendering minimal; acceptable cosmetic risk. The selection result is unaffected.
- **Two selection paths to maintain** → Inherent to supporting both TTY and non-TTY. Mitigation: the fallback is the existing, already-tested parser; only the TTY layer is new.
- **Stdin handoff bugs** (raw mode vs the shared readline) → Mirror the proven `promptHidden` sequence (`closeRl()` → raw → restore); cover with the injected-stream test.

## Migration Plan

1. Implement `multiSelect` + an agent-detection helper in `common.js` (injectable streams; cursor hide/restore; `closeRl()` before raw mode).
2. Rewrite `install.js` `promptAgents` to compute install-context pre-selection and call `multiSelect`; keep the comma parser as the non-TTY branch inside `multiSelect`.
3. Rewrite `uninstall.js` `promptAgents` likewise with uninstall-context pre-selection.
4. Add a unit test driving `multiSelect` with a scripted keypress stream (move/toggle/all/confirm, and the ≥1 guard); keep smoke covering the non-TTY fallback.
5. Manually verify on macOS/Linux and a Windows terminal.
6. **Rollback**: revert; `promptAgents` returns to the typed comma list (no data/format changes to undo).

## Open Questions

- Should `space`-less power users still be able to type a quick filter? Out of scope for now; the non-TTY fallback already accepts typed ids/numbers.
