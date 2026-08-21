# ~/.bashrc
# ----------------------------------------------------------
# Keep interactive Bash startup here; reusable commands belong in
# ~/.config/bash/aliases.sh.
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

# Append user-owned scripts without changing the inherited command precedence.
# mise activation below owns precedence for configured development tools.
export PATH="${PATH}:${HOME}/.local/bin"
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

  for keymap in emacs-standard vi-insertion vi-command; do
    bind -m "${keymap}" "\"${key_sequence}\": ${readline_function}" 2>/dev/null || true
  done
}

# Normalize common terminal editing keys across local and remote sessions.
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

if [[ -r /usr/share/bash-completion/bash_completion ]]; then
  # shellcheck disable=SC1091
  source /usr/share/bash-completion/bash_completion
fi

if [[ -x /usr/bin/mise ]]; then
  eval "$(/usr/bin/mise activate bash)"
elif command -v mise >/dev/null 2>&1; then
  eval "$(mise activate bash)"
fi

# TTY shells may not inherit the graphical environment. Preserve forwarded or
# externally managed agents, and use the Sway session agent only when it exists.
_systemd_ssh_socket="${XDG_RUNTIME_DIR:-}/ssh-agent.socket"
if [[ -z "${SSH_AUTH_SOCK:-}" && -S "${_systemd_ssh_socket}" ]]; then
  export SSH_AUTH_SOCK="${_systemd_ssh_socket}"
fi
unset _systemd_ssh_socket

# Keep the Bash command surface separate from startup, and source one explicit
# file now that Bash is the only maintained interactive shell.
if [[ -f "${HOME}/.config/bash/aliases.sh" ]]; then
  # shellcheck disable=SC1090
  source "${HOME}/.config/bash/aliases.sh"
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

export HISTFILE="${HOME}/.bash_history"
export HISTSIZE=1000
export HISTFILESIZE=1000
export HISTCONTROL="ignoreboth:erasedups"
shopt -s histappend cmdhist

export UNZIP="-O cp949"
export ZIPINFO="-O cp949"

if command -v starship >/dev/null 2>&1; then
  eval "$(starship init bash)"
fi
