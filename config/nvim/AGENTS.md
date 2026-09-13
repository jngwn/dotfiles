# Neovim Policy

- Read `NVIM-001` and `STATE-001` in `docs/contracts.md` before changing structure,
  scope, platform rewriting, or persistence.
- Read `CLIPBOARD-001` and `TERMINAL-001` before changing clipboard providers or
  OSC 52 behavior.
- Preserve the existing `{{{ / }}}` folds and intentionally disabled rollback
  options.
- Keep the inline `Workflow reference` synchronized with user-facing keymaps,
  commands, and recovery.
- For Neovim config changes, run `stylua --check` when available. Treat a headless
  Neovim load as runtime verification and run it only when the user explicitly
  requests it. Do not run a validator that may install or initialize missing
  plugins or access the network; report that prerequisite as environment unmet.
