# ~/.bash_profile
# ----------------------------------------------------------
# Keep login and non-login interactive shells on the same Bash startup path.
if [[ -f "${HOME}/.bashrc" ]]; then
  # shellcheck disable=SC1090
  source "${HOME}/.bashrc"
fi
