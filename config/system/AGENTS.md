# System Configuration Policy

`config/system/` supplies the canonical files installed by `scripts/bootstrap.sh`.
Use `SYSTEM-001` in `docs/contracts.md` for installation ownership and destination
changes. Select the other contracts by the setting affected: `NETWORK-001` for
network policy, `AUTH-001` for authentication, `DATA-001` for privacy, retained data,
or background requests, and `POWER-001` for power and storage safety.

- Read `config/sway/AGENTS.md` when a change affects Sway interaction, session state,
  background activity, or visual design.
- Use the smallest relevant static parser for JSON, TOML, and other configuration
  formats. The root policy owns shared verification rules and installed-file safety.
