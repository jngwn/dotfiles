# tmux Policy

- Read `CLIPBOARD-001`, `TERMINAL-001`, and `STATE-001` in
  `docs/contracts.md` before changing tmux clipboard, server ownership, or state
  lifetime.
- `config/tmux/tmux.conf` is the runtime source of truth. Keep user-facing keys,
  commands, and recovery synchronized with `docs/tmux-workflow.md`.
- Check the complete keymap for collisions when changing a binding.
- Loading the configuration with tmux, including through an isolated server, is
  runtime verification. Run it only when explicitly requested and never modify the
  active tmux server for verification.
