# tmux Policy

- `config/tmux/tmux.conf` is the source of truth for tmux keys and behavior;
  `docs/tmux-workflow.md` is the maintained user workflow contract. Keep them
  synchronized when user-facing behavior changes.
- Preserve the named `main` tmux server shared by the Bash entry points and
  management aliases unless the user explicitly changes that workflow.
- Preserve explicit user-owned window names and avoid automatic rename behavior.
- Keep scrollback, marks, and copy buffers server-memory-owned unless the user
  explicitly chooses persistent task history.
- Keep clipboard integration functional without a graphical clipboard by
  retaining tmux's own buffer as the fallback.
- Check the complete keymap for collisions and preserve the documented backtick
  prefix and nested-prefix path unless the requested change intentionally
  revises them.
- Validate syntax with the installed tmux when practical, without starting or
  modifying the user's active tmux server. Always run `git diff --check`.
