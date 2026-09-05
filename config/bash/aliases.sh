# ~/.config/bash/aliases.sh
# ----------------------------------------------------------
# Bash aliases and functions for the maintained interactive shell.
# This is not POSIX sh; do not source it from dash/sh.

_join_by() {
  local delimiter="${1}"
  shift

  local first=true
  local item
  for item in "${@}"; do
    if [ "${first}" = true ]; then
      printf "%s" "${item}"
      first=false
    else
      printf "%s%s" "${delimiter}" "${item}"
    fi
  done
}

_is_remote_shell() {
  [ -n "${SSH_CONNECTION:-}" ] || [ -n "${SSH_TTY:-}" ]
}

_absolute_path() {
  local target_path="${1}"

  if command -v realpath >/dev/null 2>&1; then
    command realpath -- "${target_path}"
    return
  fi

  local target_dir
  target_dir="$(dirname "${target_path}")" || return
  local target_name
  target_name="$(basename "${target_path}")" || return
  target_dir="$(cd "${target_dir}" && pwd -P)" || return
  printf "%s/%s\n" "${target_dir}" "${target_name}"
}

_copy_text_to_clipboard() {
  if _is_remote_shell; then
    echo "ERROR: Clipboard copy is disabled in remote shells." >&2
    return 1
  fi

  if [[ -n "${WAYLAND_DISPLAY:-}" ]] && command -v wl-copy >/dev/null 2>&1; then
    wl-copy --trim-newline --type text/plain
  else
    echo "ERROR: wl-copy is unavailable in the Wayland session." >&2
    return 1
  fi
}

_path_to_uri() {
  local target_path="${1}"

  if ! command -v gio >/dev/null 2>&1; then
    echo "ERROR: gio is required to copy files as clipboard objects." >&2
    return 1
  fi

  LC_ALL=C gio info -- "${target_path}" 2>/dev/null | sed -n 's/^uri: //p'
}

_reset_shell_names() {
  local name
  for name in "${@}"; do
    unalias "${name}" 2>/dev/null || true
    unset -f "${name}" 2>/dev/null || true
  done
}

# mat2 can occasionally leave the terminal's TTY state modified after it exits,
# causing typed characters to become invisible because terminal echo is disabled.
# Preserve the current TTY state for every mat2 invocation and restore it afterward.
mat2() {
  local tty_state
  tty_state="$(stty -g 2>/dev/null)"

  command mat2 "$@"
  local status=$?

  [[ -n "$tty_state" ]] && stty "$tty_state" 2>/dev/null

  return "$status"
}

if command -v nvim >/dev/null 2>&1; then
  export VISUAL="nvim"
else
  export VISUAL="vim"
fi
export EDITOR="${VISUAL}"
export GIT_EDITOR="${VISUAL}"
export FCEDIT="${VISUAL}"
unalias v vi vim vimdiff 2>/dev/null || true
v() { command "${VISUAL}" "${@}"; }
vi() { command "${VISUAL}" "${@}"; }
vim() { command "${VISUAL}" "${@}"; }
vimdiff() { command "${VISUAL}" -d "${@}"; }

_reset_shell_names cpath cfile ccont
cpath() {
  local -a target_paths=("${@}")
  if [[ ${#target_paths[@]} -eq 0 ]]; then
    target_paths=(.)
  fi

  local -a absolute_paths=()
  local target_path
  for target_path in "${target_paths[@]}"; do
    if [[ ! -e "${target_path}" && ! -L "${target_path}" ]]; then
      echo "ERROR: Path does not exist: ${target_path}" >&2
      return 1
    fi

    absolute_paths+=("$(_absolute_path "${target_path}")") || return
  done

  _join_by $'\n' "${absolute_paths[@]}" | _copy_text_to_clipboard
}

cfile() {
  if [[ $# -eq 0 ]]; then
    echo "Usage: cfile <file-or-directory> [...]" >&2
    return 1
  fi

  if _is_remote_shell; then
    echo "ERROR: File clipboard copy is disabled in remote shells." >&2
    return 1
  fi

  local -a file_uris=()
  local target_path
  local file_uri=""
  for target_path in "${@}"; do
    if [[ ! -e "${target_path}" && ! -L "${target_path}" ]]; then
      echo "ERROR: Path does not exist: ${target_path}" >&2
      return 1
    fi

    file_uri="$(_path_to_uri "${target_path}")" || return
    if [[ -z "${file_uri}" ]]; then
      echo "ERROR: Could not create a file URI for: ${target_path}" >&2
      return 1
    fi
    file_uris+=("${file_uri}")
  done

  local clipboard_data="copy"$'\n'
  clipboard_data+="$(_join_by $'\n' "${file_uris[@]}")"

  if [[ -n "${WAYLAND_DISPLAY:-}" ]] && command -v wl-copy >/dev/null 2>&1; then
    printf "%s" "${clipboard_data}" | wl-copy --type x-special/gnome-copied-files
  else
    echo "ERROR: cfile requires wl-copy in the Wayland session." >&2
    return 1
  fi
}

ccont() {
  if [[ $# -ne 1 ]]; then
    echo "Usage: ccont <file>" >&2
    return 1
  fi

  local target_file="${1}"
  if [[ ! -f "${target_file}" ]]; then
    echo "ERROR: File does not exist or is not a regular file: ${target_file}" >&2
    return 1
  fi

  if _is_remote_shell; then
    echo "ERROR: File content clipboard copy is disabled in remote shells." >&2
    return 1
  fi

  if [[ -n "${WAYLAND_DISPLAY:-}" ]] && command -v wl-copy >/dev/null 2>&1; then
    wl-copy <"${target_file}"
  else
    echo "ERROR: wl-copy is unavailable in the Wayland session." >&2
    return 1
  fi
}

_tmux_auto_attach() {
  local session_name="${1}"
  if command -v tmux >/dev/null 2>&1 &&
    [ -n "${PS1}" ] && [ -z "${TMUX}" ] &&
    [[ ! "${TERM}" =~ screen ]] && [[ ! "${TERM}" =~ tmux ]] &&
    [[ ! "${TERM_PROGRAM}" =~ vscode ]]; then
    tmux -L main -f ~/.config/tmux/tmux.conf new-session -AD -s "${session_name}"
  fi
}
ajrtm() { _tmux_auto_attach "main"; }
ajrtm1() { _tmux_auto_attach "main1"; }
ajrtm2() { _tmux_auto_attach "main2"; }
ajrtm3() { _tmux_auto_attach "main3"; }
ajrtm4() { _tmux_auto_attach "main4"; }
ajrtm5() { _tmux_auto_attach "main5"; }

alias cp='cp -iv'
alias cp1='cp --force --no-preserve=all --recursive --verbose'

_reset_shell_names yayss yaysi yayqi
if command -v pacman >/dev/null 2>&1; then
  alias pacss='pacman -Ss' # Search repository packages.
  alias pacsi='pacman -Si' # Show repository package details.
  alias pacqi='pacman -Qi' # Show installed package details.

  if command -v yay >/dev/null 2>&1; then
    alias yayss='yay -Ss' # Search repository and AUR packages.
    alias yaysi='yay -Si' # Show repository or AUR package details.
    alias yayqi='yay -Qi' # Show installed package details.
  fi

  if ! _is_remote_shell; then
    bubo() {
      echo "INFO: Checking pacman updates..."
      if command -v checkupdates >/dev/null 2>&1; then
        checkupdates || true
      else
        pacman -Qu
      fi

      if command -v yay >/dev/null 2>&1; then
        echo ""
        echo "INFO: Checking AUR updates..."
        yay -Qua || true
      fi

      if command -v flatpak >/dev/null 2>&1; then
        echo ""
        echo "INFO: Checking Flatpak updates..."
        flatpak remote-ls --updates || true
      fi
    }

    bubc() {
      # Keep Arch updates as a full-system transaction. AUR and Flatpak updates
      # run after pacman so repo packages, kernels, and desktop libraries settle first.
      sudo pacman -Syu || return

      if command -v yay >/dev/null 2>&1; then
        yay -Sua --devel || return
      fi

      if command -v flatpak >/dev/null 2>&1; then
        flatpak update -y || return
      fi
    }

    bubu() {
      bubo && bubc
    }
  fi

  pacq() {
    # List installed packages, or filter the installed package list by name.
    if [ "${#}" -eq 0 ]; then
      pacman -Q
    elif command -v rg >/dev/null 2>&1; then
      pacman -Q | rg --ignore-case --fixed-strings "${*}"
    else
      pacman -Q | grep -i --fixed-strings "${*}"
    fi
  }
fi

_reset_shell_names f
if _is_remote_shell; then
  function f { echo "WARN: File opener is disabled in remote shells." >&2; }
else
  f() {
    if command -v gio >/dev/null 2>&1; then
      # xdg-open uses its generic launcher under Sway and may keep the target
      # application in the foreground; GIO launches the same MIME default.
      # Detach standard streams so GUI diagnostics cannot overwrite a later prompt.
      command gio open "${@}" </dev/null >/dev/null 2>&1
      return
    fi

    if ! command -v xdg-open >/dev/null 2>&1; then
      echo "ERROR: No supported desktop file opener is available." >&2
      return 1
    fi

    # Keep the fallback launcher independent of the calling shell's job table.
    (command xdg-open "${@}" </dev/null >/dev/null 2>&1 &)
  }
fi

_reset_shell_names yz
yz() {
  local cwd_file cwd status
  cwd_file="$(mktemp -t 'yazi-cwd.XXXXXX')" || return

  # A child process cannot change Bash's directory, so Yazi writes its exit directory here.
  command yazi "$@" --cwd-file="${cwd_file}"
  status=$?

  if IFS= read -r -d '' cwd <"${cwd_file}" && [[ "${cwd}" != "${PWD}" && -d "${cwd}" ]]; then
    if ! builtin cd -- "${cwd}"; then
      echo "ERROR: Could not change to Yazi exit directory: ${cwd}" >&2
      status=1
    fi
  fi

  command rm -f -- "${cwd_file}"
  return "${status}"
}

alias g='git'
alias gs='git status'
alias gd='git diff'
alias gds='git diff --stat'
alias gdc='git diff --cached'
alias gdcs='git diff --cached --stat'

alias ga='git add --verbose'
alias gaa='git add --verbose --all'
alias gc='git commit --verbose'
alias gcm='git commit --verbose --message'
alias gca='git commit --verbose --all'

alias gb='git branch --verbose'
alias gsw='git switch'
alias gswc='git switch -c'
alias gco='git checkout'
alias gcob='git checkout -b'

alias grs='git restore'
alias grss='git restore --staged'

alias gf='git fetch --verbose'
alias gl='git pull --verbose'
alias gp='git push --verbose'
alias gr='git remote --verbose'

alias gm='git merge --verbose'
alias grb='git rebase --verbose'
alias gcp='git cherry-pick'
alias gst='git stash'
alias gstp='git stash pop'

alias gdt='git difftool'
alias gdts='git difftool --staged'
alias gmt='git mergetool'
alias gma='git merge --abort'
alias gmc='git merge --continue'
alias grba='git rebase --abort'
alias grbc='git rebase --continue'
alias grbs='git rebase --skip'
alias gcpa='git cherry-pick --abort'
alias gcpc='git cherry-pick --continue'

alias gg="git log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(green)(%ar)%C(reset) %C(black)%s%C(reset) %C(dim white)- %an%C(reset)%C(bold yellow)%d%C(reset)' --all"
alias glp="git log --pretty=format:'%C(bold blue)%h%C(reset) %C(green)%ad%C(reset) %C(black)%s%C(reset) %C(dim white)%an%C(reset)' --date=short"
alias ggrep="git log --all --grep" # Search commit messages

alias ggs="gg -n 10"
alias glps="glp -n 10"

# Keep management commands on the named server owned by _tmux_auto_attach so
# they address the same sessions even when invoked outside tmux.
alias tmls='tmux -L main list-sessions'
alias tmat='tmux -L main attach-session -t'
alias tmdt='tmux -L main detach-client'
alias tmkl='tmux -L main kill-session'

alias bashrc='test -f ~/.bashrc && vim ~/.bashrc || echo "WARN: File does not exist."'
alish() {
  local -r xdg_config_home="${XDG_CONFIG_HOME:-${HOME}/.config}"
  local -r aliases_file="${xdg_config_home}/bash/aliases.sh"

  if [[ -f "${aliases_file}" ]]; then
    vim "${aliases_file}"
  else
    echo "WARN: File does not exist."
  fi
}
alias dotfiles='test -d ~/.dotfiles && cd ~/.dotfiles || echo "WARN: Directory does not exist."'
alias xsh='exec /usr/bin/bash -l'

_reload_sway_session_config() {
  local -r user_manager_ready="${1:-false}"
  local failed=false

  if [[ -n "${SWAYSOCK:-}" && "${user_manager_ready}" == "true" ]]; then
    if systemctl --user is-active --quiet waybar.service; then
      echo "INFO: Reloading Waybar..."
      if ! systemctl --user kill --kill-who=main --signal=SIGUSR2 waybar.service; then
        echo "ERROR: Failed to reload Waybar."
        failed=true
      fi
    fi

    if systemctl --user is-active --quiet swaync.service && command -v swaync-client >/dev/null 2>&1; then
      echo "INFO: Reloading Sway Notification Center..."
      if ! swaync-client --reload-config || ! swaync-client --reload-css; then
        echo "ERROR: Failed to reload Sway Notification Center."
        failed=true
      fi
    fi

    # Kanshi has no reload protocol, so restart only the active instance.
    if systemctl --user is-active --quiet kanshi.service; then
      echo "INFO: Reloading Kanshi output profiles..."
      if ! systemctl --user restart kanshi.service; then
        echo "ERROR: Failed to reload Kanshi output profiles."
        failed=true
      fi
    fi
  fi

  if [[ -n "${SWAYSOCK:-}" ]] && command -v swaymsg >/dev/null 2>&1; then
    echo "INFO: Reloading Sway compositor..."
    if ! swaymsg reload; then
      echo "ERROR: Failed to reload the Sway compositor."
      failed=true
    fi
  fi

  [[ "${failed}" == "false" ]]
}

_reload_shared_interactive_config() {
  local failed=false
  local -r xdg_config_home="${XDG_CONFIG_HOME:-${HOME}/.config}"

  if [[ -n "${TMUX:-}" ]] && command -v tmux >/dev/null 2>&1; then
    echo "INFO: Reloading Tmux configuration..."
    if ! tmux source-file "${xdg_config_home}/tmux/tmux.conf"; then
      echo "ERROR: Failed to reload the Tmux configuration."
      failed=true
    fi
  fi

  if [[ -f "${xdg_config_home}/bash/aliases.sh" ]]; then
    echo "INFO: Sourcing Bash aliases..."
    # shellcheck disable=SC1090
    if ! source "${xdg_config_home}/bash/aliases.sh"; then
      echo "ERROR: Failed to source the Bash aliases."
      failed=true
    fi
  else
    echo "ERROR: Bash aliases file does not exist: ${xdg_config_home}/bash/aliases.sh"
    failed=true
  fi

  [[ "${failed}" == "false" ]]
}

reload_config() {
  # Reload only the deployed configuration visible to this session. Repository
  # edits require a manual deploy_dotfiles.sh run before this can apply them.
  local failed=false
  local user_manager_ready=false

  echo "INFO: Reloading active configurations..."

  # A degraded user manager is still reachable and must receive unit reloads.
  if command -v systemctl >/dev/null 2>&1 && systemctl --user show-environment >/dev/null 2>&1; then
    user_manager_ready=true
    echo "INFO: Reloading systemd user daemon..."
    if ! systemctl --user daemon-reload; then
      echo "ERROR: Failed to reload the systemd user daemon."
      failed=true
    fi
  fi

  _reload_sway_session_config "${user_manager_ready}" || failed=true
  _reload_shared_interactive_config || failed=true

  if [[ "${failed}" == "true" ]]; then
    echo "WARN: Reload completed with errors."
    return 1
  fi

  echo "DONE: Reload completed."
}
alias reloadall='reload_config'

sunset() {
  local -r action="${1:-status}"

  if (($# > 1)); then
    echo "ERROR: Usage: sunset {on|off|status}" >&2
    return 2
  fi

  if ! command -v systemctl >/dev/null 2>&1; then
    echo "ERROR: systemctl is required to control night color." >&2
    return 1
  fi

  if ! command systemctl --user show-environment >/dev/null 2>&1; then
    echo "ERROR: The systemd user manager is unavailable." >&2
    return 1
  fi

  # Keep this session-scoped; persistent enablement remains an explicit systemd decision.
  case "${action}" in
    on)
      echo "INFO: Starting night color..."
      if ! command systemctl --user start wlsunset.service; then
        echo "ERROR: Failed to start night color." >&2
        return 1
      fi
      echo "DONE: Night color started."
      ;;
    off)
      echo "INFO: Stopping night color..."
      if ! command systemctl --user stop wlsunset.service; then
        echo "ERROR: Failed to stop night color." >&2
        return 1
      fi
      echo "DONE: Night color stopped."
      ;;
    status)
      local state=""
      if ! state="$(command systemctl --user show wlsunset.service --property=ActiveState --value 2>/dev/null)"; then
        echo "ERROR: Failed to read the night color state." >&2
        return 1
      fi

      case "${state}" in
        active) echo "INFO: Night color is active." ;;
        inactive) echo "INFO: Night color is inactive." ;;
        failed)
          echo "WARN: Night color is in a failed state." >&2
          return 1
          ;;
        *) echo "INFO: Night color state: ${state}." ;;
      esac
      ;;
    *)
      echo "ERROR: Usage: sunset {on|off|status}" >&2
      return 2
      ;;
  esac
}

alias c='clear'
alias h='history | tail -n 20'

alias mv='mv -iv'
alias mkdir='mkdir -pv'
alias mat21='mat2 --inplace --verbose'
alias d='date "+%Y-%m-%d (%a) %H:%M:%S %Z"'

_reset_shell_names count_files
count_files() {
  local include_hidden=false
  local recursive=false
  local target="."
  local target_set=false
  local -a exclude_patterns=()

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -a | --all)
        include_hidden=true
        ;;
      -r | --recursive)
        recursive=true
        ;;
      -e | --exclude)
        if [[ $# -lt 2 || -z "$2" ]]; then
          echo "ERROR: --exclude requires a non-empty glob pattern." >&2
          return 2
        fi
        shift
        exclude_patterns+=("$1")
        ;;
      -h | --help)
        echo "Usage: count_files [-a|--all] [-r|--recursive] [-e|--exclude GLOB]... [directory]"
        return
        ;;
      --)
        shift
        if [[ $# -gt 1 || ($# -eq 1 && "${target_set}" == true) ]]; then
          echo "ERROR: count_files accepts only one directory." >&2
          return 2
        fi
        if [[ $# -eq 1 ]]; then
          target="$1"
          target_set=true
        fi
        break
        ;;
      -*)
        echo "ERROR: Unknown option: $1" >&2
        return 2
        ;;
      *)
        if [[ "${target_set}" == true ]]; then
          echo "ERROR: count_files accepts only one directory." >&2
          return 2
        fi
        target="$1"
        target_set=true
        ;;
    esac
    shift
  done

  if [[ ! -d "${target}" ]]; then
    echo "ERROR: Directory does not exist: ${target}" >&2
    return 1
  fi

  local -a file_filters=()
  if [[ "${include_hidden}" != true ]]; then
    file_filters+=("!" -name ".*")
  fi

  local pattern
  for pattern in "${exclude_patterns[@]}"; do
    file_filters+=("!" -name "${pattern}")
  done

  local -a find_args=(-H "${target}")
  if [[ "${recursive}" == true ]]; then
    local -a directory_exclusions=()
    if [[ "${include_hidden}" != true ]]; then
      directory_exclusions+=(-name ".*")
    fi
    for pattern in "${exclude_patterns[@]}"; do
      if [[ ${#directory_exclusions[@]} -gt 0 ]]; then
        directory_exclusions+=(-o)
      fi
      directory_exclusions+=(-name "${pattern}")
    done

    if [[ ${#directory_exclusions[@]} -gt 0 ]]; then
      find_args+=("(" -type d "!" -path "${target}" "(" "${directory_exclusions[@]}" ")" -prune ")" -o)
    fi
    find_args+=("(" -type f "${file_filters[@]}" -print0 ")")
  else
    find_args+=("!" -path "${target}" -prune -type f "${file_filters[@]}" -print0)
  fi

  local count
  count="$({
    set -o pipefail
    command find "${find_args[@]}" |
      LC_ALL=C command tr -cd '\000' |
      command wc -c
  })" || return

  count="${count//[[:space:]]/}"
  printf '%s\n' "${count}"
}

alias dl='cd ~/Downloads'
alias dc='cd ~/Documents'
tmp() { cd "${TMPDIR:-/tmp}" || return; }
alias vc='v ~/.dotfiles/config/nvim/init.lua'
alias vd='vimdiff'

_PROJECTS_HOME="${HOME}/Projects"
alias vdc='cd ${_PROJECTS_HOME}/personal/dotfiles/ && vimdiff ~/.dotfiles/config/nvim/init.lua config/nvim/init.lua'
alias vdb='cd ${_PROJECTS_HOME}/personal/dotfiles/ && vimdiff ~/.bashrc home/.bashrc'
alias vda='cd ${_PROJECTS_HOME}/personal/dotfiles/ && vimdiff ~/.dotfiles/config/bash/aliases.sh config/bash/aliases.sh'
alias p='cd ${_PROJECTS_HOME}'
alias per='cd ${_PROJECTS_HOME}/personal'
alias wk='cd ${_PROJECTS_HOME}/work'

_reset_shell_names _list_directory_after_cd
if ! _is_remote_shell; then
  _list_directory_after_cd() {
    ls -A
  }

  _reset_shell_names cd
  cd() {
    builtin cd "${@}" || return
    _list_directory_after_cd
  }
fi

mkcd() { command mkdir -p "${1}" && cd "${1}" || return; }
alias cd..='cd ../'
alias ..='cd ../'
alias ...='cd ../../'
alias .1='cd ../'
alias .2='cd ../../'
alias .3='cd ../../../'
alias .4='cd ../../../../'
alias .5='cd ../../../../../'
alias .6='cd ../../../../../../'

firmware_update() {
  if ! command -v fwupdmgr >/dev/null 2>&1; then
    echo "ERROR: fwupdmgr is not installed."
    return 1
  fi

  # Firmware deployment can require AC power and a reboot, so keep it separate
  # from routine package and user-tool upgrades.
  echo "INFO: Refreshing firmware metadata..."
  command fwupdmgr refresh || return

  echo ""
  echo "INFO: Installing available firmware updates..."
  command fwupdmgr update
}
alias fwup='firmware_update'

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

  if [[ -f /etc/arch-release ]]; then
    if [[ -x /usr/bin/journalctl ]]; then
      /usr/bin/journalctl --disk-usage 2>/dev/null || true
    fi
    if [[ -d /var/cache/pacman/pkg ]]; then
      command du -sh -- /var/cache/pacman/pkg 2>/dev/null || true
    fi
    echo "  - Arch package cache: keep the latest 3 versions"
  fi

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

  if command -v gio >/dev/null 2>&1; then
    if ! command gio trash --empty; then
      echo "WARN: Failed to empty the standard desktop trash."
      failed=true
    fi
  else
    echo "WARN: gio is unavailable; the standard desktop trash was not emptied."
    failed=true
  fi

  if ! command rm -f -- "${recent_file}"; then
    echo "WARN: Failed to remove GTK recent-file metadata."
    failed=true
  fi

  if [[ -L "${thumbnail_dir}" ]]; then
    echo "WARN: Refusing to clean a symlinked thumbnail directory: ${thumbnail_dir}"
    failed=true
  elif [[ -d "${thumbnail_dir}" ]] && ! command find "${thumbnail_dir}" -xdev -depth -mindepth 1 -delete; then
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

  # Root-owned cleanup uses fixed Arch paths so aliases or user-installed
  # wrappers cannot cross the privilege boundary.
  if [[ -f /etc/arch-release ]]; then
    if [[ ! -x /usr/bin/sudo ]]; then
      echo "WARN: sudo is required to clean system journals and the Pacman cache."
      failed=true
    else
      if [[ -x /usr/bin/journalctl ]]; then
        /usr/bin/sudo /usr/bin/journalctl --rotate --vacuum-time="${retention_period}" || {
          echo "WARN: Failed to remove system journal entries older than ${retention_label}."
          failed=true
        }
      fi

      if [[ -x /usr/bin/paccache ]]; then
        /usr/bin/sudo /usr/bin/paccache -r -k 3 || {
          echo "WARN: Failed to prune the Arch package cache."
          failed=true
        }
      else
        echo "WARN: paccache is unavailable; install pacman-contrib."
        failed=true
      fi
    fi
  fi

  if [[ "${failed}" == "true" ]]; then
    echo "WARN: Privacy cleanup completed with errors."
    return 1
  fi

  echo "WARN: Other open shells can write their in-memory history again when they exit."
  echo "DONE: Privacy cleanup completed."
}
alias pclean='privacy_cleanup'

update_npm_global_packages() {
  local npm_prefix=""

  if ! npm_prefix="$(npm prefix --global 2>/dev/null)"; then
    echo "WARN: Could not determine the npm global prefix. Skipping npm packages."
    return 1
  fi

  if [[ "${npm_prefix}" != /* || ! -d "${npm_prefix}" ]]; then
    echo "WARN: Refusing npm global update for an invalid prefix: ${npm_prefix:-<empty>}"
    return 1
  fi

  if [[ ! -w "${npm_prefix}" ]]; then
    echo "WARN: npm global prefix is not user-writable; skipping: ${npm_prefix}"
    return 0
  fi

  echo "INFO: Updating npm global packages..."
  npm update --global
}

update_uv_managed_tools() {
  local tools=""

  if ! tools="$(uv tool list 2>/dev/null)"; then
    echo "WARN: Could not inspect uv-managed tools."
    return 1
  fi

  if [[ -z "${tools}" ]]; then
    echo "INFO: No uv-managed tools installed."
    return 0
  fi

  echo "INFO: Updating uv-managed tools..."
  if ! uv tool upgrade --all; then
    echo "WARN: Failed to update uv-managed tools."
    return 1
  fi
}

upgrade_all_managers() {
  # Keep user-owned tool updates separate from Arch package and firmware updates.
  # Projects retain ownership of their pinned dependencies and runtime versions.
  if [[ "${EUID}" -eq 0 ]]; then
    echo "ERROR: upall must run as the owning user, not root."
    return 1
  fi

  local failed=false

  if command -v mise >/dev/null 2>&1; then
    echo "INFO: Updating mise-managed tools..."
    if ! mise upgrade --yes; then
      echo "WARN: Failed to update mise-managed tools."
      failed=true
    elif ! mise prune --yes; then
      echo "WARN: Failed to prune unused mise-managed tool versions."
      failed=true
    fi
  fi

  if command -v uv >/dev/null 2>&1; then
    if ! update_uv_managed_tools; then
      failed=true
    fi
  fi

  if command -v npm >/dev/null 2>&1; then
    if ! update_npm_global_packages; then
      failed=true
    fi
  fi

  if [[ "${failed}" == true ]]; then
    echo "WARN: User tool updates completed with errors."
    return 1
  fi

  echo "DONE: User tool updates completed."
}
alias upall='upgrade_all_managers'

precommit_update_hooks() {
  if ! command -v pre-commit >/dev/null 2>&1; then
    echo "ERROR: pre-commit is not installed."
    return 1
  fi

  if [ ! -f .pre-commit-config.yaml ]; then
    echo "ERROR: .pre-commit-config.yaml not found in current directory."
    return 1
  fi

  # This intentionally updates the repository hook revisions and can rewrite
  # tracked files, so leave final scope review to the caller's Git diff.
  pre-commit autoupdate || return
  pre-commit run --all-files || return
  git diff --stat
}
alias pcup='precommit_update_hooks'

_common_excludes=(
  .git node_modules dist build .next .cache .turbo .vite coverage target __pycache__ .venv
  .mypy_cache .pytest_cache .ruff_cache .idea .gradle
)

# Keep CLI file colors aligned with the light Paper palette. Default ls colors
# can look fluorescent on the warm background, especially with bright ANSI colors.
export LS_COLORS="di=01;34:ln=36:ex=32:ow=01;34:tw=01;34:*.sh=31:*.bash=31:*.rs=33:*.c=34:*.h=36:*.cc=34:*.cpp=34:*.java=31:*.json=36:*.toml=33:*.yaml=33:*.yml=33:*.zip=31:*.7z=31:*.tar=31:*.gz=31"

_reset_shell_names tree lt lt1 lt2 lt3 ltsrc ltd ltl
if command -v tree >/dev/null; then
  _tree_exclude="$(_join_by '|' "${_common_excludes[@]}")"
  tree() { command tree -a -I "${_tree_exclude}" "${@}"; }
  alias lt='tree'
  lt1() { command tree -L 1 -a -I "${_tree_exclude}" "${@}"; }
  lt2() { command tree -L 2 -a -I "${_tree_exclude}" "${@}"; }
  lt3() { command tree -L 3 -a -I "${_tree_exclude}" "${@}"; }
  ltsrc() { command tree src -a -I "${_tree_exclude}" "${@}"; }
  ltd() { command tree -d -a -I "${_tree_exclude}" "${@}"; }
  ltl() {
    local level="${1:-2}"
    command tree -L "${level}" -a -I "${_tree_exclude}" "${@:2}"
  }
fi

_reset_shell_names ff ffs ffe ff-s ffs-s ffe-s fdf fdf-ext fdf-s fdd fdd-s
unset _fd_exclude_args _find_base_args _find_prune_args

if command -v fd >/dev/null 2>&1; then
  _fd_exclude_args=()
  for _exclude in "${_common_excludes[@]}"; do _fd_exclude_args+=("--exclude" "${_exclude}"); done

  ff() { command fd --color=auto --ignore-case --hidden "${_fd_exclude_args[@]}" "${@}"; }
  ffs() { command fd --color=auto --ignore-case --hidden "${_fd_exclude_args[@]}" "^${*}"; }
  ffe() { command fd --color=auto --ignore-case --hidden "${_fd_exclude_args[@]}" "${*}$"; }
  ff-s() { command fd --color=auto --case-sensitive --hidden "${_fd_exclude_args[@]}" "${@}"; }
  ffs-s() { command fd --color=auto --case-sensitive --hidden "${_fd_exclude_args[@]}" "^${*}"; }
  ffe-s() { command fd --color=auto --case-sensitive --hidden "${_fd_exclude_args[@]}" "${*}$"; }

  fdf() { command fd --color=auto --ignore-case --hidden --type f "${_fd_exclude_args[@]}" "${@}"; }
  fdf-s() { command fd --color=auto --case-sensitive --hidden --type f "${_fd_exclude_args[@]}" "${@}"; }
  fdd() { command fd --color=auto --ignore-case --hidden --type d "${_fd_exclude_args[@]}" "${@}"; }
  fdd-s() { command fd --color=auto --case-sensitive --hidden --type d "${_fd_exclude_args[@]}" "${@}"; }
  fdf-ext() {
    if [[ $# -ne 1 || -z "${1}" ]]; then
      echo "ERROR: Usage: fdf-ext EXT" >&2
      return 2
    fi

    local extension="${1#.}"
    command fd --color=auto --ignore-case --hidden --type f "${_fd_exclude_args[@]}" --extension "${extension}"
  }
else
  _find_base_args=(. -ignore_readdir_race -mindepth 1)
  _find_prune_args=()
  for _exclude in "${_common_excludes[@]}"; do _find_prune_args+=("-path" "*/${_exclude}" "-prune" "-o"); done

  ff() { command find "${_find_base_args[@]}" "${_find_prune_args[@]}" -iname "*${*}*" -print; }
  ffs() { command find "${_find_base_args[@]}" "${_find_prune_args[@]}" -iname "${*}*" -print; }
  ffe() { command find "${_find_base_args[@]}" "${_find_prune_args[@]}" -iname "*${*}" -print; }
  ff-s() { command find "${_find_base_args[@]}" "${_find_prune_args[@]}" -name "*${*}*" -print; }
  ffs-s() { command find "${_find_base_args[@]}" "${_find_prune_args[@]}" -name "${*}*" -print; }
  ffe-s() { command find "${_find_base_args[@]}" "${_find_prune_args[@]}" -name "*${*}" -print; }

  fdf() { command find "${_find_base_args[@]}" "${_find_prune_args[@]}" -type f -iname "*${*}*" -print; }
  fdf-s() { command find "${_find_base_args[@]}" "${_find_prune_args[@]}" -type f -name "*${*}*" -print; }
  fdd() { command find "${_find_base_args[@]}" "${_find_prune_args[@]}" -type d -iname "*${*}*" -print; }
  fdd-s() { command find "${_find_base_args[@]}" "${_find_prune_args[@]}" -type d -name "*${*}*" -print; }
  fdf-ext() {
    if [[ $# -ne 1 || -z "${1}" ]]; then
      echo "ERROR: Usage: fdf-ext EXT" >&2
      return 2
    fi

    local extension="${1#.}"
    command find "${_find_base_args[@]}" "${_find_prune_args[@]}" -type f -iname "*.${extension}" -print
  }
fi

if command -v rg >/dev/null 2>&1; then
  _rg_exclude_args=()
  for _exclude in "${_common_excludes[@]}"; do _rg_exclude_args+=("-g" "!${_exclude}/**"); done

  rgp() { rg --column --line-number --no-heading --smart-case --hidden --follow "${_rg_exclude_args[@]}" --color 'always' --fixed-strings "${@}"; }
  rgp-s() { rg --column --line-number --no-heading --case-sensitive --hidden --follow "${_rg_exclude_args[@]}" --color 'always' --fixed-strings "${@}"; }
  rgr() { rg --column --line-number --no-heading --smart-case --hidden --follow "${_rg_exclude_args[@]}" --color 'always' --regexp "${@}"; }
  rgr-s() { rg --column --line-number --no-heading --case-sensitive --hidden --follow "${_rg_exclude_args[@]}" --color 'always' --regexp "${@}"; }
else
  _grep_exclude_args=(--binary-files=without-match)
  for _exclude in "${_common_excludes[@]}"; do _grep_exclude_args+=("--exclude-dir=${_exclude}"); done

  rgp() { command grep --recursive --line-number --color=always --ignore-case "${_grep_exclude_args[@]}" --fixed-strings "${@}"; }
  rgp-s() { command grep --recursive --line-number --color=always "${_grep_exclude_args[@]}" --fixed-strings "${@}"; }
  rgr() { command grep --recursive --line-number --color=always --ignore-case "${_grep_exclude_args[@]}" --extended-regexp "${@}"; }
  rgr-s() { command grep --recursive --line-number --color=always "${_grep_exclude_args[@]}" --extended-regexp "${@}"; }
fi

unalias ls lsa ll 2>/dev/null || true
alias ls='ls -AF --color=auto'
alias ll='ls -AFhlp --color=auto'
alias lsa='ls -al --color=auto'

del() {
  if [[ $# -eq 0 ]]; then
    echo "ERROR: Please specify a file or directory to delete."
    return 1
  fi

  if ! command -v gio >/dev/null 2>&1; then
    echo "ERROR: gio is required to move files to the desktop trash."
    return 1
  fi

  command gio trash -- "${@}"
}

empty-trash() {
  echo -n "WARN: Empty the trash permanently? (y/n): "
  local answer=""
  read -r answer

  if [[ "$answer" == "y" || "$answer" == "Y" ]]; then
    if ! command -v gio >/dev/null 2>&1; then
      echo "ERROR: gio is required to empty the desktop trash."
      return 1
    fi
    if command gio trash --empty; then
      echo "DONE: The desktop trash has been permanently emptied."
    else
      echo "ERROR: Failed to empty the desktop trash."
      return 1
    fi
  else
    echo "INFO: Operation canceled."
  fi
}

zipf() {
  for file in "${@}"; do
    zip -r "${file}".zip "${file}"
  done
}

djszip() {
  for file in "${@}"; do
    unzip -O cp949 "${file}" -d "${file%%.zip}"
  done
}

_reset_shell_names djs7z clfz clfzp clfzcp clfzpcp
if command -v 7zz &>/dev/null; then
  _seven_zip_command="7zz"

elif command -v 7z &>/dev/null; then
  _seven_zip_command="7z"
else
  _seven_zip_command=""
fi

if [ -n "${_seven_zip_command}" ]; then
  djs7z() {
    local password
    printf "%s" "Password: "
    read -rs password
    echo

    for file in "${@}"; do
      "${_seven_zip_command}" x "${file}" -p"${password}"
    done
  }

  clfz() {
    for file in "${@}"; do
      "${_seven_zip_command}" a -t7z -m0=lzma2 -mx=0 -mfb=64 -md=32m -ms=on "${file}".7z "${file}"
    done
  }

  clfzp() {
    local password
    printf "%s" "Password: "
    read -rs password
    echo

    for file in "${@}"; do
      "${_seven_zip_command}" a -t7z -m0=lzma2 -mx=0 -mfb=64 -md=32m -ms=on -mhe=on -p"${password}" "${file}".7z "${file}"
    done
  }

  clfzcp() {
    for file in "${@}"; do
      "${_seven_zip_command}" a -t7z -m0=copy "${file}".7z "${file}"
    done
  }

  clfzpcp() {
    local password
    printf "%s" "Password: "
    read -rs password
    echo

    for file in "${@}"; do
      "${_seven_zip_command}" a -t7z -m0=copy -mhe=on -p"${password}" "${file}".7z "${file}"
    done
  }
fi

dirdiff() {
  if [ "$#" -lt 2 ]; then
    echo "Usage: dirdiff <directory1> <directory2> [diff_options]"
    return 1
  fi
  local dir1="${1}"
  shift
  local dir2="${1}"
  shift

  local args=("${_common_excludes[@]/#/--exclude=}")

  diff --brief --recursive "${args[@]}" "${dir1}" "${dir2}" "${@}"
}

sshload() {
  if [[ "${#}" -eq 0 ]]; then
    echo "Usage: sshload <private-key> [...]"
    return 1
  fi

  if ! command -v ssh-add >/dev/null 2>&1; then
    echo "ERROR: ssh-add is unavailable."
    return 1
  fi

  local agent_status=0
  command ssh-add -l >/dev/null 2>&1 || agent_status="${?}"

  # ssh-add returns 2 only when it cannot contact an authentication agent.
  if [[ "${agent_status}" -eq 2 ]]; then
    if ! command -v ssh-agent >/dev/null 2>&1; then
      echo "ERROR: ssh-agent is unavailable."
      return 1
    fi

    # No existing agent is reachable, so this shell owns the bounded fallback;
    # do not discover or terminate agents belonging to other sessions.
    unset SSH_AUTH_SOCK SSH_AGENT_PID
    eval "$(command ssh-agent -s -t 8h)" || return
    echo "INFO: Started new SSH agent (PID: ${SSH_AGENT_PID})."
  fi

  local success_count=0
  local failure_count=0
  local key

  for key in "${@}"; do
    if [[ -f "${key}" ]]; then
      if command ssh-add -t 8h "${key}"; then
        echo "DONE: Key '${key}' added successfully."
        ((success_count++))
      else
        echo "ERROR: Failed to add key '${key}'. Check passphrase or permissions."
        ((failure_count++))
      fi
    else
      echo "ERROR: Key file '${key}' does not exist."
      ((failure_count++))
    fi
  done

  echo ""
  echo "INFO: Currently loaded SSH keys:"
  command ssh-add -l
  echo ""
  echo "INFO: Summary: ${success_count} keys added successfully, ${failure_count} failures."
  [[ "${failure_count}" -eq 0 ]]
}

sshkill() {
  if [[ -n "${SSH_AGENT_PID:-}" ]] && kill -0 "${SSH_AGENT_PID}" 2>/dev/null; then
    eval "$(command ssh-agent -k)"
    echo "DONE: Stopped the current SSH agent."
    return
  fi

  if [[ -n "${SSH_AUTH_SOCK:-}" ]]; then
    command ssh-add -D || return
    echo "DONE: Removed all identities from the current SSH agent."
    return
  fi

  echo "INFO: No SSH agent is available."
}

keep_awake() {
  if [[ "${#}" -eq 0 ]]; then
    echo "Usage: keep_awake <command> [arguments...]"
    return 1
  fi

  if command -v systemd-inhibit >/dev/null 2>&1; then
    command systemd-inhibit \
      --what=sleep \
      --mode=block \
      --why="User-invoked long-running task" \
      "${@}"
    return
  fi

  echo "ERROR: systemd-inhibit is unavailable."
  return 1
}
