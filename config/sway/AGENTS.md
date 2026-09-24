# Sway Policy

- Read `MACHINE-001`, `DESKTOP-001`, `INTERACTION-001`, `POWER-001`, `DATA-001`,
  and `COLOR-001` in `docs/contracts.md` before changing this area.
- `config/sway/config` is the runtime source of truth. Keep user-facing keys and
  recovery synchronized with `docs/sway-workflow.md`.
- Preserve confirmation for destructive or broad session actions and an obvious
  `Escape` path from every mode.
- Trace cross-component changes through `config/systemd/`, `config/system/`,
  `config/power/`, and bootstrap ownership as applicable.
- Treat every `sway -C` invocation, including a headless one, as runtime
  verification. Run it only when explicitly requested; otherwise use static review.
