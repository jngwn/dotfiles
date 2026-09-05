---
name: dotfiles-maintenance
description: Analyze and carry out cross-cutting maintenance in this personal Arch/Sway dotfiles repository. Use for repository-wide review or cleanup, ownership and maintained-contract reconciliation, or changes spanning multiple maintained areas; do not use for narrow single-file edits or generic project development.
---

# Dotfiles Maintenance

Turn broad dotfiles maintenance requests into small, repository-owned slices using
the judgment that is specific to cross-cutting maintenance.

## Evaluate improvement candidates

- Identify the canonical owner, maintained contract, concrete problem, affected
  user workflow, protected decision boundary, and required repository or runtime
  evidence for each candidate.
- Separate observed facts, interpretation, and recommendation.
- Prefer candidates that correct a safety or ownership violation, implementation and
  contract drift, a reproducible failure, or repeated maintenance friction. Do not
  manufacture style-only work.
- Split work at real ownership or verification boundaries. Do not impose a fixed
  number of phases, files, or commits.
- State `no changes worth applying` when the current repository already satisfies the
  relevant contract.

For a broad review, return a prioritized sequence. Make each proposed slice's
outcome, owner and maintained contract, value, decision boundary, repository
verification, and remaining deployment or runtime verification clear without
imposing a fixed response template.

Apply the root and closest component `AGENTS.md` for authorization, editing,
documentation, verification, deployment, and Git behavior. This skill adds no new
authority.
