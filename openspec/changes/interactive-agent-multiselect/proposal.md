## Why

Agent selection is already multi-select, but only via a typed comma-separated list (`1,3,5` / ids / `all`). That works yet isn't discoverable or ergonomic — users expect a checkbox-style picker. This adds a zero-dependency, raw-mode checkbox multi-select on a TTY, while preserving the comma-list path as the non-TTY fallback that CI and piped input rely on.

## What Changes

- Add a reusable zero-dependency `multiSelect` component (in `installer/common.js`): an interactive checkbox picker on a TTY — `↑/↓` (and `j/k`) to move, `space` to toggle, `a` to select/deselect all, `enter` to confirm, `Ctrl-C` to abort. Enforces at least one selection.
- **Non-TTY fallback**: when `stdin` is not a TTY (CI, piped input, smoke test), fall back to the existing comma-separated prompt (numbers / ids / `all`). Behavior and parsing unchanged there.
- **Pre-selection by detection**:
  - Install — pre-check agents the user appears to use: the agent's config dir exists under the chosen base (e.g. `~/.claude` → claude-code). None detected → nothing pre-checked.
  - Uninstall — pre-check agents that actually have the bundle installed (recorded `skills_targets` in the registry, or `{base}/{subpath}/_super8-studio-api-shared` present).
- Use the same picker for **both** `install` and `uninstall` agent selection.
- **Testability**: `multiSelect` accepts injectable `input`/`output`/`isTTY` so the keypress logic is unit-tested without a real terminal; the non-TTY fallback stays covered by the smoke test.

## Capabilities

### New Capabilities
<!-- None — this modifies the existing installer capability. -->

### Modified Capabilities
- `skill-installer`: Interactive agent selection becomes a checkbox multi-select on a TTY (with detection-based pre-selection and a minimum of one), falling back to the comma-separated list on non-TTY. The same picker is used by uninstall.

## Impact

- **Code**: `installer/common.js` (new `multiSelect` + an agent-detection helper); `installer/install.js` and `installer/uninstall.js` (`promptAgents` uses `multiSelect` with context-specific pre-selection); the raw-mode handling mirrors the existing `promptHidden` (must `closeRl()` before entering raw mode).
- **Tests**: new unit test driving `multiSelect` via an injected keypress stream; existing smoke test continues to exercise the non-TTY comma-list path.
- **Platforms**: TTY checkbox is exercised manually (CI uses piped input → fallback). Windows raw-mode arrow-key/redraw compatibility is a known risk to verify by hand.
- **No change** to the agent set, subpaths, registry format, non-interactive flags, or copy semantics.
