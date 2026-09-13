# Maintained Documentation Policy

- Use the ownership table in the root `AGENTS.md`. Keep runtime mechanics in their
  implementation, procedures in their workflow, and durable rationale in contracts.
  Workflow explanations may cover shared commands where needed to complete that
  workflow; they must not become a second shell or development-tool reference.
- Change a contract only when its boundary, ownership, rationale, or change condition
  changes. Implementation refactors and renames alone do not require contract edits.
  `Locators` are navigation aids; update them only when they no longer lead to the
  owner, and do not turn them into exhaustive implementation inventories.
- Contract IDs are permanent. Do not renumber or reuse them; add an ID only for an
  independent durable boundary with no existing owner. Keep current decisions here,
  not change history or session handoffs.
- When a contract repeats an exact runtime value, name its canonical config key,
  command argument, or identifier and owning path. Change the implementation and
  contract together when that protected value changes; add a drift gate only after
  the same mechanically detectable mismatch recurs.
- Keep rationale out of workflow prose and implementation comments. A local comment
  may explain a hazard, invariant, or compatibility workaround needed to understand
  the code. Link to a contract when its boundary is needed for a user procedure.
- Document commands when their sequence, prerequisite, side effect, fallback, or
  recovery path is not evident at the point of use. Avoid repeating the same keymap
  as several equivalent walkthroughs.
- README edits remain subject to root authorization. Keep the Neovim workflow in
  `config/nvim/init.lua`; do not create a separate workflow owner incidentally.
