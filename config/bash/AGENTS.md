# Bash and Shared Tooling Policy

`home/.bashrc` owns interactive startup, `config/bash/aliases.sh` owns the shared
command surface, `config/bash/platform/` owns capability adapters, and
`home/.local/bin/open-path` owns the shared opener.

Read the contracts in `docs/contracts.md` that govern the behavior being changed:

- Shell startup, platform integration, or SSH agent lifecycle: `SHELL-001`.
- Path opening or file-operation boundaries: `OPEN-001`.
- Clipboard providers or terminal integration: `CLIPBOARD-001` and `TERMINAL-001`.
- Tool installation or updates: `TOOLS-001`. Review `config/mise/config.toml`, the
  Bash owners above, and `scripts/bootstrap.sh` together for shared tool changes;
  use `scripts/AGENTS.md` when bootstrap ownership is affected.
- History, cleanup, or background requests: `DATA-001`.
- tmux entry points or recovery state: `STATE-001`.

- Keep startup fast and quiet. Do not add work that scales with the current
  repository or depends on a responsive network filesystem.
- Gate desktop behavior on the actual session capability and preserve non-GUI
  fallbacks for SSH.
- Keep a helper nested only when it has no meaning outside its parent operation. Do
  not rename established interfaces only for style consistency.
