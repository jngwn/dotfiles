#!/usr/bin/env bash

main() {
  local script_dir
  local repo_root
  local -a policy_files=()
  local reference
  local failed=false

  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" || {
    echo "ERROR: Unable to resolve the script directory." >&2
    return 1
  }
  repo_root="$(cd "${script_dir}/.." && pwd)" || {
    echo "ERROR: Unable to resolve the repository root." >&2
    return 1
  }
  cd "${repo_root}" || {
    echo "ERROR: Unable to enter the repository root: ${repo_root}" >&2
    return 1
  }

  if ! command -v rg >/dev/null 2>&1; then
    echo "ERROR: rg is required to check agent policy references." >&2
    return 1
  fi

  mapfile -t policy_files < <(rg --files -uu -g 'AGENTS.md' -g '!.git/**' | sort)
  if ((${#policy_files[@]} == 0)); then
    echo "ERROR: No AGENTS.md policy files were found." >&2
    return 1
  fi

  while IFS= read -r reference; do
    reference="${reference#\`}"
    reference="${reference%\`}"
    if [[ ! -e "${reference}" ]]; then
      echo "ERROR: Missing AGENTS.md reference: ${reference}" >&2
      failed=true
    fi
  done < <(
    rg --no-filename --only-matching '`[^`]+AGENTS\.md`' "${policy_files[@]}" |
      sort -u
  )

  if [[ "${failed}" == "true" ]]; then
    return 1
  fi

  echo "DONE: Agent policy references are valid."
}

main "$@"
