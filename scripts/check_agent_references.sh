#!/usr/bin/env bash

main() {
  local script_dir
  local repo_root
  local -r contract_file="docs/contracts.md"
  local -a policy_files=()
  local -a contract_reference_files=()
  local reference
  local contract_id
  local contract_schema_errors=""
  local locator
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

  if [[ ! -f "${contract_file}" ]]; then
    echo "ERROR: Repository contract registry is missing: ${contract_file}" >&2
    return 1
  fi

  contract_schema_errors="$(
    awk '
      function validate_entry(    i, field) {
        if (contract_id == "") {
          return
        }
        for (i = 1; i <= required_count; i++) {
          field = required[i]
          if (!(field in seen)) {
            print contract_id ": missing " field
          }
        }
      }

      BEGIN {
        required[++required_count] = "Name"
        required[++required_count] = "Locators"
        required[++required_count] = "Why"
        required[++required_count] = "Boundary"
        required[++required_count] = "Change condition"
      }

      /^## [A-Z]+-[0-9][0-9][0-9]$/ {
        validate_entry()
        delete seen
        contract_id = $2
        next
      }

      contract_id != "" && /^\*\*(Name|Locators|Why|Boundary|Change condition):\*\*/ {
        field = $0
        sub(/^\*\*/, "", field)
        sub(/:\*\*.*/, "", field)
        if (seen[field]++) {
          print contract_id ": duplicate " field
        }
      }

      END {
        validate_entry()
      }
    ' "${contract_file}"
  )"
  if [[ -n "${contract_schema_errors}" ]]; then
    echo "ERROR: Invalid repository contract schema:" >&2
    printf '%s\n' "${contract_schema_errors}" >&2
    failed=true
  fi

  while IFS= read -r locator; do
    locator="${locator#\`}"
    locator="${locator%\`}"
    case "${locator}" in
      */* | *.md)
        if [[ ! -e "${locator}" ]]; then
          echo "ERROR: Missing repository contract locator: ${locator}" >&2
          failed=true
        fi
        ;;
    esac
  done < <(
    awk '
      /^\*\*Locators:\*\*/ { in_locators = 1 }
      in_locators { print }
      in_locators && /^$/ { in_locators = 0 }
    ' "${contract_file}" |
      rg --no-filename --only-matching '`[^`]+`' |
      sort -u
  )

  mapfile -t contract_reference_files < <(rg --files -uu -g '!.git/**' | sort)

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

  while IFS= read -r contract_id; do
    contract_id="${contract_id#\`}"
    contract_id="${contract_id%\`}"
    if ! rg --quiet --line-regexp --fixed-strings "## ${contract_id}" "${contract_file}"; then
      echo "ERROR: Missing repository contract: ${contract_id}" >&2
      failed=true
    fi
  done < <(
    rg --no-filename --only-matching '`[A-Z]+-[0-9]{3}`' "${contract_reference_files[@]}" |
      sort -u
  )

  local duplicate_contract_ids=""
  duplicate_contract_ids="$(
    sed -n 's/^## \([A-Z][A-Z]*-[0-9][0-9][0-9]\)$/\1/p' "${contract_file}" |
      sort |
      uniq -d
  )"
  if [[ -n "${duplicate_contract_ids}" ]]; then
    echo "ERROR: Duplicate repository contract IDs:" >&2
    printf '%s\n' "${duplicate_contract_ids}" >&2
    failed=true
  fi

  if [[ "${failed}" == "true" ]]; then
    return 1
  fi

  echo "DONE: Agent policy references are valid."
}

main "$@"
