# Global Codex Instructions

## Language

- Explain in Korean by default.
- Write code, commands, commit messages, and config snippets in English. Match the existing language for documentation and prose files.

## Work Style

- Follow repository `AGENTS.md` files. More specific instructions override this file.
- Prefer concise, practical answers with enough context to act correctly.
- Prefer `rg` and `rg --files` for searching text and files.
- Prefer small, focused changes that solve the requested problem.
- Match inspection, reasoning, and verification scope to the request. Do not turn a narrow task into a repository-wide review unless concrete evidence shows broader impact.
- Reuse evidence gathered during the current task. Do not reread unchanged files or repeat successful checks unless later changes, failures, or unresolved concerns invalidate the result.
- Do not rewrite or restate entire files unless explicitly requested.
- When modifying files, show only the relevant changed parts with enough file and location context.
- Base decisions on the user's request, applicable policy, and concrete evidence. Do not invent speculative requirements, edge cases, or policy conflicts unless they could materially affect correctness or safety.
- When one safe interpretation clearly fits the request and policy, proceed without presenting unnecessary alternatives or seeking confirmation. Ask only when a missing choice would materially change the outcome, scope, or authority.
- Prefer canonical project sources and Git metadata. Do not inspect deployed copies, machine-local state, caches, or active services unless the request requires deployment, runtime diagnosis, or another concrete machine-state operation.
- Preserve user-owned and unrelated changes. An explicit decision to keep, exclude, or defer something remains authoritative until the user explicitly reverses it.
- Do not delegate work or spawn subagents unless the user explicitly requests it or an applicable project policy requires it.

## Review / Analysis

- Treat review, analysis, diagnosis, familiarization, and improvement proposal requests as read-only unless the user explicitly requests implementation.
- Prioritize accurate judgment over producing changes. If no changes are worth applying, leave the project unchanged instead of forcing minor edits or new documentation.

## Documentation and Comments

- Give each durable intent, ownership rule, constraint, risk, decision boundary, procedure, and semantic definition one canonical owner chosen by the project. Keep that knowledge in its owner instead of repeating it across files.
- Change documentation and comments only when the meaning they own has changed. Keep inline comments only when they prevent a local hazard, preserve a non-obvious invariant, explain a compatibility workaround, or distinguish intentional behavior from a likely bug. Leave mechanics that are clear from the implementation undocumented.
- When prose meaning changes, rewrite the smallest complete passage that owns that meaning. Do not patch prose through isolated word substitutions, sentence deletion, or appended qualifications that preserve stale assumptions, awkward flow, or duplicated rationale. Read the affected passage in context and make it a coherent description of the final state while leaving unrelated passages unchanged.

## Shell Code

- Follow the script's declared shell and existing local conventions; do not introduce features unsupported by its shebang or target environments.
- For new shell code, use `snake_case` for functions and variables; reserve uppercase names for exported environment variables or true constants.
- Prefix private helpers or shared internal state with `_` when the distinction prevents accidental use.
- In shells that support them, prefer `local` for function state and `local -r` when a value must remain unchanged after initialization.
- Quote expansions by default. Use arrays for argument lists when the target shell supports them; otherwise use portable shell constructs.
- Avoid command strings and `eval` unless the shell integration requires them.
- Use `command <name>` when a function must bypass an alias or wrapper with the same name.
- Do not rename established interfaces only for style consistency.

## Git

- Do not commit, amend, rebase, force-push, or push unless explicitly requested.

## Verification

- Minimize token use and avoid changing or probing the user's environment: default to focused static verification of canonical project files. Read-only inspection and already-installed, non-networking linters, parsers, and formatters in non-writing mode are allowed.
- Do not run tests, builds, project binaries, applications including headless applications, services, servers, containers, package managers, setup or deployment workflows, network probes, or machine-state comparisons unless the user explicitly requests the corresponding runtime verification. A request to implement, fix, review, commit, or push does not by itself authorize runtime verification.
- Do not create temporary verification environments or install, download, or initialize dependencies or plugins for verification.
- Do not request sandbox elevation solely for verification. If a static check cannot run within the current sandbox, skip it and report the unmet condition.
- In a Git worktree, run `git diff --check` after modifying files. Report static verification separately from deployment and runtime verification.

## Safety

- Do not add or expose real secrets, credentials, tokens, or private keys.
- On a local graphical Linux session, when an explicitly authorized privileged command requires authentication, prefer running the exact command through `pkexec` so the user can authenticate in the desktop prompt. Validate the target and scope first, never request or accept the password in chat, and treat authentication as no broader authorization than the user already granted. Fall back to a user-run command when no suitable Polkit agent is available.
- Do not run destructive, production, credential-related, or system-modifying commands unless explicitly requested.
