# VS Code Policy

- Keep VS Code settings pragmatic and aligned with the maintained local
  development workflow. Do not chase full Neovim or IdeaVim parity; share only
  repeated editing and navigation behavior that maps cleanly to native actions.
- Treat `settings.json` as JSONC. Validate it with the configured Biome JSONC
  parser, not a strict JSON parser.
- Preserve explicit user control over updates, synchronization, telemetry, and
  background network activity unless the user requests a policy change.
- Keep the local Paper theme declarative and free of executable extension-host
  code, network activity, update checks, and persistent state.
- Extension additions are tool and supply-chain decisions. Add one only for a
  demonstrated workflow need and keep project-owned quality tools conditional on
  project configuration.
