# Setup Script Policy

Read the contracts in `docs/contracts.md` for the behavior being changed:

- Platform selection or exclusions: `PLATFORM-001`.
- Deployment copies, links, backups, manifests, or recovery: `DEPLOY-001`.
- Machine-local state, user directories, or bookmarks: `MACHINE-001`.
- Packages, tool managers, installers, or updates: `TOOLS-001`.
- System installation ownership or destinations: `SYSTEM-001`.

For protected behavior, use the root and affected component policies to identify
the additional contracts to read. The root policy owns verification permissions
and shared shell checks.

- Do not add blanket `set -e`; each owning task must classify and report failure.
- Exit before setup for invalid invocation, unsupported platform, unsafe privilege
  context, or a prerequisite that prevents all meaningful work.
- Once bootstrap enters its task loop, attempt every task. Package installation must
  also attempt remaining available packages after an individual failure. Report the
  complete failure list and return nonzero at the owning boundary.
- Optional integrations may warn and preserve usable state when the remainder is
  meaningful. Ignore a status with `|| true` only when the expected failure is clear
  at that location.
- Keep diagnostic commands read-only and do not suppress errors needed to decide a
  mutation.
- Guard each WSL exclusion at the owning task entry before prerequisite checks or
  mutations.
