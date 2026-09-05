# Bash and Shared Tooling Policy

- Bash is the sole maintained interactive and login shell. Keep startup and
  aliases Bash-native, honor executable shebangs, and never source Bash startup
  files from POSIX `sh`.
- `home/.bashrc` owns interactive startup. `config/bash/aliases.sh` owns the
  reusable interactive command surface. Keep startup fast and quiet; do not add
  work that scales with the current repository or requires a responsive network
  filesystem.
- Gate desktop-only behavior behind environment checks and preserve explicit
  fallbacks for SSH sessions without local GUI access.
- Review `config/mise/config.toml`, `config/bash/aliases.sh`, `home/.bashrc`, and
  `scripts/bootstrap.sh` together when changing shared shell commands
  or local development tooling. No workflow document owns that command surface.
- Decide whether behavior is OS-owned or user-owned before changing bootstrap
  or system setup. Arch owns OS-integrated tools and the shared container
  runtime; mise owns user-versioned tools; each project owns dependencies,
  runtime versions, build and test commands, container images, credentials,
  ports, volumes, and service lifecycle.
- Prefer stock OS capability, then a distro package, then a small upstream
  install. Prefer current upstream releases for user-owned tools and
  distro-managed releases for OS packages, drivers, services, and desktop
  components. Pin only for a regression, compatibility boundary, or reviewed
  constraint, with a comment explaining why and when to reconsider it.
- Do not introduce lockfiles, generated version churn, or broad dependency
  pinning without a demonstrated need.
- Treat each new AUR recipe, upstream installer, release-binary source, and
  Flatpak remote as a supply-chain decision. Prefer reviewed sources and
  supported integrity verification; require an explicit decision before adding
  a new source or bypassing available verification.
- Keep development local by default. Remote compatibility guards are not
  evidence of a maintained remote workflow. Do not add speculative
  remote-workstation guidance or integration. If execution must live remotely,
  follow the repository policy for `docs/remote-development.md`.
- Reuse one explicitly owned SSH authentication agent per local session when
  practical, keep identity lifetimes bounded, and select identities per host or
  explicit user action. Do not bulk-load keys, enable forwarding globally, or
  discover and terminate agents outside the current workflow's ownership.
- Keep a helper nested only when it is meaningful solely within its parent
  operation. Do not rename established interfaces only for style consistency.
- For changed Bash startup or aliases, run `bash -n` and prefer `shellcheck` and
  `shfmt -d` when available. Report environment-unmet checks separately from
  failures.
