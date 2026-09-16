# Bash and Shared Tooling Policy

- Read `SHELL-001`, `OPEN-001`, `TOOLS-001`, `DATA-001`, and `STATE-001` in
  `docs/contracts.md` before changing this area.
- `home/.bashrc` owns interactive startup, `config/bash/aliases.sh` owns the shared
  command surface, `config/bash/platform/` owns capability adapters, and
  `home/.local/bin/open-path` owns the shared opener.
- Keep startup fast and quiet. Do not add work that scales with the current
  repository or depends on a responsive network filesystem.
- Gate desktop behavior on the actual session capability and preserve non-GUI
  fallbacks for SSH.
- Review `config/mise/config.toml`, the Bash owners above, and
  `scripts/bootstrap.sh` together when a shared development tool changes.
- Keep a helper nested only when it has no meaning outside its parent operation. Do
  not rename established interfaces only for style consistency.
- For changed Bash startup or aliases, run `bash -n`; use `shellcheck` and `shfmt -d`
  when available under the root static-verification rules.
