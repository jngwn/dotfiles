# tmux Policy

`config/tmux/tmux.conf` owns runtime behavior; `docs/tmux-workflow.md` owns user-facing
keys, commands, and recovery. Update the workflow when those interactions change.

- Use `CLIPBOARD-001` and `TERMINAL-001` in `docs/contracts.md` for clipboard and
  terminal integration, and `STATE-001` for server ownership or state lifetime.
- Check the complete keymap for collisions when changing a binding.
- Loading the configuration with tmux, including through an isolated server, is
  runtime verification under the root policy. Never modify the active tmux server
  for verification.
