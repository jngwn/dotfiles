# System Configuration Policy

- Read `SYSTEM-001` and every affected security, desktop, power, authentication, or
  data contract in `docs/contracts.md` before changing this area.
- `config/system/` is source material for `scripts/bootstrap.sh`; installed copies
  under system paths are derived state and not independent edit targets.
- Preserve all root protected-decision rules. Do not run bootstrap or install files
  as repository-only verification.
- Read `config/sway/AGENTS.md` when a change affects Sway interaction, session state,
  background activity, or visual design.
- Trace each setting to its actual consumer. A valid configuration write alone does
  not establish runtime behavior.
- Validate changed XML with `xmllint --noout` when available and use the smallest
  relevant static parser for JSON, TOML, and other configuration files.
