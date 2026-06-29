## 1. multiSelect component

- [x] 1.1 Add `multiSelect(items, { input, output, isTTY, preselected })` to `installer/common.js`, returning selected ids (≥1)
- [x] 1.2 Implement the TTY checkbox: `↑/↓`+`j/k` move, `space` toggle, `a` toggle-all, `enter` confirm (re-prompt if none), `Ctrl-C` abort; hide/restore cursor; `closeRl()` before raw mode
- [x] 1.3 Implement ANSI redraw (print once, move-up-and-rewrite on each keypress) to the output stream
- [x] 1.4 Implement the non-TTY fallback: delegate to the comma-separated parser (numbers / ids / `all`, reject unknown)

## 2. Detection-based pre-selection

- [x] 2.1 Add an agent-detection helper: install → agent config dir (`.claude`, `.opencode`, `.cursor`, `.copilot`, `.codex`) exists under the chosen base
- [x] 2.2 Uninstall detection → agent present in the registry `skills_targets`, or `{base}/{subpath}/_super8-studio-api-shared` exists

## 3. Wire into install & uninstall

- [x] 3.1 Rewrite `install.js` `promptAgents` to compute install pre-selection and call `multiSelect`
- [x] 3.2 Rewrite `uninstall.js` `promptAgents` to compute uninstall pre-selection and call `multiSelect`
- [x] 3.3 Confirm non-interactive flags (`--agents`, `all`) and the rest of both flows are unchanged

## 4. Tests & verification

- [x] 4.1 Unit-test `multiSelect` via an injected keypress stream: move/toggle/all/confirm and the ≥1 guard
- [x] 4.2 Confirm `npm run smoke` still passes (non-TTY fallback path), and `validate` + `test` stay green
- [x] 4.3 Manually verify the checkbox — macOS verified OK; Windows deferred to post-release external testing (CI uses piped input → fallback, so the TUI layer is only verifiable on a real terminal)
- [x] 4.4 Confirm CI matrix (ubuntu/macos/windows × node 18,20) stays green
