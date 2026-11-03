_reset_shell_names pacss pacsi pacqi pacq bubo bubc bubu
if command -v pacman >/dev/null 2>&1; then
  alias pacss='pacman -Ss'
  alias pacsi='pacman -Si'
  alias pacqi='pacman -Qi'

  if ! _is_remote_shell; then
    bubo() {
      echo "INFO: Checking pacman updates..."
      if command -v checkupdates >/dev/null 2>&1; then
        command checkupdates || true
      else
        command pacman -Qu
      fi

      if command -v flatpak >/dev/null 2>&1; then
        echo ""
        echo "INFO: Checking Flatpak updates..."
        command flatpak remote-ls --updates || true
      fi
    }

    bubc() {
      # Complete the full-system upgrade before updating Flatpak so system
      # packages, kernels, and desktop libraries reach a consistent state first.
      command sudo pacman -Syu || return

      if command -v flatpak >/dev/null 2>&1; then
        command flatpak update -y || return
      fi
    }

    bubu() {
      bubo && bubc
    }
  fi

  pacq() {
    if [ "${#}" -eq 0 ]; then
      command pacman -Q
    elif command -v rg >/dev/null 2>&1; then
      command pacman -Q | command rg --ignore-case --fixed-strings "${*}"
    else
      command pacman -Q | command grep -i --fixed-strings "${*}"
    fi
  }
fi

_platform_privacy_cleanup_preview() {
  if [[ -x /usr/bin/journalctl ]]; then
    /usr/bin/journalctl --disk-usage 2>/dev/null || true
  fi
  if [[ -d /var/cache/pacman/pkg ]]; then
    command du -sh -- /var/cache/pacman/pkg 2>/dev/null || true
  fi
  echo "  - Arch package cache: keep the latest 3 versions"
}

_platform_privacy_cleanup_system() {
  local -r retention_period="${1}"
  local -r retention_label="${2}"
  local failed=false

  # Fixed system paths keep aliases and user-installed wrappers outside the
  # privilege boundary.
  if [[ ! -x /usr/bin/sudo ]]; then
    echo "WARN: sudo is required to clean system journals and the Pacman cache."
    return 1
  fi

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

  [[ "${failed}" == "false" ]]
}
