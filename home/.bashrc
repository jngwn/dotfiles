# shellcheck shell=bash
[[ $- == *i* ]] || return

_configure_interactive_locale() {
  local available_locales candidate
  available_locales="$(locale -a 2>/dev/null || true)"

  for candidate in en_US.UTF-8 en_US.utf8 C.UTF-8 C.utf8; do
    if [[ $'\n'"${available_locales}"$'\n' == *$'\n'"${candidate}"$'\n'* ]]; then
      export LANG="${candidate}"
      if [[ "${candidate}" == en_US* ]]; then
        export LANGUAGE="en_US:en"
      else
        unset LANGUAGE
      fi

      # LC_ALL stays unset so minimal SSH sessions do not propagate an
      # unavailable locale into child processes.
      unset LC_ALL
      return
    fi
  done

  export LANG="C"
  unset LANGUAGE LC_ALL
}
_configure_interactive_locale
unset -f _configure_interactive_locale

# Preserve inherited precedence; mise activation below may prepend managed tools.
if [[ ":${PATH:-}:" != *":${HOME}/.local/bin:"* ]]; then
  export PATH="${PATH:+${PATH}:}${HOME}/.local/bin"
fi
# Keep persistent user files in explicit XDG bases. XDG_RUNTIME_DIR is created
# per login by PAM/systemd and must not be replaced with a persistent path.
export XDG_CONFIG_HOME="${HOME}/.config"
export XDG_DATA_HOME="${HOME}/.local/share"
export XDG_STATE_HOME="${HOME}/.local/state"
export XDG_CACHE_HOME="${HOME}/.cache"

_local_env_file="${HOME}/.local/bin/env"
if [[ -f "${_local_env_file}" ]]; then
  # shellcheck disable=SC1090
  source "${_local_env_file}"
fi
unset _local_env_file

set -o vi
bind 'set bell-style none'
bind 'set completion-ignore-case on'
bind 'set completion-map-case on'
bind 'set colored-completion-prefix on'
bind 'set colored-stats on'
bind 'set show-all-if-ambiguous on'

_bind_terminal_key() {
  local key_sequence="${1}"
  local readline_function="${2}"
  local keymap

  for keymap in emacs-standard vi-insert vi-command; do
    bind -m "${keymap}" "\"${key_sequence}\": ${readline_function}" 2>/dev/null || true
  done
}

for _key_sequence in '\e[H' '\eOH' '\e[1~' '\e[7~'; do
  _bind_terminal_key "${_key_sequence}" beginning-of-line
done
for _key_sequence in '\e[F' '\eOF' '\e[4~' '\e[8~'; do
  _bind_terminal_key "${_key_sequence}" end-of-line
done
_bind_terminal_key '\e[5~' history-search-backward
_bind_terminal_key '\e[6~' history-search-forward
for _key_sequence in '\e[1;5D' '\e[5D' '\eOd'; do
  _bind_terminal_key "${_key_sequence}" backward-word
done
for _key_sequence in '\e[1;5C' '\e[5C' '\eOc'; do
  _bind_terminal_key "${_key_sequence}" forward-word
done
_bind_terminal_key '\e[3~' delete-char
_bind_terminal_key '\e[3;5~' kill-word
for _key_sequence in '\C-h' '\C-?'; do
  _bind_terminal_key "${_key_sequence}" backward-delete-char
done
_bind_terminal_key '\C-u' unix-line-discard
_bind_terminal_key '\C-k' kill-line
_bind_terminal_key '\C-l' clear-screen
unset _key_sequence
unset -f _bind_terminal_key

for _bash_completion_file in \
  /usr/share/bash-completion/bash_completion \
  /opt/homebrew/etc/profile.d/bash_completion.sh \
  /usr/local/etc/profile.d/bash_completion.sh; do
  if [[ -r "${_bash_completion_file}" ]]; then
    # shellcheck disable=SC1090
    source "${_bash_completion_file}"
    break
  fi
done
unset _bash_completion_file

if command -v mise >/dev/null 2>&1; then
  eval "$(command mise activate bash)"
fi

# TTY shells may not inherit the graphical environment. Preserve forwarded or
# externally managed agents, and use the Sway session agent only when it exists.
_systemd_ssh_socket="${XDG_RUNTIME_DIR:-}/ssh-agent.socket"
if [[ -z "${SSH_AUTH_SOCK:-}" && -S "${_systemd_ssh_socket}" ]]; then
  export SSH_AUTH_SOCK="${_systemd_ssh_socket}"
fi
unset _systemd_ssh_socket

if [[ -f "${XDG_CONFIG_HOME}/bash/aliases.sh" ]]; then
  # shellcheck disable=SC1090
  source "${XDG_CONFIG_HOME}/bash/aliases.sh"
fi

if [[ -f "${HOME}/.bashrc.secret" ]]; then
  # shellcheck disable=SC1090
  source "${HOME}/.bashrc.secret"
fi

if [[ "${TERM}" != "screen" ]] &&
  [[ "${TERM}" != "tmux" ]] &&
  [[ "${TERM}" != "linux" ]]; then
  export COLORTERM="truecolor"
fi

_configure_bash_history() {
  local -r history_dir="${XDG_STATE_HOME}/bash"
  local -r history_file="${history_dir}/history"

  if [[ -L "${history_dir}" ]] ||
    [[ -e "${history_dir}" && (! -d "${history_dir}" || ! -O "${history_dir}") ]]; then
    printf 'WARN: Persistent Bash history is disabled because its directory is unsafe: %s\n' \
      "${history_dir}" >&2
    unset HISTFILE
    return
  fi
  if ! mkdir -p "${history_dir}" || ! chmod 0700 "${history_dir}"; then
    printf 'WARN: Persistent Bash history is disabled because its directory is unavailable: %s\n' \
      "${history_dir}" >&2
    unset HISTFILE
    return
  fi
  if [[ -L "${history_file}" ]] ||
    [[ -e "${history_file}" && (! -f "${history_file}" || ! -O "${history_file}") ]]; then
    printf 'WARN: Persistent Bash history is disabled because its file is unsafe: %s\n' \
      "${history_file}" >&2
    unset HISTFILE
    return
  fi
  if [[ ! -e "${history_file}" ]]; then
    (umask 077 && : >"${history_file}") || {
      printf 'WARN: Persistent Bash history is disabled because its file cannot be created: %s\n' \
        "${history_file}" >&2
      unset HISTFILE
      return
    }
  fi
  if ! chmod 0600 "${history_file}"; then
    printf 'WARN: Persistent Bash history is disabled because its file cannot be protected: %s\n' \
      "${history_file}" >&2
    unset HISTFILE
    return
  fi

  export HISTFILE="${history_file}"
}
_configure_bash_history
unset -f _configure_bash_history
export HISTSIZE=1000
export HISTFILESIZE=1000
export HISTCONTROL="ignoreboth:erasedups"
shopt -s histappend cmdhist

_set_prompt() {
  local status=$?
  local context=''
  local leading_newline=''
  local result=''

  if [[ -n "${_prompt_initialized:-}" ]]; then
    leading_newline='\n'
  else
    _prompt_initialized=1
  fi

  if ((status != 0)); then
    result="\[\e[31m\][${status}]\[\e[0m\] "
  fi

  if [[ -n "${SSH_CONNECTION:-}" || -n "${SSH_TTY:-}" ]]; then
    context='[ssh \u@\h] '
  fi

  PS1="${leading_newline}\[\e[1;30m\]${context}\w\[\e[0m\]\n${result}\$ "
}
# Capture the user's exit status first, then retain mise and other existing hooks.
if [[ ";${PROMPT_COMMAND:-};" != *';_set_prompt;'* ]]; then
  PROMPT_COMMAND="_set_prompt${PROMPT_COMMAND:+;${PROMPT_COMMAND}}"
fi
