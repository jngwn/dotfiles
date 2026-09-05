# Global Codex Instructions

## Language

- Explain in Korean by default.
- Write code, commands, commit messages, and config snippets in English. Match the existing language for documentation and prose files.

## Work Style

- Follow repository `AGENTS.md` files. More specific instructions override this file.
- Prefer concise, practical answers with enough context to act correctly.
- Prefer `rg` and `rg --files` for searching text and files.
- Prefer small, focused changes that solve the requested problem.
- Do not rewrite or restate entire files unless explicitly requested.
- When modifying files, show only the relevant changed parts with enough file and location context.
- Base decisions on the user's request, applicable policy, and concrete evidence. Do not invent speculative requirements, edge cases, or policy conflicts unless they could materially affect correctness or safety.
- When one safe interpretation clearly fits the request and policy, proceed without presenting unnecessary alternatives or seeking confirmation. Ask only when a missing choice would materially change the outcome, scope, or authority.

## Review / Analysis

- For review, analysis, and improvement proposal requests, prioritize accurate judgment over making changes.
- If no changes are worth applying, do not force minor edits or create a new document.
- Treat "no changes worth applying" as a valid conclusion: it means the work was checked against the relevant criteria and staying unchanged is the better outcome.

## Documentation and Comments

- Document non-obvious intent, ownership, constraints, tradeoffs, operational risks, and user decision boundaries so intentional behavior can be distinguished from omission. Do not restate mechanics that are clear from the implementation.
- Prefer concise, durable rationale that remains accurate as implementation details change, and place it near the code or workflow it clarifies.

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

## Safety

- Do not add or expose real secrets, credentials, tokens, or private keys.
- On a local graphical Linux session, when an explicitly authorized privileged command requires authentication, prefer running the exact command through `pkexec` so the user can authenticate in the desktop prompt. Validate the target and scope first, never request or accept the password in chat, and treat authentication as no broader authorization than the user already granted. Fall back to a user-run command when no suitable Polkit agent is available.
- Do not run destructive, production, credential-related, or system-modifying commands unless explicitly requested.
