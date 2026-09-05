# Setup Script Policy

- Do not add blanket `set -e` behavior to the setup scripts; failures are
  classified and handled at the owning task boundary.
- Exit before setup begins for invalid invocation, unsupported platform, unsafe
  privilege context, or a missing prerequisite that prevents any meaningful
  work.
- Once `bootstrap.sh` enters its task loop, attempt every declared
  task even when an earlier task fails. Record each failed task, report the
  complete list after the final task, and return nonzero only then.
- Within Arch package installation, an unavailable or failed package must not
  prevent the remaining available packages and package groups from being
  attempted. Return nonzero after those attempts so the task is included in the
  final bootstrap failure summary.
- Return nonzero for an operation that did not complete so the owning task can
  record it accurately instead of treating incomplete state as success.
- For optional tools and integrations, emit `WARN`, preserve usable state, and continue when the remaining setup is still meaningful.
- Ignore an exit status with `|| true` only when that failure is expected and the surrounding code or comment makes the reason clear.
- Keep diagnostic commands read-only, and do not suppress their errors when the output is needed to decide a state-changing action.
- The checked-out repository is canonical. `~/.dotfiles` is a disposable derived
  deployment copy when deployment runs from another path, and deployed home and
  config entries are symlinks into that copy.
- Keep deployment simple: replace the derived copy as a whole during each manual
  deployment, preserve the previous copy in the run-specific timestamped backup,
  and leave recovery to an explicit manual decision. Do not add manifests,
  staging, automatic pruning, or automatic rollback unless explicitly requested.
- Treat `config/system/` as source material for bootstrap installation. Do not
  expose it as inert user configuration or edit installed `/etc` and
  `/usr/local` copies as independent sources.
- Keep machine-owned state outside shared deployment. Preserve
  `~/.config/kanshi/local.conf` across derived-copy replacement and keep
  identities, SSH hosts, VPN profiles, certificates, and credential-bearing
  state outside the repository.
- A path under a derived deployment identifies the canonical source to edit; do
  not inspect or modify the derived path by default.
- Arch Linux with Sway is the sole supported setup and deployment target.
- Add or remove OS packages, persistent system services, or long-running user
  services only when the requested capability clearly requires it. Report the
  owner, lifecycle, network and data impact, hardware behavior, and practical
  alternative.
- Repository-only work may use already-installed tools for permitted static
  checks, but must not use installed or active machine state as evidence. Do not
  download, invoke package managers, create temporary environments, or run
  machine-state probes unless explicitly requested or required by authorized
  verification.
- Never run setup, deployment, bootstrap, upgrade, or other machine-changing
  workflows as verification. Distinguish repository changes, deployment, and
  runtime verification in every report.
- For changed scripts, run `bash -n` and prefer `shellcheck` and `shfmt -d` when
  available. Always run `git diff --check`.
