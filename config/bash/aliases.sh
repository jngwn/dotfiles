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

_is_wsl() {
  local os_release=""
  [[ -r /proc/sys/kernel/osrelease ]] || return 1
  IFS= read -r os_release </proc/sys/kernel/osrelease || return 1

  case "${os_release}" in
    *[Mm]icrosoft* | *[Ww][Ss][Ll]*) return 0 ;;
    *) return 1 ;;
  esac
}

_platform_open_path() {
  local -r opener="${HOME}/.local/bin/open-path"
  if [[ ! -x "${opener}" ]]; then
    echo "ERROR: Shared file opener is unavailable: ${opener}" >&2
    return 1
  fi

  command "${opener}" "${@}"
}

_platform_move_to_trash() {
  echo "ERROR: No supported desktop trash provider is available." >&2
  return 1
}

_platform_empty_trash() {
  echo "ERROR: No supported desktop trash provider is available." >&2
  return 1
}

_platform_keep_awake() {
  echo "ERROR: No supported sleep inhibitor is available." >&2
  return 1
}

_reset_shell_names() {
  local name
  for name in "${@}"; do
    unalias "${name}" 2>/dev/null || true
    unset -f "${name}" 2>/dev/null || true
  done
}

# Restore terminal echo if mat2 leaves the TTY state modified.
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

_reset_shell_names f
f() {
  _platform_open_path "${@}"
}

_reset_shell_names yz
yz() {
  local cwd_file cwd status
  cwd_file="$(mktemp "${TMPDIR:-/tmp}/yazi-cwd.XXXXXX")" || return

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
alias ggrep="git log --all --grep"

alias ggs="gg -n 10"
alias glps="glp -n 10"

alias tmls='tmux -L main list-sessions'
alias tmat='tmux -L main attach-session -t'
alias tmdt='tmux -L main detach-client'
alias tmkl='tmux -L main kill-session'

_reset_shell_names xsh
xsh() {
  local bash_path=""
  bash_path="$(command -v bash)" || {
    echo "ERROR: bash is unavailable." >&2
    return 1
  }

  exec "${bash_path}" -l
}

alias c='clear'
alias h='history | tail -n 20'

alias mv='mv -iv'
alias mkdir='mkdir -pv'
alias mat21='mat2 --inplace --verbose'
alias d='date "+%Y-%m-%d (%a) %H:%M:%S %Z"'

alias dl='cd ~/Downloads'
alias dc='cd ~/Documents'
tmp() { cd "${TMPDIR:-/tmp}" || return; }
alias vd='vimdiff'

_PROJECTS_HOME="${HOME}/Projects"
alias p='cd ${_PROJECTS_HOME}'
alias per='cd ${_PROJECTS_HOME}/personal'
alias wk='cd ${_PROJECTS_HOME}/work'

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

  # Autoupdate and hooks may rewrite tracked files; leave the resulting diff unstaged.
  pre-commit autoupdate || return
  pre-commit run --all-files || return
  git diff --stat
}
alias pcup='precommit_update_hooks'

_common_excludes=(
  .git node_modules dist build .next .cache .turbo .vite coverage target __pycache__ .venv
  .mypy_cache .pytest_cache .ruff_cache .idea .gradle
)

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
  _find_base_args=(. -mindepth 1)
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

del() {
  if [[ $# -eq 0 ]]; then
    echo "ERROR: Please specify a file or directory to delete."
    return 1
  fi

  _platform_move_to_trash "${@}"
}

empty-trash() {
  echo -n "WARN: Empty the trash permanently? (y/n): "
  local answer=""
  read -r answer

  if [[ "$answer" == "y" || "$answer" == "Y" ]]; then
    if _platform_empty_trash; then
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
  if (($# == 0)); then
    echo "ERROR: Usage: zipf <file-or-directory> [...]" >&2
    return 2
  fi

  local file
  for file in "${@}"; do
    command zip -r "${file}".zip "${file}" || return
  done
}

_reset_shell_names djs7z clfz clfzp clfzcp clfzpcp
_seven_zip_command="$(type -P 7zz 2>/dev/null || type -P 7z 2>/dev/null || true)"

if [ -n "${_seven_zip_command}" ]; then
  djs7z() {
    if (($# == 0)); then
      echo "ERROR: Usage: djs7z <archive> [...]" >&2
      return 2
    fi

    local file
    for file in "${@}"; do
      command "${_seven_zip_command}" x "${file}" || return
    done
  }

  clfz() {
    if (($# == 0)); then
      echo "ERROR: Usage: clfz <file-or-directory> [...]" >&2
      return 2
    fi

    local file
    for file in "${@}"; do
      command "${_seven_zip_command}" a -t7z -m0=lzma2 -mx=0 -mfb=64 -md=32m -ms=on "${file}".7z "${file}" || return
    done
  }

  clfzp() {
    if (($# == 0)); then
      echo "ERROR: Usage: clfzp <file-or-directory> [...]" >&2
      return 2
    fi

    local file
    for file in "${@}"; do
      command "${_seven_zip_command}" a -t7z -m0=lzma2 -mx=0 -mfb=64 -md=32m -ms=on -mhe=on -p "${file}".7z "${file}" || return
    done
  }

  clfzcp() {
    if (($# == 0)); then
      echo "ERROR: Usage: clfzcp <file-or-directory> [...]" >&2
      return 2
    fi

    local file
    for file in "${@}"; do
      command "${_seven_zip_command}" a -t7z -m0=copy "${file}".7z "${file}" || return
    done
  }

  clfzpcp() {
    if (($# == 0)); then
      echo "ERROR: Usage: clfzpcp <file-or-directory> [...]" >&2
      return 2
    fi

    local file
    for file in "${@}"; do
      command "${_seven_zip_command}" a -t7z -m0=copy -mhe=on -p "${file}".7z "${file}" || return
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

  local args=()
  local exclude
  for exclude in "${_common_excludes[@]}"; do
    args+=("-x" "${exclude}")
  done

  command diff -q -r "${args[@]}" "${dir1}" "${dir2}" "${@}"
}

keep_awake() {
  if [[ "${#}" -eq 0 ]]; then
    echo "Usage: keep_awake <command> [arguments...]"
    return 1
  fi

  _platform_keep_awake "${@}"
}

# Later overlays intentionally override generic capabilities.
_load_platform_config() {
  local config_source="${BASH_SOURCE[0]}"
  local config_dir="."
  if [[ "${config_source}" == */* ]]; then
    config_dir="${config_source%/*}"
    [[ -n "${config_dir}" ]] || config_dir="/"
  fi

  local platform_dir=""
  platform_dir="$(builtin cd -- "${config_dir}" 2>/dev/null && pwd -P)" || {
    echo "WARN: Could not resolve the Bash platform configuration directory." >&2
    return 1
  }
  platform_dir+="/platform"

  case "${OSTYPE:-}" in
    darwin*)
      # shellcheck disable=SC1090
      source "${platform_dir}/macos.sh"
      ;;
    linux*)
      # shellcheck disable=SC1090
      source "${platform_dir}/linux.sh" || return

      if [[ -f /etc/arch-release ]]; then
        # shellcheck disable=SC1090
        source "${platform_dir}/arch.sh" || return
      fi

      if _is_wsl; then
        # shellcheck disable=SC1090
        source "${platform_dir}/wsl.sh"
      elif [[ -f /etc/arch-release ]]; then
        # shellcheck disable=SC1090
        source "${platform_dir}/native_arch.sh"
      fi
      ;;
  esac
}

if ! _load_platform_config; then
  echo "WARN: Bash platform integrations were not fully loaded." >&2
fi
unset _exclude
unset -f _is_wsl _load_platform_config _reset_shell_names
