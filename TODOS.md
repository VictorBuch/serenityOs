# TODOS

## sync script: `--check` dry-run flag
- **What:** Add `sync --check` mode that runs `nixos-rebuild build` (no switch) and skips the push step.
- **Why:** Lets you verify a config change evaluates and builds before activating it on all three machines. Useful before risky merges (kernel bump, disko changes, stylix theme swap).
- **Pros:** Catches eval errors without touching the running system; cheap (reuses same flake path, just `build` not `switch`).
- **Cons:** Doubles the script's surface area from ~30 to ~40 lines; invites more flag creep (`--no-push`, `--host <x>`, etc.).
- **Context:** Original sync script written 2026-04-21 at `modules/apps/cli/sync.nix`. Flow: fetch → ff/abort → rebuild → push-on-success. Adding `--check` means branching on arg before `rebuild()` step and short-circuiting before `push()`. Darwin variant runs `darwin-rebuild build`.
- **Depends on:** sync script merged first.
