# Maintained Documentation Policy

- Documentation is private operational memory for the maintainer and future
  agents, not public-facing presentation or contributor onboarding. Record
  durable intent, ownership, safety boundaries, prerequisites, side effects,
  recovery knowledge, and user decision boundaries.
- Omit promotional context and invocations already obvious from the canonical
  implementation unless sequence, prerequisite, side effect, or fallback
  matters.
- Keep interfaces precise and rationale durable. Do not mirror internal
  function names, task order, implementation flags, or exact inventories unless
  users rely on them. Maintain each exact inventory in one canonical location.
- `README.md` is limited to installation, bootstrap, and recovery and may be
  edited only under the explicit authority defined by the root `AGENTS.md`.
- Keep the Neovim workflow contract inline in `config/nvim/init.lua`; do not
  create a separate Neovim workflow document unless the inline reference is no
  longer sufficient.
- When removing a maintained document, preserve every non-obvious ownership,
  safety, recovery, and decision boundary in the nearest implementation comment
  or root policy.
- After replacing or removing a platform, shell, tool, or workflow, review
  related documentation and comments for stale rationale and mechanical
  renames. Describe current ownership and support directly; retain historical
  wording only for an active constraint, fallback, or dormant mapping.
- No maintained workflow document owns shared shell commands or local
  development tooling. Follow `config/bash/AGENTS.md` for that surface.
- Do not add clone instructions, contributor onboarding, or multi-user
  abstractions unless explicitly requested.
- If remote execution becomes a maintained workflow, create
  `docs/remote-development.md`, add it to the root ownership table, and let it
  own connection, locality, authentication, editor and toolchain placement,
  forwarding, persistence, verification, and environment-specific security.
  Shared workflow documents should retain only common local entry points and
  compatibility fallbacks.
