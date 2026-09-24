# Setup Script Policy

- Read `PLATFORM-001`, `DEPLOY-001`, `MACHINE-001`, `TOOLS-001`, `SYSTEM-001`, and
  every affected protected contract in `docs/contracts.md` before changing setup or
  deployment behavior.
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
- Never run setup, deployment, bootstrap, upgrade, or another machine-changing
  workflow as verification.
- For changed scripts, run `bash -n`; use `shellcheck` and `shfmt -d` when available
  under the root static-verification rules. Always run `git diff --check`.
