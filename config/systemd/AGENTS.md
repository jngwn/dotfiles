# systemd User-Unit Policy

- Read `DESKTOP-001`, `DATA-001`, and the closest component policy before changing
  user-unit lifecycle or state.
- Preserve explicit `PartOf`, `Wants`, `Requires`, and ordering relationships.
- Adding a long-running user service requires the authority and impact report defined
  by the root policy.
- Use `systemd-analyze --user --man=no --generators=no verify` only as a static parser
  when it cannot contact the active user manager or inspect derived state. Any active
  user-manager check is runtime verification and requires an explicit request.
