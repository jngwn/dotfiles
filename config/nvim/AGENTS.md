# Neovim Policy

- Keep Neovim configuration as a single-file SSOT in `config/nvim/init.lua`.
- Preserve the existing `{{{ / }}}` fold structure.
- Preserve intentionally commented-out Lua code in `init.lua`; it records
  maintained optional settings and rollback references. Do not remove it as
  dead-code cleanup without an explicit user request.
- Keep the WSL-only automatic carriage-return trimming in `init.lua` as an
  intentional file-compatibility exception. It does not make WSL a maintained
  platform or authorize broader WSL support; do not treat it as an inconsistency
  or remove or change it without an explicit user request.
- Do not split the Neovim config into modules unless explicitly requested.
- Keep the inline `Workflow reference` synchronized with user-facing keymaps,
  commands, and workflows. Do not create a separate workflow document unless
  the inline reference is no longer sufficient.
- Preserve the stated scope: quick local editing and review, single-file
  interview problems, nearby file management, Git-change review, and precise
  file references. Project builds, tests, dependencies, debugging, and broad
  automation remain project or terminal owned.
- Keep the plugin set small and use plugins only for clear, irreplaceable value.
  Do not add or configure Treesitter unless explicitly requested.
- Keep LSP limited to the language servers and completion model documented at
  the top of `init.lua` unless the user requests a scope change.
- Preserve `paper-custom.vim` license and attribution; do not guess its upstream revision outside an explicit refresh.
- Treat the configured Neovim ShaDa, persistent undo, and cursor views as an explicit productivity exception to activity-record minimization. Keep this state user-owned under Neovim's state directory, do not expand its categories or expire it automatically, and require an explicit user decision before changing its persistence.
- For Neovim config changes, run `stylua --check` and a headless load check when
  practical. Do not run a validator that may initialize missing plugins or
  download network state; report that prerequisite as environment unmet.
