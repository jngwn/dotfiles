# AGENTS.md

## Repository Scope

This repository manages personal dotfiles and OS bootstrap scripts.

- Arch Linux + Sway/Wayland bootstrap: `scripts/setup_arch_bootstrap.sh`
- Dotfile deployment: `scripts/setup_dotfiles.sh`
- Neovim config: `config/nvim/init.lua`

## Audience

- This is a personal-use repository maintained for one user.
- Assume the maintainer already has access to the repository. Do not add clone instructions, contributor onboarding, or multi-user abstractions unless explicitly requested.
- Keep `README.md` focused on installation and bootstrap. Keep desktop operation and keybinding workflows in `docs/sway-workflow.md`; do not update README unless explicitly requested.
- If a requested behavior change would make `README.md` inaccurate and README editing was not explicitly requested, leave it unchanged and report the exact stale section, changed behavior, and required follow-up.

## Documentation Ownership

Implementation and configuration files remain the source of truth for runtime behavior. The maintained workflow documents own the user-facing contract for operating that behavior. Before changing a listed area, read its maintained document; when an authorized behavior change makes that document inaccurate, update it in the same change. Keep the `README.md` exception above and do not copy full implementation rules into this index.

| Change area | Canonical implementation or contract | Maintained document |
| --- | --- | --- |
| tmux keys and session behavior | `config/tmux/tmux.conf` | `docs/tmux-workflow.md` |
| Sway desktop behavior, services, and system integration | `config/sway/`, `config/systemd/user/`, `config/system/`, `scripts/setup_arch_bootstrap.sh` | `docs/sway-workflow.md` |
| Shared Paper palette semantics and intentional tool-specific mappings | `docs/color_system.md` | `docs/color_system.md` |

### Shell and Local Development Boundary

- No maintained workflow document exists for shared shell commands or local development tooling. When changing this area, review `config/mise/config.toml`, `config/bash/aliases.sh`, `home/.bashrc`, and `scripts/setup_arch_bootstrap.sh` together.
- Preserve their ownership split: Arch owns OS-integrated tools and the shared container runtime, mise owns user-versioned tools, and each project owns its dependencies, runtime version, build and test commands, container images, credentials, ports, volumes, and service lifecycle.

## Documentation Stability

- Update maintained documentation when a user-facing command, supported input, prerequisite, owner, side effect, constraint, decision boundary, or recovery path changes.
- Do not mirror internal function names, task ordering, tool inventories, or implementation flags unless users must rely on those details.
- Keep interfaces and operational contracts precise. Generalize rationale and ownership around durable intent.
- Maintain each exact inventory in one canonical location. Other documents should describe its role and link to that owner.
- When removing a maintained document, preserve every non-obvious ownership, safety, recovery, and decision boundary in the nearest implementation comment or in this policy, so a fresh agent session can reconstruct the same intent without relying on prior chat context.

## Policy Files

- `AGENTS.md` governs this repository.
- `home/.codex/AGENTS.md` is deployed as global Codex policy.
- Change either file only when the user explicitly requests the corresponding repository or global policy change.
- Do not edit policy files incidentally during ordinary dotfile, bootstrap, or documentation work.
- After an authorized policy change, review the complete policy diff for weakened constraints, conflicting authority, and broader permissions.

## Platform Support

- Arch Linux + Sway on Wayland is the sole maintained deployment, desktop, and bootstrap target.
- The maintained Sway configuration must support both desktop and laptop hardware. Keep shared behavior independent of fixed output names, PCI addresses, batteries, backlights, and lid switches; isolate unavoidable machine-specific output profiles.
- Other operating systems and Linux distributions are not supported deployment targets. Do not add platform paths for them without an explicit user decision.

## Repository Inspection

- Treat hidden dotfiles and dot directories as in scope during repository inspection, excluding `.git/`.
- Treat dotfiles and configuration files as first-class repository content.
- Treat requests to understand, map, or become familiar with the repository as inspection-only tasks.
- For familiarization, inspect repository files, documentation, Git metadata, and static relationships only. Do not run tests, validators, headless applications, service checks, deployment comparisons, or runtime probes unless the user explicitly requests verification or diagnosis.
- The Verification section applies after authorized changes or when verification is explicitly requested; it does not require validation during repository familiarization.

## Editing Rules

- Treat analysis, diagnosis, review, and improvement proposals as read-only unless the user explicitly requests changes.
- Setup is run manually from the relevant script.
- Do not execute `scripts/setup_dotfiles.sh`, bootstrap scripts, or upgrade commands unless explicitly requested. Non-mutating inspection and static checks are allowed.
- Keep Arch Linux + Sway distro bootstrap behavior in `scripts/setup_arch_bootstrap.sh`.
- Keep dotfile deployment behavior centralized in `scripts/setup_dotfiles.sh`.
- Preserve user-owned changes and do not revert unrelated edits.
- Prefer small, explicit changes that match the existing style.
- Prefer editing existing files over creating new helpers.
- Avoid broad refactors, generated churn, and style-only rewrites.
- After replacing or removing a platform, shell, tool, or workflow, review the surrounding documentation and comments for stale rationale and mechanical renames. Describe the current owner and support scope directly; retain migration, compatibility, or historical wording only when it records an intentional current constraint, fallback, or dormant mapping.
- If you intentionally deviate from local conventions or repo defaults, add a short comment explaining why.

## Cognitive Ergonomics

- Reduce working-memory load through stable, recognizable entry points, semantic grouping, and concise documentation. Prefer recognition over isolated shortcuts that must be recalled without context.
- Preserve spatial and behavioral consistency when concepts genuinely match across tools. Do not force identical bindings or workflows when native conventions or different semantics would make the similarity misleading.
- Keep frequent, low-risk actions direct. Put infrequent, destructive, broad, or stateful actions behind an explicit command, mode, preview, or confirmation proportional to their impact.
- Prefer visible state over hidden modes. When a mode or toggle is justified, provide a stable default, immediate feedback when it changes, and an obvious way to inspect, exit, or recover from it.
- Keep automatic actions narrow, deterministic, and owned by the component with enough context. Routine automation should be fast, local, and preserve user intent and existing state; broader cleanup or state-changing transformations should remain explicit and be reviewed through the owning workflow's preview, diagnostics, or diff.
- Minimize interruption and choice overload. Avoid competing providers, duplicate paths for the same routine task, redundant notifications, and controls that are always visible without supporting the current task; reveal advanced operations when requested.
- Design keybindings by semantic family, usage frequency, physical ergonomics, and transfer from established conventions. Check the complete keymap for collisions and symmetry, and do not optimize isolated keystroke counts at the expense of predictability.
- Favor reversible operations and timely, proportionate feedback so the user can build an accurate mental model of what changed, what did not, and how to recover.

## User Decision Boundaries

- Require an explicit user decision before materially changing maintained platform support, boot or disk policy, login or authentication, firewall or network privacy, destructive data lifecycle behavior, or another boundary already reserved to the user in this file.
- Treat changes that alter the balance among privacy, manual control, background activity, portability, simplicity, or service ownership as policy decisions rather than routine improvements. If this file does not already make the preferred tradeoff explicit, stop at analysis and request a user decision before implementation.
- Keep dm-crypt discard pass-through disabled for encrypted system volumes to minimize exposure of encrypted block-use patterns. Do not enable it as routine SSD optimization; require an explicit user decision based on a demonstrated performance or maintenance need.
- Require an explicit user decision before changing automatic low-battery thresholds or their resulting suspend, hibernate, or power-off behavior. Automatic low-battery power-off must use system-scoped batteries, provide a visible grace period, re-check the trigger immediately before acting, cancel when the trigger clears, and remain inert when system battery hardware is absent.
- Do not add or remove OS packages, persistent system services, or long-running user services unless the requested capability clearly requires the change. When it does, report the owner, lifecycle, network and data impact, hardware behavior, and practical alternative.

## Deployment Ownership

- Treat the checked-out repository as the canonical source. When `scripts/setup_dotfiles.sh` runs from another path, `~/.dotfiles` is a derived deployment copy and home/config entries are symlinks into that copy.
- Keep dotfile deployment deliberately simple: replace the derived `~/.dotfiles` copy as a whole during each manual deployment, preserve the previous copy in the run-specific timestamped backup, and leave recovery to an explicit manual decision. Do not add manifests, staging, automatic pruning, or automatic rollback unless explicitly requested.
- Treat files under `config/system/` as canonical source material for the owning bootstrap task. Files installed into `/etc`, `/usr/local/bin`, or `/usr/local/share` are derived system state, not independent sources to edit in place.
- Update canonical repository files and redeploy through the owning script. When `~/.dotfiles` is a derived deployment copy rather than the checkout itself, direct edits there do not complete a repository change and may be replaced on the next deployment; the same applies to deployed home symlinks and installed system copies.
- Keep machine-owned state outside the shared deployment source. `~/.config/kanshi/local.conf` is the intentional output-profile exception and must survive replacement of `~/.dotfiles`.
- Keep identities, SSH hosts, VPN profiles, certificates, and other credential-bearing machine state outside the shared deployment source.
- Distinguish `repository changed`, `deployed`, and `runtime verified` in completion reports. Do not imply that a committed configuration is active on a machine without deployment evidence.

## Shell Code

- Follow the global shell naming, scoping, quoting, and command-construction rules.
- Bash is the sole maintained interactive and login shell. Keep its startup and alias files Bash-native; do not add compatibility paths for other shells.
- Executable scripts must follow their declared shebang. Do not source Bash startup or alias files from POSIX `sh`.
- Gate desktop-only behavior behind environment checks and preserve explicit fallback behavior for SSH shells that cannot access the local GUI session.
- Keep shell startup fast and quiet; do not add work that scales with the current repository or depends on a responsive network filesystem.
- Keep nested functions limited to helpers that are meaningful only during one parent operation; otherwise prefer an ordinary file-level helper.

## SSH Authentication

- Reuse one explicitly owned authentication agent per local session when practical, keep identity lifetimes bounded, and select identities per host or explicit user action.
- Do not bulk-load every private key, enable agent forwarding globally, or discover and terminate authentication agents outside the current workflow's ownership.

## Failure Handling

- Do not add blanket `set -e` behavior to the setup scripts; failures are classified and handled at the owning task boundary.
- Exit immediately for invalid invocation, unsupported platform, unsafe privilege context, or a missing prerequisite that prevents meaningful progress.
- Return nonzero for a required operation that did not complete. Callers must either stop, propagate the failure, or explicitly classify it as best-effort.
- For optional tools and integrations, emit `WARN`, preserve usable state, and continue when the remaining setup is still meaningful.
- Ignore an exit status with `|| true` only when that failure is expected and the surrounding code or comment makes the reason clear.
- Keep diagnostic commands read-only, and do not suppress their errors when the output is needed to decide a state-changing action.

## Comments

- Preserve existing `{{{ / }}}` fold markers in long configuration and script files.
- For large folded sections, name closing markers when it improves navigation.
- Keep ordinary function closing markers simple unless a name materially improves readability.

## Neovim

- Keep Neovim configuration as a single-file SSOT in `config/nvim/init.lua`.
- Preserve the existing `{{{ / }}}` fold structure.
- Do not split the Neovim config into modules unless explicitly requested.

## Sway

- Keep the shared Sway compositor configuration in `config/sway/config` as its SSOT.
- Prefer native Wayland paths for maintained desktop applications and services. Keep XWayland as a compatibility boundary for applications that still require X11.
- Manage session services with clear Sway/systemd user-session ownership so reloads do not create duplicate processes and logout does not leave desktop services running.
- Keep user-facing key bindings synchronized with the Sway workflow documentation.
- Do not encode machine-specific output identifiers in the shared Sway config. Put reviewed per-machine output layouts in the dedicated output-profile configuration.

## Desktop Philosophy

- Keep recurring desktop network activity opt-in and user-initiated. Do not enable telemetry, analytics, crash uploads, automatic update polling, geolocation, cloud synchronization, or similar background requests unless explicitly requested or required for requested functionality.
- When recurring outbound access is justified, document its purpose, transmitted data, cadence, and disable path. Prefer established manual update and maintenance workflows over duplicate background checkers.
- Preserve the reviewed firewall and network privacy policy. If a demonstrated critical security or operability issue conflicts with it, stop at diagnosis, report the impact and practical alternatives, and require an explicit user decision before changing the policy.
- Minimize persistent desktop metadata. Before adding history, cache, or state, identify what is stored, where it is stored, how long it is retained, and how it is cleared; prefer session-scoped state when persistence provides no clear benefit.
- Treat minimizing locally persisted records of user activity as a primary privacy goal. Do not add a persistent activity history or index merely for convenience; prefer user-invoked lookup or session-scoped state, and preserve only explicitly maintained workflow state with a documented lifetime and clear path.
- Treat the configured Neovim ShaDa, persistent undo, and cursor views as an explicit productivity exception to activity-record minimization. Keep this state user-owned under Neovim's state directory, do not expand its categories or expire it automatically, and require an explicit user decision before changing its persistence.
- For sensitive state that is intended to end with the graphical session, prefer `XDG_RUNTIME_DIR` when practical and enforce the boundary at both session start and shutdown; normal-logout cleanup alone is insufficient because interrupted sessions can leave state behind.
- Do not automatically delete user data, trash, browser state, credentials, or broad development caches without an explicit request.
- Prefer a quiet, non-interrupting desktop: keep audible and visual bells and automatic notification banners disabled by default. Retain passive status indicators and user-invoked controls where useful, and interrupt only for an explicit workflow or safety requirement.
- Keep always-visible desktop surfaces privacy-minimal. Show operational state without SSIDs, network addresses, device aliases, or page, document, and window titles when user-invoked detail provides the same function.
- Use the Paper palette as the default surface for maintained desktop UI. Prefer clear borders over introducing white cards solely for separation, and reserve solid accent fills for selection, focus, urgency, and other meaningful states.
- Treat the maintained color system as an independent design and compatibility layer. Removing a language, tool, plugin, extension, UI component, or workflow must not modify its palette token, color value, syntax highlight group, semantic-token mapping, ANSI mapping, theme contribution, reviewed alternative, comment, or mapping metadata, and must not add dormant, unused, legacy, or compatibility annotations. Behavioral activation references may change when their owning behavior changes, but mapping definitions may be changed or pruned only when the user explicitly requests a color-system change.
- Keep routine interface text at normal weight with compact, sufficient padding. Improve readability first through strong foreground contrast, readable sizing, and removal of visual effects; use bold text or extra spacing only for semantic emphasis or interaction needs.
- Do not add a package or long-running service when an established manual workflow adequately covers the need. For each new daemon, identify its owner, lifecycle, network activity, persistent data, and desktop/laptop behavior.
- Protect occasional long-running tasks with a user-invoked, command-scoped inhibitor instead of weakening the baseline lock or suspend policy globally.
- Do not maintain parallel desktop-environment implementations after a replacement is verified. Treat coexistence as a temporary migration state and remove the superseded implementation once the replacement is complete.

## Desktop Configuration Ownership

- Trace each setting to the component that actually consumes it; successful configuration writes alone do not prove that the maintained desktop behavior changed.
- Ensure commands launched by Sway, systemd user units, desktop entries, and MIME handlers resolve from the non-interactive graphical session environment. Do not treat availability in an interactive shell as proof; when a user tool manager owns a command, expose its supported executable path or shims to the session deliberately.
- Treat GSettings schema availability as insufficient evidence that a setting affects Sway. Use GLib or GTK settings for applications that consume them, and use Sway, systemd-logind, swayidle, or the relevant native owner for compositor, input, power, and session behavior.

## Preferences

- Prefer practical defaults over maximal customization.
- Prefer stock OS capability, then distro package, then small upstream install.
- When changing bootstrap or system setup behavior, first decide whether the behavior is OS-owned or user-owned.
- For OS-owned behavior, prefer the target platform's native tools, services, packages, and desktop conventions after inspecting the current script and, when needed, checking current upstream documentation.
- For user-owned development workflows, prefer portable, distro-neutral behavior when practical, and isolate unavoidable distro-specific handling behind the relevant bootstrap script.
- Prefer good readability and strong contrast over softer, trendier visuals.

## Version Policy

- Prefer current upstream releases for user-owned development tools and Neovim plugins over exact bootstrap reproducibility.
- Prefer distro-managed versions for OS-owned packages, drivers, services, and desktop components.
- Pin a version or revision when an upstream regression, compatibility boundary, or reviewed operational constraint requires it; add a concise comment stating why and when the pin can be reconsidered.
- Do not introduce lockfiles, generated version churn, or broad dependency pinning without a demonstrated need.
- Treat each new AUR recipe, upstream installer, release-binary source, and Flatpak remote as a supply-chain trust decision. Prefer existing reviewed sources, use supported integrity verification when available, and require an explicit user decision before introducing a new source or bypassing available verification.

## Development Environment Scope

- Keep the maintained development workflow focused on a local source checkout, local editors and language tooling, and locally executed build, test, development-server, and browser workflows.
- Treat Git remotes, SSH authentication, repository-provider integrations, VPN use, network privacy controls, and safe shell fallback during an SSH session as independent capabilities. Their presence alone does not make remote development a maintained workflow.
- Do not treat the absence of `docs/remote-development.md` or the local-first documentation scope as grounds to remove or simplify existing remote-aware portability guards, SSH-session fallbacks, GUI-less behavior, tmux clipboard fallback, network-filesystem safeguards, or graceful degradation in editor and language tooling. These are maintained compatibility contracts; change them only for a concrete defect, an authorized behavior change, or an explicit user request.
- Do not distribute speculative remote-workstation procedures across the VS Code, shell, tmux, or Neovim workflow documents, and do not add a remote editor integration to the common baseline without a concrete remote development requirement.
- When an actual workflow requires the source checkout, editor backend, build, test, or development server to live on a remote host, create `docs/remote-development.md` and add it to Documentation Ownership before documenting or implementing the shared workflow. This includes VS Code Remote SSH, a browser or cloud workstation, and SSH with a remote terminal editor.
- The remote development document must own connection prerequisites, source and data locality, authentication and access boundaries, editor and extension placement, remote toolchain ownership, port forwarding, session persistence and reconnection, verification, and environment-specific security requirements. Existing workflow documents should retain only their shared local entry points and compatibility fallback, then link to that document instead of duplicating its procedure.

## Output Style

- Do not use emoji in code, documentation, commits, or runtime output.
- For application, CI, test, and structured logs, use the project's logging framework and standard log levels such as `DEBUG`, `INFO`, `WARN`, and `ERROR`.
- For interactive scripts, prefer plain text status labels such as `INFO`, `WARN`, `ERROR`, and `DONE`.

## Verification

- Prefer static validation and short checks using tools already installed on
  the local system.
- Do not create temporary test environments, install or download dependencies,
  invoke package managers, start containers, or run broad integration suites
  unless the user explicitly requests them or they are necessary to validate
  the requested change.
- When runtime validation is necessary, run the smallest targeted,
  non-mutating check for the changed component.
- Do not run deployment or bootstrap scripts as verification.
- Avoid verbose exploratory output. Use focused commands and report the
  relevant result, skipped checks, and remaining runtime risk.
- If a validator could initialize missing plugins, dependencies, or network
  state, do not use it automatically; report the unmet prerequisite instead.
- Treat `.pre-commit-config.yaml` as the canonical hook list.
- Some hooks rewrite files. Scope them to reviewed files when practical and inspect the resulting diff before reporting completion.
- Run `bash -n` for changed Bash startup, alias, and script files.
- For shell scripts, prefer `shellcheck` and `shfmt -d` when available.
- For Neovim config changes, run a headless load check when practical.
- On an Arch Sway environment, validate `config/sway/config` with `WLR_BACKENDS=headless WLR_RENDERER=pixman WLR_LIBINPUT_NO_DEVICES=1 sway -C -c config/sway/config`.
- On a systemd user environment, validate changed units with `systemd-analyze --user --man=no --generators=no verify` and the relevant files under `config/systemd/user/`.
- Validate changed XML configuration with `xmllint --noout` when available.
- Classify environment-dependent checks as passed, failed, environment unmet, result invalid, or skipped. If a validator cannot start because required display, socket, user manager, permission, hardware, or similar environment prerequisites are unavailable, treat that as no evidence of configuration success or failure and report the unmet prerequisite.
- Treat deployment and runtime checks as separate from static checks. After an explicitly requested deployment, verify the relevant symlink or installed target against its canonical source and report any target that was not checked.
- Run `git diff --check` for every change.
- Report the exact checks run, checks not run, and any system, desktop, hardware, or reboot-dependent behavior that remains unverified.
- Static checks do not prove that the bootstrap completed on a real system.

## Long-Running Work and Handoff

- For multi-session migrations or hardware-dependent validation, use the owning issue or PR as the persistent handoff location when one exists; do not treat chat-only state as durable evidence.
- If unfinished multi-session work has no durable handoff location, report that gap and ask the user to choose one instead of inventing a new tracking document or silently relying on conversation history.
- Record the branch and commit, machine or environment class, completed gates, skipped or invalid results, remaining risks, and the next user decision. Keep generic acceptance criteria in the maintained documentation instead of copying task history into it.
- When resuming work, confirm that the handoff belongs to the current task and reconcile its status with the current branch, commit, working tree, gate results, and artifacts. Report conflicts instead of adopting a completion claim that is not supported by the current repository evidence.

## Git Workflow

- Do not commit, amend, rebase, force-push, or push unless explicitly requested.
- Review `git status` and `git diff` before committing.
- Run the relevant verification commands before committing.
- Prefer one commit per clear intent.
- Use Conventional Commits: `type: summary`.
- Prefer `feat`, `fix`, `docs`, `refactor`, or `chore`.
- Keep commit subjects concise, focused, and lowercase after the colon.
- Do not mix unrelated changes in one commit.
- Keep commits focused on reviewed working-tree changes only.
