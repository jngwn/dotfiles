# Neovim Policy

- `config/nvim/init.lua` owns general editor behavior,
  `config/nvim/plugin/packages.lua` owns external plugin declarations, other
  `config/nvim/plugin/*.lua` files own independently auto-loaded features,
  `config/nvim/after/plugin/*.lua` owns per-plugin configuration, and
  `config/nvim/lsp/*.lua` owns server-specific configuration. Use `{{{ / }}}`
  folds only to separate multiple useful sections within one runtime file; do
  not wrap an entire modular file in one fold. Preserve intentionally disabled
  rollback options.
- Read `NVIM-001` before changing the editor's scope, configuration structure, or
  platform-specific behavior, and `STATE-001` before changing persistence.
  Clipboard provider or OSC 52 changes also require `CLIPBOARD-001` and
  `TERMINAL-001`.
- Check changes with `stylua --check` when available. Headless Neovim loads are
  runtime verification and require an explicit user request. Do not use validation
  that installs or initializes plugins or accesses the network; report an unmet
  prerequisite instead.
