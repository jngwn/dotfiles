# systemd User-Unit Policy

- Read `config/sway/AGENTS.md` for Sway-session lifecycle and state rules. Root
  policy owns shared desktop design, privacy, and background-activity boundaries.
- Keep Sway session daemons owned by `sway-session.target` so compositor reloads
  do not duplicate them and logout does not leave them running.
- Preserve clear `PartOf`, `Wants`, `Requires`, and ordering relationships. Add
  long-running user services only when the requested capability requires them,
  and report lifecycle, network and data impact, hardware behavior, and a
  practical alternative.
- Keep sensitive session state under `%t`/`XDG_RUNTIME_DIR` with explicit
  startup and shutdown lifetime. Do not add persistent history or indexes for
  convenience.
- On a systemd user environment, validate changed units with `systemd-analyze --user --man=no --generators=no verify` and the relevant files under `config/systemd/user/`.
