_reset_shell_names reload_config reloadall

_reload_sway_session_config() {
  local -r user_manager_ready="${1:-false}"
  local failed=false

  if [[ -n "${SWAYSOCK:-}" && "${user_manager_ready}" == "true" ]]; then
    if command systemctl --user is-active --quiet waybar.service; then
      echo "INFO: Reloading Waybar..."
      if ! command systemctl --user kill --kill-who=main --signal=SIGUSR2 waybar.service; then
        echo "ERROR: Failed to reload Waybar."
        failed=true
      fi
    fi

    if command systemctl --user is-active --quiet swaync.service &&
      command -v swaync-client >/dev/null 2>&1; then
      echo "INFO: Reloading Sway Notification Center..."
      if ! command swaync-client --reload-config || ! command swaync-client --reload-css; then
        echo "ERROR: Failed to reload Sway Notification Center."
        failed=true
      fi
    fi

    # Kanshi has no reload protocol, so restart only the active instance.
    if command systemctl --user is-active --quiet kanshi.service; then
      echo "INFO: Reloading Kanshi output profiles..."
      if ! command systemctl --user restart kanshi.service; then
        echo "ERROR: Failed to reload Kanshi output profiles."
        failed=true
      fi
    fi
  fi

  if [[ -n "${SWAYSOCK:-}" ]] && command -v swaymsg >/dev/null 2>&1; then
    echo "INFO: Reloading Sway compositor..."
    if ! command swaymsg reload; then
      echo "ERROR: Failed to reload the Sway compositor."
      failed=true
    fi
  fi

  [[ "${failed}" == "false" ]]
}

reload_config() {
  local user_manager_ready=false
  local reloaded=false
  local failed=false

  echo "INFO: Reloading active configurations..."

  # A degraded user manager is still reachable and must receive unit reloads.
  if command -v systemctl >/dev/null 2>&1 &&
    command systemctl --user show-environment >/dev/null 2>&1; then
    user_manager_ready=true
    reloaded=true
    echo "INFO: Reloading systemd user daemon..."
    if ! command systemctl --user daemon-reload; then
      echo "ERROR: Failed to reload the systemd user daemon."
      failed=true
    fi
  fi

  if [[ -n "${SWAYSOCK:-}" ]] && command -v swaymsg >/dev/null 2>&1; then
    reloaded=true
  fi
  _reload_sway_session_config "${user_manager_ready}" || failed=true

  if [[ -n "${TMUX:-}" ]] && command -v tmux >/dev/null 2>&1; then
    reloaded=true
    local -r xdg_config_home="${XDG_CONFIG_HOME:-${HOME}/.config}"

    echo "INFO: Reloading Tmux configuration..."
    if ! command tmux source-file "${xdg_config_home}/tmux/tmux.conf"; then
      echo "ERROR: Failed to reload the Tmux configuration."
      failed=true
    fi
  fi

  if [[ "${failed}" == "true" ]]; then
    echo "WARN: Reload completed with errors."
    return 1
  fi

  if [[ "${reloaded}" == "false" ]]; then
    echo "INFO: No active configurations to reload."
    return 0
  fi

  echo "DONE: Reload completed."
}
alias reloadall='reload_config'

_reset_shell_names sunset
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

_reset_shell_names firmware_update fwup
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
