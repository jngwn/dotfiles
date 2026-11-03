# systemd User-Unit Policy

For user-unit changes, read the policy of the component whose process is managed.
Use `DESKTOP-001` in `docs/contracts.md` for lifecycle and service ownership, and
`DATA-001` for stored state, history, or cleanup.

- Preserve explicit `PartOf`, `Wants`, `Requires`, and ordering relationships.
- Use `systemd-analyze --user --man=no --generators=no verify` only as a static parser
  when it cannot contact the active user manager or inspect derived state. Checks
  involving the active user manager are runtime verification under the root policy.
