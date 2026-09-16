_platform_move_to_trash() {
  if ! command -v gio >/dev/null 2>&1; then
    echo "ERROR: gio is required to move files to the desktop trash." >&2
    return 1
  fi

  command gio trash -- "${@}"
}

_platform_empty_trash() {
  if ! command -v gio >/dev/null 2>&1; then
    echo "ERROR: gio is required to empty the desktop trash." >&2
    return 1
  fi

  command gio trash --empty
}

_platform_keep_awake() {
  if ! command -v systemd-inhibit >/dev/null 2>&1; then
    echo "ERROR: systemd-inhibit is unavailable." >&2
    return 1
  fi

  command systemd-inhibit \
    --what=sleep \
    --mode=block \
    --why="User-invoked long-running task" \
    "${@}"
}

_reset_shell_names cp1 ls ll lsa
alias cp1='cp --force --no-preserve=all --recursive --verbose'
alias ls='ls -AF --color=auto'
alias ll='ls -AFhlp --color=auto'
alias lsa='ls -al --color=auto'

export LS_COLORS="di=01;34:ln=36:ex=32:ow=01;34:tw=01;34:*.sh=31:*.bash=31:*.rs=33:*.c=34:*.h=36:*.cc=34:*.cpp=34:*.java=31:*.json=36:*.toml=33:*.yaml=33:*.yml=33:*.zip=31:*.7z=31:*.tar=31:*.gz=31"

_reset_shell_names djszip
djszip() {
  if (($# == 0)); then
    echo "ERROR: Usage: djszip <zip-file> [...]" >&2
    return 2
  fi

  local file
  for file in "${@}"; do
    command unzip -O cp949 "${file}" -d "${file%%.zip}" || return
  done
}

_clear_shell_history() {
  if [[ -z "${HOME:-}" || "${HOME}" != /* ]]; then
    echo "WARN: Refusing to clear shell history with an invalid home path."
    return 1
  fi

  local -r xdg_state_home="${XDG_STATE_HOME:-${HOME}/.local/state}"
  local -r expected_history_file="${xdg_state_home}/bash/history"

  if [[ -n "${HISTFILE:-}" && "${HISTFILE}" != "${expected_history_file}" ]]; then
    echo "WARN: Refusing to remove a custom shell history file: ${HISTFILE}"
    return 1
  fi

  if [[ -L "${expected_history_file}" ]]; then
    echo "WARN: Refusing to remove a symlinked shell history file: ${expected_history_file}"
    return 1
  fi

  command rm -f -- "${expected_history_file}" || return
  builtin history -c || return
  HISTFILE="${expected_history_file}"
  builtin history -w "${HISTFILE}" || return
}

_clear_cliphist_history() {
  if ! command -v cliphist >/dev/null 2>&1; then
    return 0
  fi

  local failed=false
  if [[ -n "${XDG_RUNTIME_DIR:-}" && "${XDG_RUNTIME_DIR}" == /* ]]; then
    local -r session_db="${XDG_RUNTIME_DIR}/cliphist/db"
    if [[ -L "${session_db}" ]]; then
      echo "WARN: Refusing to clear a symlinked session clipboard database: ${session_db}"
      failed=true
    elif [[ -e "${session_db}" && (! -f "${session_db}" || ! -O "${session_db}") ]]; then
      echo "WARN: Refusing to clear an unexpected session clipboard database: ${session_db}"
      failed=true
    elif [[ -e "${session_db}" ]]; then
      if ! command chmod 600 "${session_db}" ||
        ! command cliphist -db-path "${session_db}" wipe; then
        echo "WARN: Failed to clear the session clipboard history."
        failed=true
      fi
    fi
  fi

  [[ "${failed}" == "false" ]]
}

_platform_privacy_cleanup_preview() {
  return 0
}

_platform_privacy_cleanup_system() {
  return 0
}

_reset_shell_names privacy_cleanup pclean
privacy_cleanup() {
  if [[ -z "${HOME:-}" || "${HOME}" != /* ]]; then
    echo "ERROR: Privacy cleanup requires an absolute home path."
    return 1
  fi

  local -r retention_period=1day
  local -r retention_label="1 day"
  local -r retention_minutes=1440
  local -r xdg_data_home="${XDG_DATA_HOME:-${HOME}/.local/share}"
  local -r xdg_state_home="${XDG_STATE_HOME:-${HOME}/.local/state}"
  local -r xdg_cache_home="${XDG_CACHE_HOME:-${HOME}/.cache}"
  local -r recent_file="${xdg_data_home}/recently-used.xbel"
  local -r thumbnail_dir="${xdg_cache_home}/thumbnails"
  local -r setup_log_dir="${xdg_state_home}/dotfiles/logs"
  local setup_log_count=0
  local standard_trash_count=0

  if [[ -d "${setup_log_dir}" && ! -L "${setup_log_dir}" ]]; then
    setup_log_count="$(
      command find "${setup_log_dir}" -xdev -type f \
        \( -name '*-deploy-dotfiles.log' -o -name '*-bootstrap.log' -o -name '*-setup-dotfiles.log' \) \
        -mmin "+${retention_minutes}" -print 2>/dev/null | awk 'END { print NR + 0 }'
    )"
  fi

  echo "INFO: Privacy cleanup targets:"
  echo "  - Clipboard history"
  echo "  - Bash command history"
  echo "  - GTK recent-file metadata"
  if command -v gio >/dev/null 2>&1; then
    standard_trash_count="$(command gio trash --list 2>/dev/null | awk 'END { print NR + 0 }')"
  fi
  echo "  - Standard desktop trash: ${standard_trash_count} item(s)"
  if [[ -d "${thumbnail_dir}" && ! -L "${thumbnail_dir}" ]]; then
    command du -sh -- "${thumbnail_dir}" 2>/dev/null || true
  else
    echo "  - Thumbnail cache: not present"
  fi
  echo "  - Setup logs older than ${retention_label}: ${setup_log_count} file(s)"
  _platform_privacy_cleanup_preview

  echo -n "WARN: Permanently clean these privacy records and caches? (y/n): "
  local answer=""
  read -r answer
  if [[ "${answer}" != "y" && "${answer}" != "Y" ]]; then
    echo "INFO: Operation canceled."
    return 0
  fi

  local failed=false

  if ! _clear_cliphist_history; then
    echo "WARN: Failed to clear clipboard history."
    failed=true
  fi

  if ! _clear_shell_history; then
    echo "WARN: Failed to clear shell command history."
    failed=true
  fi

  if ! _platform_empty_trash; then
    echo "WARN: Failed to empty the standard desktop trash."
    failed=true
  fi

  if ! command rm -f -- "${recent_file}"; then
    echo "WARN: Failed to remove GTK recent-file metadata."
    failed=true
  fi

  if [[ -L "${thumbnail_dir}" ]]; then
    echo "WARN: Refusing to clean a symlinked thumbnail directory: ${thumbnail_dir}"
    failed=true
  elif [[ -d "${thumbnail_dir}" ]] &&
    ! command find "${thumbnail_dir}" -xdev -depth -mindepth 1 -delete; then
    echo "WARN: Failed to clear the thumbnail cache."
    failed=true
  fi

  if [[ -L "${setup_log_dir}" ]]; then
    echo "WARN: Refusing to clean a symlinked setup log directory: ${setup_log_dir}"
    failed=true
  elif [[ -d "${setup_log_dir}" ]] && ! command find "${setup_log_dir}" -xdev -type f \
    \( -name '*-deploy-dotfiles.log' -o -name '*-bootstrap.log' -o -name '*-setup-dotfiles.log' \) \
    -mmin "+${retention_minutes}" -delete; then
    echo "WARN: Failed to remove setup logs older than ${retention_label}."
    failed=true
  fi

  _platform_privacy_cleanup_system "${retention_period}" "${retention_label}" || failed=true

  if [[ "${failed}" == "true" ]]; then
    echo "WARN: Privacy cleanup completed with errors."
    return 1
  fi

  echo "WARN: Other open shells can write their in-memory history again when they exit."
  echo "DONE: Privacy cleanup completed."
}
alias pclean='privacy_cleanup'
