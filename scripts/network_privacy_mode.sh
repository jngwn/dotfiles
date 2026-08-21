#!/usr/bin/env bash

show_usage() {
  cat <<'EOF'
Usage: network_privacy_mode.sh <connection-profile> [mode]

Modes:
  trusted  Trusted personal connection: random MAC, strict DoT, IPv6 disabled.
  portal   Captive portal login: stable MAC, automatic DNS, IPv6 privacy enabled.
  public   Public network after login: stable MAC, strict DoT, IPv6 disabled.
  vpn      Delegate DNS to a VPN app: keep MAC policy, automatic DNS, IPv6 disabled.
  managed  Inspect a connection without changing its settings.

The default mode is trusted. Run modifying modes from a local terminal, not SSH.
EOF
}

print_error() {
  echo "ERROR: ${1}" >&2
}

require_command() {
  local -r command_name="${1}"

  if ! command -v "${command_name}" >/dev/null 2>&1; then
    print_error "Required command not found: ${command_name}"
    return 1
  fi
}

is_supported_mode() {
  case "${1}" in
    trusted | portal | public | vpn | managed) return 0 ;;
    *) return 1 ;;
  esac
}

inspect_connection() {
  local -r profile_uuid="${1}"

  nmcli -f connection.id,connection.uuid,connection.type,connection.dns-over-tls,ipv4.dns,ipv4.ignore-auto-dns,ipv6.method,ipv6.dns,ipv6.ignore-auto-dns connection show uuid "${profile_uuid}" || return 1
  resolvectl status || return 1
  echo "DONE: Connection inspected without changing its policy."
}

apply_connection_mode() {
  local -r profile_uuid="${1}"
  local -r connection_type="${2}"
  local -r dns_mode="${3}"
  local cloned_mac_property

  case "${connection_type}" in
    802-11-wireless) cloned_mac_property="802-11-wireless.cloned-mac-address" ;;
    802-3-ethernet) cloned_mac_property="802-3-ethernet.cloned-mac-address" ;;
    *)
      print_error "Only Wi-Fi and Ethernet profiles can use a modifying mode."
      return 1
      ;;
  esac

  case "${dns_mode}" in
    trusted)
      nmcli connection modify uuid "${profile_uuid}" \
        "${cloned_mac_property}" random \
        connection.dns-over-tls yes \
        ipv4.ignore-auto-dns yes \
        ipv4.dns "1.1.1.1#one.one.one.one 1.0.0.1#one.one.one.one" \
        ipv6.method disabled \
        ipv6.ignore-auto-dns yes \
        ipv6.dns "" || return 1
      ;;
    portal)
      # Captive portals commonly bind authentication to the client MAC. Keep a
      # pseudonymous address stable across the portal-to-public reactivation.
      nmcli connection modify uuid "${profile_uuid}" \
        "${cloned_mac_property}" stable \
        connection.dns-over-tls no \
        ipv4.ignore-auto-dns no \
        ipv4.dns "" \
        ipv6.method auto \
        ipv6.ip6-privacy 2 \
        ipv6.ignore-auto-dns no \
        ipv6.dns "" || return 1
      ;;
    public)
      nmcli connection modify uuid "${profile_uuid}" \
        "${cloned_mac_property}" stable \
        connection.dns-over-tls yes \
        ipv4.ignore-auto-dns yes \
        ipv4.dns "1.1.1.1#one.one.one.one 1.0.0.1#one.one.one.one" \
        ipv6.method disabled \
        ipv6.ignore-auto-dns yes \
        ipv6.dns "" || return 1
      ;;
    vpn)
      # Preserve the current MAC policy so a portal-authenticated connection
      # keeps its stable address while the VPN app takes ownership of DNS.
      nmcli connection modify uuid "${profile_uuid}" \
        connection.dns-over-tls no \
        ipv4.ignore-auto-dns no \
        ipv4.dns "" \
        ipv6.method disabled \
        ipv6.ignore-auto-dns yes \
        ipv6.dns "" || return 1
      ;;
  esac

  nmcli connection up uuid "${profile_uuid}" || {
    print_error "Failed to reactivate the connection after applying mode: ${dns_mode}"
    return 1
  }
  resolvectl status || return 1

  case "${dns_mode}" in
    trusted | public)
      resolvectl query example.com || {
        print_error "Strict DoT verification failed. Use portal or vpn mode on this network."
        return 1
      }
      ;;
    portal)
      echo "DONE: Portal-compatible DNS and IPv6 are active. Open the login page manually."
      ;;
    vpn)
      echo "DONE: Automatic DNS is active. Connect the VPN and verify its DNS leak protection."
      ;;
  esac
}

main() {
  if [[ "${1-}" == "-h" || "${1-}" == "--help" ]]; then
    show_usage
    return 0
  fi
  if ((EUID == 0)); then
    print_error "Run this script as the normal desktop user, not root."
    return 1
  fi
  if (($# < 1 || $# > 2)); then
    show_usage >&2
    return 2
  fi

  local -r profile_reference="${1}"
  local -r dns_mode="${2:-trusted}"
  local command_name
  local profile_uuid
  local connection_type
  local resolv_conf_target

  if ! is_supported_mode "${dns_mode}"; then
    print_error "Unsupported mode: ${dns_mode}"
    show_usage >&2
    return 2
  fi

  for command_name in nmcli readlink resolvectl systemctl; do
    require_command "${command_name}" || return 1
  done
  if ! systemctl is-active --quiet systemd-resolved.service; then
    print_error "systemd-resolved is not active. Complete the Arch bootstrap first."
    return 1
  fi

  resolv_conf_target="$(readlink -f /etc/resolv.conf 2>/dev/null)" || {
    print_error "Unable to resolve /etc/resolv.conf."
    return 1
  }
  if [[ "${resolv_conf_target}" != "/run/systemd/resolve/stub-resolv.conf" ]]; then
    print_error "/etc/resolv.conf is not connected to the systemd-resolved stub."
    return 1
  fi

  profile_uuid="$(nmcli -g connection.uuid connection show "${profile_reference}" 2>/dev/null)" || {
    print_error "NetworkManager connection profile not found: ${profile_reference}"
    return 1
  }
  if [[ -z "${profile_uuid}" || "${profile_uuid}" == *$'\n'* ]]; then
    print_error "The profile reference is ambiguous; use its UUID instead."
    return 1
  fi
  connection_type="$(nmcli -g connection.type connection show uuid "${profile_uuid}")" || return 1

  echo "INFO: Connection UUID: ${profile_uuid}"
  echo "INFO: Connection type: ${connection_type}"
  echo "INFO: Selected mode: ${dns_mode}"

  if [[ "${dns_mode}" == "managed" ]]; then
    inspect_connection "${profile_uuid}"
    return
  fi
  if [[ -n "${SSH_CONNECTION:-}" || -n "${SSH_TTY:-}" ]]; then
    print_error "Run modifying modes locally because network reactivation can terminate SSH."
    return 1
  fi

  apply_connection_mode "${profile_uuid}" "${connection_type}" "${dns_mode}"
}

main "$@"
