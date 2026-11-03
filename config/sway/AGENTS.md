# Sway Policy

`config/sway/config` owns runtime behavior; `docs/sway-workflow.md` owns user-facing
keys and recovery. Update the workflow when those interactions change.

Read the contracts in `docs/contracts.md` that govern the behavior being changed:

- Device identifiers, output profiles, or local exceptions: `MACHINE-001`.
- Session lifecycle, process ownership, or background capabilities: `DESKTOP-001`.
- Keys, modes, feedback, or visible information: `INTERACTION-001`.
- Power actions or storage safety: `POWER-001`.
- Data storage, history, cleanup, or background requests: `DATA-001`.
- Visual tokens, palettes, or color semantics: `COLOR-001`.

- Preserve confirmation for destructive or broad session actions and an obvious
  `Escape` path from every mode.
- Trace cross-component changes through `config/systemd/`, `config/system/`,
  `config/power/`, and bootstrap ownership as applicable.
- Treat every `sway -C` invocation, including a headless one, as runtime
  verification under the root policy.
