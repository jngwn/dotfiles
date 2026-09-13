# AGENTS.md

## Scope and Sources

This personal repository owns dotfiles and Arch Linux bootstrap behavior for one
maintainer. Implementation files own runtime behavior; `docs/contracts.md` owns
repository rationale, constraints, and protected user decisions.

- Read the closest applicable `AGENTS.md`, canonical implementation, and relevant
  contracts before changing an area. On first familiarization and repository-wide
  review, cleanup, refactor, or improvement, read all of `docs/contracts.md` before
  judging content obsolete or proposing new owners or support paths.
- Include hidden files and directories in inspection; use Git commands for metadata
  without traversing `.git/`.
- Enforce `PLATFORM-001` and `MACHINE-001`. Do not broaden bootstrap, deployment,
  platform support, host integration, or machine-local exceptions without the
  required user decision.
- Do not add clone instructions, contributor onboarding, or multi-user abstractions
  unless explicitly requested.
- Treat unrequested flexibility as technical debt. Do not add abstractions,
  configuration switches, compatibility paths, fallbacks, or support layers
  without a demonstrated current requirement. Preserve existing flexibility
  unless canonical evidence establishes that its requirement no longer exists.
- Evaluate maintained exceptions, guards, fallbacks, and dormant mappings in both
  their present and absent states. A missing consumer or device does not establish
  obsolescence.
- Treat configuration for an uninstalled, inactive, or non-preferred program as
  intentionally retained. Its presence does not add an active support target.
  Propose removal only when the user requests an inactive-configuration review or
  canonical evidence proves a bootstrap, deployment, startup, or runtime failure,
  active ownership conflict, or security/privacy exposure. Preserve it when the
  evidence is incomplete; report uncertainty only when material to the task.

## Documentation Ownership

| Owner | Content |
| --- | --- |
| `docs/contracts.md` | Durable rationale, constraints, ownership, and change boundaries |
| `README.md` | Installation, bootstrap, deployment, and recovery procedures, including WSL |
| `docs/sway-workflow.md` | Sway interactions and recovery |
| `docs/tmux-workflow.md` | tmux interactions and recovery |
| Inline `Workflow reference` in `config/nvim/init.lua` | Neovim interactions and recovery |
| `docs/color_system.md` | Paper tokens and semantic specification |

- Read `docs/AGENTS.md` before changing maintained documentation or its ownership.
  Keep implementation mechanics in code and each durable meaning in its owner;
  if proposed knowledge fits none of these owners, do not add documentation.
- Change prose only when its meaning changes. Rewrite the smallest complete
  affected passage coherently; do not use isolated substitutions or appended
  qualifications to retain stale assumptions. Small code changes need documentation
  changes only when they affect a procedure, contract, or semantic specification.
- Edit README only when explicitly requested or when an authorized behavior change
  changes a procedure it owns. Support-boundary changes require their own explicit
  user decision.
- Preserve the single-owner documentation model. Do not create a parallel contract,
  decision log, or architecture registry without an explicit user decision.
- Keep maintained content self-contained; do not reference another repository's
  paths or workflows.
- After cross-cutting changes, check for duplicated rationale, stale contract IDs,
  and superseded owners. Remove duplication rather than synchronizing explanations.
- `AGENTS.md` governs this repository; `home/.codex/AGENTS.md` is the source of the
  deployed global policy. Change either only when that policy scope is explicitly
  requested. Keep general coding, debugging, and task-dispatch tactics out of local
  policy; retain repository facts, ownership, decision boundaries, and verification
  evidence.
- Consult current official OpenAI documentation before changing policy based on
  Codex capabilities or instruction loading. Repository-specific wording does not
  require external research.
- Review the complete policy diff for weakened constraints, conflicting authority,
  and broader permissions after an authorized policy change.

## Protected Decisions

- Require an explicit user decision before changing protected support, boot/disk,
  authentication, network/privacy, destructive data-lifecycle, power,
  service-ownership, portability, background-activity, or manual-control boundaries.
- Enforce `NETWORK-001`, `DATA-001`, and `AUTH-001`. If a critical security or
  operability issue conflicts with them, stop at diagnosis, explain impact and
  practical alternatives, and request a decision.
- Do not edit these network surfaces, including comments, formatting, or refactors,
  unless the user names the path or unambiguously requests the security behavior:
  - `scripts/bootstrap.sh`: `setup_basic_firewall`,
    `setup_trusted_network_profiles`, `setup_networkmanager_privacy`, and
    `setup_basic_network_privacy`.
  - `config/system/NetworkManager/conf.d/99-privacy.conf`.
  - `config/system/systemd/resolved.conf.d/60-network-privacy.conf`.
  - Network-policy entries, including `DNSOverHTTPS`, in
    `config/system/firefox/policies/policies.json`.
  - `scripts/network_privacy_mode.sh`.
  - `NETWORK-001` in `docs/contracts.md`.
- Enforce `POWER-001` before changing low-battery actions, hibernation, swap/resume,
  or encrypted-volume discard.
- Add or remove OS packages, persistent system services, or long-running user
  services only when the requested capability requires it. Report owner, lifecycle,
  network/data impact, hardware behavior, and a practical alternative.

## Implementation and Component Boundaries

- `scripts/bootstrap.sh` owns OS setup; `scripts/deploy_dotfiles.sh` owns deployment.
  Enforce `DEPLOY-001` and `SYSTEM-001`, and read `scripts/AGENTS.md` for this work.
  Read `config/system/AGENTS.md` for sources installed to system paths.
- Edit canonical sources and deploy through their owner. Derived paths identify
  their source, not independent evidence or edit targets. Inspect installed tools,
  tool-manager state, or deployed copies only for explicitly requested deployment,
  runtime diagnosis, or another concrete machine-state operation.
- A system-source removal or rename is incomplete until the same authorized change
  names and removes the former installed destination through its owning bootstrap
  path and documents recovery. Never infer deletion of an unknown system file from
  the absence of a repository source.
- Repository edits do not authorize setup, deployment, bootstrap, upgrade, or other
  machine changes. Sandbox approval permits only the already authorized operation.
- Read `config/bash/AGENTS.md` for Bash and shared tooling, including changes outside
  that directory. Enforce `SHELL-001`, `OPEN-001`, `CLIPBOARD-001`, `TERMINAL-001`,
  and `TOOLS-001`; read `scripts/AGENTS.md` when bootstrap ownership is affected.
  A discretionary compatibility pin needs a demonstrated constraint and a local
  comment stating when to reconsider it; manager-required revisions remain intact.
- Read `config/nvim/AGENTS.md` for Neovim and its inline workflow, and
  `config/tmux/AGENTS.md` for tmux and its workflow.
- Read `config/sway/AGENTS.md` for Sway interaction, session state, visual design,
  behavior, or workflow changes, including implementations outside `config/`.
  Read `config/systemd/AGENTS.md` for session user services. Enforce `DESKTOP-001`,
  `INTERACTION-001`, `POWER-001`, and `COLOR-001`.
- Trace desktop settings to their actual consumer; accepted syntax or a successful
  write does not prove behavior. Graphical commands must resolve without relying
  on interactive-shell `PATH`.
- Preserve existing `{{{ / }}}` folds. Name large closing sections only when useful
  for navigation; keep ordinary function closing markers simple.

## Verification and Reporting

- Default to focused static inspection. Do not run applications, tests, builds,
  or services as verification without an explicit request for the corresponding
  runtime operation. Never use bootstrap or deployment as verification. Do not
  install or initialize verification dependencies or request elevation solely for
  verification.
- `.pre-commit-config.yaml` owns the hook list. Run hooks only when they do not
  install or initialize dependencies or plugins, access the network, create target
  application state, or start services, servers, or sessions. Scope rewriting hooks
  to reviewed files and inspect their changes.
- The hook configuration defines available gates; it does not prove that a
  checkout-local hook is installed, executed, or blocking. Bootstrap does not
  install the Git hook. Before a requested commit, inspect the local hook state and
  report whether checks were run directly, invoked by Git, or skipped.
- Use the component's static checks and `xmllint --noout` for changed XML when
  available. Run `git diff --check` after edits.
- Classify environment-dependent checks as passed, failed, environment unmet,
  result invalid, or skipped. Missing prerequisites do not establish success or
  failure. Report repository changes, deployment, and runtime verification separately.
- After an explicitly requested deployment, compare the relevant target with its
  canonical source. Report checks run or skipped and any remaining system, desktop,
  hardware, reboot, deployment, or runtime uncertainty.

## Work State and Handoff

- For work that must continue in another session, designate an existing issue, PR,
  or task-specific implementation plan as the handoff owner. Do not create a
  standing handoff document for routine changes.
- Record the owning task, baseline branch and commit, clean or dirty working-tree
  state, changes owned by the task, pre-existing changes, completed verification,
  unverified deployment or runtime state, remaining decisions, and the next step.
- A chat-only summary is not a durable handoff when the next session cannot access
  it. On resume, compare the handoff with Git and artifact evidence before accepting
  its completion claims.

## Output and Git

- Do not use emoji in code, documentation, commits, or runtime output. Prefer
  `INFO`, `WARN`, `ERROR`, and `DONE` labels in interactive scripts; use standard
  logging levels for structured logs.
- Commit and push only when explicitly requested. Review status, diff, and relevant
  verification first; include only reviewed changes belonging to one clear intent.
- Do not bypass hooks with `--no-verify`; fix the failure or report the blocker.
- Use Conventional Commits with a concise lowercase `type: summary`; prefer
  `feat`, `fix`, `docs`, `refactor`, or `chore`.
