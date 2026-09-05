# Sway Policy

- Apply the root desktop-wide interaction and design rules when maintained Sway
  behavior touches `config/systemd/`, `config/system/`, bootstrap code, or
  `docs/sway-workflow.md`.
- Keep the shared Sway compositor configuration in `config/sway/config` as its SSOT.
- Prefer native Wayland paths for maintained desktop applications and services. Keep XWayland as a compatibility boundary for applications that still require X11.
- Manage session services with clear Sway/systemd user-session ownership so reloads do not create duplicate processes and logout does not leave desktop services running.
- Keep user-facing key bindings synchronized with the Sway workflow documentation.
- Do not encode machine-specific output identifiers in the shared Sway config. Put reviewed per-machine output layouts in the dedicated output-profile configuration.
- Shared behavior must remain valid on desktop and laptop hardware. Battery,
  backlight, lid, and output helpers must remain inert when matching hardware is
  absent and must not encode fixed device identities.
- Preserve existing confirmation and recovery paths for destructive, broad, or
  stateful session actions. Every mode must retain an obvious `Escape` path.
- On an Arch Sway environment, validate `config/sway/config` with `WLR_BACKENDS=headless WLR_RENDERER=pixman WLR_LIBINPUT_NO_DEVICES=1 sway -C -c config/sway/config`.
