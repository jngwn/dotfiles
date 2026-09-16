# Neovim Policy

- `config/nvim/init.lua` is the sole Neovim runtime configuration. Preserve its
  `{{{ / }}}` folds and intentionally disabled rollback options.
- Read `NVIM-001` before changing the editor's scope, configuration structure, or
  platform-specific behavior, and `STATE-001` before changing persistence.
  Clipboard provider or OSC 52 changes also require `CLIPBOARD-001` and
  `TERMINAL-001`.
- Check changes with `stylua --check` when available. Headless Neovim loads are
  runtime verification and require an explicit user request. Do not use validation
  that installs or initializes plugins or accesses the network; report an unmet
  prerequisite instead.
