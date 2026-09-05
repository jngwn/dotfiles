# Repository Skill Policy

- Keep repository-local Codex skills under `.agents/skills/`. Do not place caches,
  session state, credentials, or machine-specific agent configuration in this
  tracked subtree.
- Before creating or changing a skill, consult current official OpenAI documentation
  and use the `skill-creator` skill. Keep each skill focused on a demonstrated
  repository workflow and avoid restating rules already owned by the root or
  component `AGENTS.md` files.
- Add scripts, references, assets, or UI metadata only when the skill's actual
  workflow needs them. Do not create placeholder resources.
- Validate a changed skill with the `skill-creator` validator when available. Treat a
  missing validator as an environment-unmet check, inspect all new untracked skill
  files explicitly, and always run `git diff --check`.
