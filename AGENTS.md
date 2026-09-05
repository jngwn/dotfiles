# AGENTS.md

## Repository Purpose and Support

This personal repository owns dotfiles and Arch Linux bootstrap behavior for one
maintainer.

- `scripts/bootstrap.sh` owns Arch Linux OS bootstrap.
- `scripts/deploy_dotfiles.sh` owns dotfile deployment.
- `config/nvim/init.lua` owns Neovim configuration.
- Arch Linux with Sway on Wayland is the sole maintained platform and deployment
  target.
- Shared Sway behavior must support desktop and laptop hardware without fixed
  output names, PCI addresses, batteries, backlights, or lid switches. Isolate
  unavoidable machine-specific output profiles.
- Do not add support paths for other platforms, operating systems, or distributions
  without an explicit user decision.
- Retain README's `Arch Linux on WSL` section as an intentional auxiliary note for
  initial user setup. It does not make WSL a supported bootstrap or deployment
  target; change or remove the section only by explicit user decision.
- Do not add clone instructions, contributor onboarding, or multi-user abstractions
  unless explicitly requested.

## Operating Model

- Read the closest applicable `AGENTS.md`, canonical implementation, and maintained
  contract before changing an area.
- Treat review, analysis, diagnosis, and familiarization as read-only. Implement a
  change only when the user requests one.
- When one safe implementation clearly follows the request and existing policy,
  proceed without asking. Ask only when a missing choice would materially change
  the outcome, scope, authority, or a protected decision below.
- Work from canonical repository files, documentation, and Git metadata by default.
  Do not inspect or infer from deployed files, home configuration, installed tools,
  caches, user tool-manager state, or active services unless the user requests
  deployment, runtime diagnosis, or a concrete machine-state operation.
- Include hidden dotfiles and dot directories in repository inspection, but do not
  traverse `.git/`; use Git commands for repository metadata.
- For repository familiarization, inspect only files, documentation, Git metadata,
  and static relationships. Do not run tests, validators, headless applications,
  service checks, deployment comparisons, or runtime probes unless verification or
  diagnosis is explicitly requested.
- Preserve user-owned and unrelated changes. Prefer the smallest coherent edit to
  existing files, follow local style, and avoid generated churn, broad refactors,
  and style-only rewrites.
- An explicit user decision to keep, preserve, or exclude something remains
  authoritative until the user explicitly reverses it. A later request to clean up,
  simplify, refactor, reorganize, or remove unnecessary material does not by itself
  authorize changing that decision.
- Do not infer that maintained content, a rule, exception, guard, fallback,
  compatibility boundary, dormant mapping, or other constraint is obsolete solely
  because the current checkout, machine, or runtime has no matching file, consumer,
  hardware, or active use. Establish its behavior for both present and absent states
  from canonical contracts and permitted evidence before removing or narrowing it;
  when evidence is incomplete, preserve it and report the uncertainty.
- Run setup, deployment, bootstrap, upgrade, and other machine-changing workflows
  only when explicitly requested. Execution sandboxing and safety constraints remain
  authoritative; approval or elevated execution permits only the already authorized
  operation and never expands task scope.

## Ownership and Documentation

Implementation and configuration files are the source of truth for runtime behavior.
Maintained contracts record the maintainer-facing commands, inputs, prerequisites,
side effects, constraints, decision boundaries, and recovery paths that cannot be
safely inferred from implementation alone.

| Area | Canonical owner | Maintained contract |
| --- | --- | --- |
| OS bootstrap | `scripts/bootstrap.sh` | `README.md` |
| Dotfile deployment | `scripts/deploy_dotfiles.sh` | `README.md` |
| Privacy, security, and data retention | Privacy and retention sources under `config/` and `scripts/bootstrap.sh` | `docs/privacy-security.md` |
| Desktop and Sway session integration | `config/sway/`, `config/power/`, `config/systemd/user/`, desktop-owned sources under `config/system/`, and `scripts/bootstrap.sh` | `docs/sway-workflow.md` |
| tmux keys and sessions | `config/tmux/tmux.conf` | `docs/tmux-workflow.md` |
| Neovim keys and workflows | `config/nvim/init.lua` | Inline `Workflow reference` in `config/nvim/init.lua` |
| Paper palette semantics and intentional mappings | `docs/color_system.md` | `docs/color_system.md` |

- Keep `README.md` limited to installation, bootstrap, and recovery. Edit it only
  when the user explicitly requests README changes. If an authorized behavior change
  makes it inaccurate, leave it unchanged and report the exact stale section,
  changed behavior, and required follow-up.
- Update maintained contracts in the same change when their operational behavior
  becomes inaccurate. Read `docs/AGENTS.md` before changing workflow documentation
  or its ownership.
- Read `config/bash/AGENTS.md` before changing shared shell commands or local
  development tooling, and read `config/nvim/AGENTS.md` before changing the inline
  Neovim workflow contract.
- Read `config/tmux/AGENTS.md` before changing tmux configuration or its maintained
  workflow, and read `config/Code/AGENTS.md` before changing VS Code settings or the
  local extension under `home/.vscode/`.
- `AGENTS.md` governs this repository; `home/.codex/AGENTS.md` is the deployed global
  policy. Change either only when the user explicitly requests that policy scope,
  and never as incidental cleanup.
- Before changing policy based on Codex capabilities or instruction loading, consult
  current official OpenAI documentation. Repository-specific wording does not
  require external research.
- When adding agent-facing policy, preserve only durable repository facts,
  ownership, user decision boundaries, or verification evidence. Keep coding,
  debugging, review, and task-dispatch tactics owned by the active agent or
  methodology.
- Keep maintained content self-contained. Do not reference another repository's
  paths, files, or workflows; adopt necessary facts into an existing local owner.
- After an authorized policy change, review the complete policy diff for weakened
  constraints, conflicting authority, and broader permissions.

## Privacy and Security

- Keep recurring network activity opt-in and user-initiated. Do not
  enable telemetry, analytics, crash uploads, automatic update polling,
  geolocation, cloud synchronization, or similar background requests unless
  explicitly requested or required. When justified, document purpose,
  transmitted data, cadence, and disable path. Prefer an established manual
  workflow when it already covers the need.
- Preserve reviewed firewall and network-privacy policy. If a critical security
  or operability issue conflicts with it, stop at diagnosis, report impact and
  practical alternatives, and request a decision.
- Minimize persistent local metadata and activity records. Before adding
  history, cache, or state, define what is stored, where, for how long, and how
  it is cleared. Do not add persistent history or indexes merely for
  convenience; prefer user-invoked lookup and session-scoped state. Preserve
  only explicitly maintained workflow state with a documented lifetime and
  clear path.
- For sensitive graphical-session state, prefer `XDG_RUNTIME_DIR` and enforce
  the lifetime at session start and shutdown; logout-only cleanup is
  insufficient.
- Do not automatically delete user data, trash, browser state, credentials, or
  broad development caches without an explicit request.

## Protected User Decisions

- Require an explicit user decision before materially changing platform support,
  boot or disk policy, login or authentication, firewall or network privacy,
  destructive data lifecycle behavior, or another boundary reserved below.
- Require an explicit user decision before intentionally revising a tradeoff among
  privacy, manual control, background activity, portability, simplicity, or service
  ownership. Routine implementation of an existing decision does not require
  another confirmation.
- Do not edit the following firewall and network-privacy surfaces, including comments,
  formatting, cleanup, or refactors, unless the user explicitly names the path or
  unambiguously requests the specific security behavior:
  - `scripts/bootstrap.sh`: `setup_basic_firewall`,
    `setup_trusted_network_profiles`, `setup_networkmanager_privacy`, and
    `setup_basic_network_privacy`.
  - `config/system/NetworkManager/conf.d/99-privacy.conf`.
  - `config/system/systemd/resolved.conf.d/60-network-privacy.conf`.
  - Network-policy entries, including `DNSOverHTTPS`, in
    `config/system/firefox/policies/policies.json`.
  - Connection DNS, encrypted-DNS, firewall, and network-privacy sections in
    `docs/privacy-security.md`.
- Keep dm-crypt discard pass-through disabled for encrypted system volumes. Do not
  enable it as routine SSD optimization; require an explicit decision based on a
  demonstrated performance or maintenance need.
- Require an explicit decision before changing automatic low-battery thresholds or
  their suspend, hibernate, or power-off results. Automatic low-battery power-off
  must use system-scoped batteries, show a grace period, re-check immediately before
  acting, cancel when the trigger clears, and remain inert without system battery
  hardware.
- Add or remove OS packages, persistent system services, or long-running user
  services only when the requested capability clearly requires it. Report the owner,
  lifecycle, network and data impact, hardware behavior, and practical alternative.

## Deployment and Machine State

- The checked-out repository is canonical. `~/.dotfiles` is a derived deployment
  copy when deployment runs from another path, and deployed home/config entries are
  symlinks into that copy.
- Treat `config/system/` as canonical source material for its bootstrap task. Files
  installed under `/etc`, `/usr/local/bin`, or `/usr/local/share` are derived state,
  not independent sources to edit.
- Edit canonical sources and redeploy through the owner. Direct changes to a derived
  copy, deployed symlink, or installed system copy do not complete a repository
  change and may be replaced later.
- Keep machine-owned state outside shared deployment. Preserve
  `~/.config/kanshi/local.conf` as the output-profile exception and keep identities,
  SSH hosts, VPN profiles, certificates, and other credential-bearing state outside
  the repository.
- A path under a derived deployment identifies the canonical source to edit; do not
  inspect or modify the derived path by default.
- Repository-only work may use already-installed tools for permitted static checks,
  but must not use installed or active machine state as evidence. Do not download,
  invoke package managers, create temporary environments, or run machine-state probes
  unless explicitly requested or required by an authorized verification.
- Distinguish `repository changed`, `deployed`, and `runtime verified` in reports.
  Never imply that repository changes are active without deployment evidence.
- Read `scripts/AGENTS.md` for deployment, backup, machine-owned state, and
  verification boundaries. Read `config/system/AGENTS.md` before changing material
  installed to system paths.

## Shell, Tooling, and Development Scope

- Follow the global shell quoting, naming, scoping, and command-construction rules.
- Bash is the sole maintained interactive and login shell. Do not add another shell
  support path without an explicit user decision.
- Arch owns OS-integrated tools and the shared container runtime; mise owns
  user-versioned tools; each project owns dependencies, runtime versions, build and
  test commands, container images, credentials, ports, volumes, and service lifecycle.
- Prefer stock OS capability, then a distro package, then a small upstream install.
  Prefer practical defaults over maximal customization, platform-native ownership
  for OS behavior, and portable, distro-neutral paths for user development tooling
  when practical.
- Prefer current upstream releases for user-owned tools and Neovim plugins, and
  distro-managed releases for OS packages, drivers, services, and desktop components.
  Pin only for a regression, compatibility boundary, or reviewed constraint, with a
  comment explaining why and when to reconsider it.
- Do not introduce lockfiles, generated version churn, or broad dependency pinning
  without a demonstrated need.
- Treat each new AUR recipe, upstream installer, release-binary source, and Flatpak
  remote as a supply-chain decision. Prefer reviewed sources and supported integrity
  verification; require an explicit decision before adding a new source or bypassing
  available verification.
- Keep development local: source checkout, editor, language tools, build, test,
  development server, and browser run locally by default. Git remotes, SSH
  authentication, repository-provider integrations, VPN and network-privacy controls,
  and GUI-less, clipboard, network-filesystem, and graceful-degradation guards are
  compatibility capabilities, not evidence of a maintained remote workflow.
- Do not add speculative remote-workstation guidance or integration. If execution
  must live remotely, create `docs/remote-development.md`, add it to the ownership
  table, and let it own connection, locality, authentication, editor and toolchain
  placement, forwarding, persistence, verification, and environment-specific
  security. Shared workflow documents should link to it and retain only common local
  entry points and compatibility fallbacks.
- Read `config/bash/AGENTS.md` for Bash startup, aliases, shared tool ownership,
  update sources, remote compatibility, and SSH-agent rules. Read
  `scripts/AGENTS.md` when the same change affects bootstrap ownership.

## Interaction and Desktop Design

- Reduce working-memory load with stable entry points, semantic grouping, and
  recognition. Design interactions by semantic family, frequency, physical
  ergonomics, and established conventions; check the complete interaction surface
  for collisions, symmetry, and genuine cross-tool consistency.
- Keep frequent, low-risk actions direct. Put infrequent, destructive, broad, or
  stateful actions behind an explicit command, mode, preview, or confirmation
  proportional to impact.
- Prefer visible state over hidden modes. Give toggles a stable default, immediate
  feedback, and an obvious inspection, exit, or recovery path. Favor reversible
  operations and make changed and unchanged state clear.
- Keep routine automation fast, narrow, deterministic, local, and owned by the
  component with enough context. Preserve user intent and existing state; keep
  broader cleanup and transformation explicit and reviewable through the owning
  workflow's preview, diagnostics, or diff.
- Minimize interruption and choice overload. Avoid competing providers, duplicate
  routine paths, redundant notifications, and permanently visible controls without
  a current purpose; reveal advanced operations on demand.
- Keep the desktop quiet and privacy-minimal: disable bells and automatic banners
  by default, retain useful passive indicators and user-invoked detail, and avoid
  SSIDs, addresses, device aliases, page titles, document titles, and window titles
  on always-visible surfaces.
- Use the Paper palette for maintained desktop UI. Prefer clear borders over white
  cards used only for separation, reserve solid accents for meaningful state, and
  require an explicit color-system decision before changing tokens or semantics in
  `docs/color_system.md`. Changing or removing a consumer does not authorize a
  palette change.
- Prefer readable size, strong contrast, normal weight, and compact sufficient
  padding over decorative effects, unnecessary bold, or extra spacing.
- Trace each desktop setting to its actual consumer. A configuration write or
  available schema alone does not prove behavior; use the owning compositor,
  session service, system service, toolkit, or application as appropriate.
- Ensure graphical-session commands resolve without relying on interactive-shell
  `PATH`. Expose user-tool-manager shims or supported executable paths deliberately.
- Protect occasional long-running tasks with a user-invoked command-scoped inhibitor
  rather than weakening baseline lock or suspend policy.
- Do not maintain parallel desktop environments after a replacement is verified;
  remove the superseded implementation after migration.
- Read `config/sway/AGENTS.md` before changing Sway keybindings, modes, feedback,
  session automation or state, Sway visual design, or workflow documentation, even
  when the implementation file is outside `config/`.
- Read `config/systemd/AGENTS.md` for Sway-session user services.
- Preserve the root protected-user-decision rules for network privacy, destructive
  data lifecycle, service ownership, authentication, and power behavior.

## Comments and Local Structure

- Preserve existing `{{{ / }}}` fold markers in long configuration and scripts.
- Name closing markers for large folded sections only when it improves navigation;
  keep ordinary function closing markers simple.
- After changing code or configuration, review nearby comments for stale, redundant,
  mechanical, or newly inaccurate wording. Update or remove only what is needed to
  explain non-obvious current intent; avoid comment-only churn.
- When intentionally deviating from local conventions or repository defaults, add a
  concise comment explaining why.

## Component-Specific Policy

- `.agents/AGENTS.md` owns repository-local Codex skill scope and validation.
- `config/bash/AGENTS.md` owns Bash startup, aliases, shared tooling, and SSH-agent
  behavior.
- `config/Code/AGENTS.md` owns VS Code and local extension policy.
- `config/nvim/AGENTS.md` owns Neovim structure, scope, persistence exceptions, and
  focused validation.
- `config/sway/AGENTS.md` owns Sway-specific interaction, session state, visual
  design, behavior, and validation.
- `config/system/AGENTS.md` owns canonical system configuration installed by
  bootstrap.
- `config/systemd/AGENTS.md` owns Sway-session user-unit lifecycle and validation.
- `config/tmux/AGENTS.md` owns tmux keys, memory state, and workflow synchronization.
- `docs/AGENTS.md` owns maintained-document content and structure.
- `scripts/AGENTS.md` owns setup failure handling, deployment boundaries, and script
  verification.

## Verification

- Use focused, concise static checks with already-installed tools and avoid verbose
  exploration. When runtime validation is necessary, run the smallest targeted,
  non-mutating check.
- Do not create temporary test environments, install or download dependencies, run
  package managers, start containers, or run broad integration suites unless
  explicitly requested or necessary for authorized validation.
- Never run deployment or bootstrap scripts as verification.
- Do not run a validator that may initialize missing plugins, dependencies, or
  network state automatically; report the unmet prerequisite.
- Treat `.pre-commit-config.yaml` as the canonical hook list. Scope rewriting hooks
  to reviewed files when practical and inspect their changes.
- Validate changed XML with `xmllint --noout` when available.
- Classify environment-dependent checks as passed, failed, environment unmet, result
  invalid, or skipped. A missing display, socket, user manager, permission, hardware,
  or similar prerequisite is no evidence of configuration success or failure.
- Treat static, deployment, and runtime verification as separate evidence. After an
  explicitly requested deployment, compare the relevant target with its canonical
  source and report anything not checked. Static checks do not prove that bootstrap
  succeeded on a real system.
- Run `git diff --check` for every change. Report the exact checks run or skipped and
  any system, desktop, hardware, reboot, deployment, or runtime behavior left
  unverified.

## Long-Running Work and Handoff

- Use an owning issue or PR as durable handoff for multi-session migrations or
  hardware-dependent validation when one exists. Do not treat chat-only state as
  durable evidence.
- If unfinished work has no durable handoff, report the gap and ask the user to choose
  one rather than inventing a tracking document.
- Record branch and commit, environment class, completed gates, skipped or invalid
  results, remaining risks, and the next user decision. Keep generic acceptance
  criteria in maintained documentation rather than task history.
- On resume, confirm that the handoff belongs to the current task and reconcile it
  with the current branch, commit, worktree, gate results, and artifacts; report
  conflicts instead of trusting unsupported claims.

## Output and Git

- Do not use emoji in code, documentation, commits, or runtime output.
- Use the project's logging framework and standard levels such as `DEBUG`, `INFO`,
  `WARN`, and `ERROR` for structured logs. Prefer `INFO`, `WARN`, `ERROR`, and `DONE`
  labels in interactive scripts.
- Do not commit, amend, rebase, force-push, or push unless explicitly requested.
- Do not bypass hooks with `--no-verify`; fix the failure or report the blocker.
- Before committing, review status and diff, run relevant verification, and include
  only reviewed working-tree changes belonging to one clear intent.
- Use Conventional Commits with a concise lowercase `type: summary`; prefer `feat`,
  `fix`, `docs`, `refactor`, or `chore`.
