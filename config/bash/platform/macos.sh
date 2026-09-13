_platform_move_to_trash() {
  if ! command -v osascript >/dev/null 2>&1; then
    echo "ERROR: osascript is required to move files to the Trash." >&2
    return 1
  fi

  local current_dir=""
  current_dir="$(builtin pwd -L)" || return

  local target
  local -a absolute_paths=()
  for target in "${@}"; do
    if [[ ! -e "${target}" && ! -L "${target}" ]]; then
      echo "ERROR: Path does not exist: ${target}" >&2
      return 1
    fi

    if [[ "${target}" == /* ]]; then
      absolute_paths+=("${target}")
    else
      # Preserve the selected directory entry so deleting a symlink does not
      # resolve it and send its target to Finder instead.
      absolute_paths+=("${current_dir}/${target}")
    fi
  done

  command osascript - "${absolute_paths[@]}" <<'APPLESCRIPT'
on run targetPaths
  tell application "Finder"
    repeat with targetPath in targetPaths
      delete (POSIX file (targetPath as text))
    end repeat
  end tell
end run
APPLESCRIPT
}

_platform_empty_trash() {
  if ! command -v osascript >/dev/null 2>&1; then
    echo "ERROR: osascript is required to empty the Trash." >&2
    return 1
  fi

  command osascript -e 'tell application "Finder" to empty trash'
}

_platform_keep_awake() {
  if ! command -v caffeinate >/dev/null 2>&1; then
    echo "ERROR: caffeinate is unavailable." >&2
    return 1
  fi

  command caffeinate -i "${@}"
}

_reset_shell_names cp1 ls ll lsa
alias cp1='cp -RfXv'
alias ls='ls -AFG'
alias ll='ls -AFhlpG'
alias lsa='ls -alG'
