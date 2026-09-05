# System Configuration Policy

- `config/system/` is canonical source material for
  `scripts/bootstrap.sh`. Files installed under `/etc`,
  `/usr/local/bin`, or `/usr/local/share` are derived state and are not
  independent sources to edit.
- Review the owning bootstrap task and its maintained contract with every
  behavior change in this subtree. Privacy and security behavior belongs in
  `docs/privacy-security.md`; maintained desktop and Sway integration belongs
  in `docs/sway-workflow.md`. Do not run bootstrap or install these files as
  part of repository-only verification.
- Read `config/sway/AGENTS.md` when the change affects maintained Sway
  interaction, session state, background activity, or visual design.
- Preserve the root `AGENTS.md` protected-user-decision rules. In particular,
  network privacy, authentication, boot, disk, destructive retention, and power
  policy changes require the authority defined there.
- Keep system changes scoped to the maintained Arch Linux Sway desktop.
- Add or remove persistent system services only when the requested capability
  clearly requires it. Report owner, lifecycle, network and data impact,
  hardware behavior, and practical alternative.
- Trace a setting to the subsystem that consumes it; writing a configuration
  file does not prove runtime behavior.
- Validate changed XML with `xmllint --noout` when available. Use the smallest
  relevant static parser for JSON, TOML, and configuration files. Runtime,
  service, authentication, hardware, and reboot behavior remains unverified
  unless the user explicitly requests and authorizes the corresponding check.
