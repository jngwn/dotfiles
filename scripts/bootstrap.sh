#!/usr/bin/env bash

# Bootstrap Arch Linux to a personal Sway desktop.
# Keep the OS baseline on Arch packages and the graphical session Wayland-first.

# Common helpers and environment detection {{{

start_logging() { # {{{
  local -r xdg_state_home="${XDG_STATE_HOME:-${HOME}/.local/state}"
  local -r log_dir="${xdg_state_home}/dotfiles/logs"
  local -r log_file="${log_dir}/$(date +%Y%m%d-%H%M%S)-bootstrap.log"

  if ! command -v tee >/dev/null 2>&1; then
    echo "ERROR: tee is required for logging." >&2
    exit 1
  fi

  # Logs can contain user paths and command output, so keep them owner-only.
  if ! mkdir -p "${log_dir}" || ! chmod 0700 "${log_dir}"; then
    echo "ERROR: Could not create or protect log directory: ${log_dir}" >&2
    exit 1
  fi

  if ! touch "${log_file}" || ! chmod 0600 "${log_file}"; then
    echo "ERROR: Could not create or protect log file: ${log_file}" >&2
    exit 1
  fi

  exec > >(tee -a "${log_file}") 2>&1

  echo "INFO: Log file: ${log_file}"
  echo ""
} # }}}

show_script_info() { # {{{
  echo "INFO: basename: ${0##*/}"
  echo "INFO: dirname : $(dirname "${0}")"
  echo "INFO: pwd     : $(pwd)"
  echo ""
} # }}}

find_and_move_to_dotfiles_root() { # {{{
  dotfiles_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)" || {
    echo "ERROR: Unable to find dotfiles root from script location."
    return 1
  }

  echo "INFO: Dotfiles root: ${dotfiles_root}"
  cd "${dotfiles_root}" || {
    echo "ERROR: Unable to move to directory '${dotfiles_root}'."
    return 1
  }
} # }}}

is_arch() { # {{{
  [[ -f /etc/os-release ]] || return 1
  (
    source /etc/os-release
    [[ "${ID}" == "arch" ]]
  )
} # }}}

is_supported_platform() { # {{{
  is_arch || return 1

  if [[ -r /proc/sys/kernel/osrelease ]] &&
    grep -qiE '(microsoft|wsl)' /proc/sys/kernel/osrelease; then
    return 1
  fi

  return 0
} # }}}

refuse_root_execution() { # {{{
  if ((EUID == 0)); then
    echo "ERROR: Do not run bootstrap.sh as root."
    echo "   Run it as your normal user; this script will use sudo when needed."
    exit 1
  fi
} # }}}

target_user() { # {{{
  if [[ -n "${SUDO_USER:-}" && "${SUDO_USER}" != "root" ]]; then
    printf "%s\n" "${SUDO_USER}"
    return 0
  fi

  if [[ -n "${USER:-}" && "${USER}" != "root" ]]; then
    printf "%s\n" "${USER}"
    return 0
  fi

  return 1
} # }}}

target_home() { # {{{
  local user_name="${1:-}"
  if [[ -z "${user_name}" ]]; then
    user_name="$(target_user)" || return 1
  fi

  local home_dir=""
  home_dir="$(getent passwd "${user_name}" | cut -d: -f6)"
  if [[ -z "${home_dir}" ]]; then
    return 1
  fi

  printf "%s\n" "${home_dir}"
} # }}}

run_as_target_user() { # {{{
  local user_name=""
  user_name="$(target_user)" || return 1

  local current_user=""
  current_user="$(id -un 2>/dev/null || true)"
  if [[ "${current_user}" == "${user_name}" ]]; then
    "${@}"
    return
  fi

  if command -v sudo &>/dev/null; then
    sudo -H -u "${user_name}" "${@}"
  elif ((EUID == 0)) && command -v runuser &>/dev/null; then
    runuser -u "${user_name}" -- "${@}"
  else
    echo "WARN: Could not run command as ${user_name}."
    return 1
  fi
} # }}}

run_as_root() { # {{{
  if ((EUID == 0)); then
    "${@}"
    return
  fi

  sudo "${@}"
} # }}}

# Common helpers and environment detection }}}

# Arch Linux system packages {{{

_pacman_mutations_allowed=false

install_package() { # {{{
  local -a valid_pkgs=()
  local pkg

  for pkg in "${@}"; do
    if pacman -Qq "${pkg}" >/dev/null 2>&1; then
      echo "DONE: Package already installed: ${pkg}"
      continue
    fi

    if pacman -Si "${pkg}" >/dev/null 2>&1; then
      valid_pkgs+=("${pkg}")
    else
      echo "WARN: Skipping: ${pkg} (Not found in configured pacman repositories)"
    fi
  done

  if [[ ${#valid_pkgs[@]} -eq 0 ]]; then
    return 0
  fi

  # Do not refresh package databases here. Arch-based systems do not support
  # partial upgrades, so the full system upgrade stays centralized in upgrade_packages.
  run_as_root pacman -S --needed --noconfirm -- "${valid_pkgs[@]}" && return 0

  echo "WARN: Package batch install failed. Retrying packages one by one..."

  local failed=false
  for pkg in "${valid_pkgs[@]}"; do
    if pacman -Qq "${pkg}" >/dev/null 2>&1; then
      echo "DONE: Package already installed: ${pkg}"
      continue
    fi

    echo ""
    echo "INFO: Installing package: ${pkg}"
    run_as_root pacman -S --needed --noconfirm -- "${pkg}" || {
      echo "WARN: Failed to install package: ${pkg}"
      failed=true
    }
  done

  [[ "${failed}" == "false" ]]
} # }}}

replace_package_before_install() { # {{{
  local desired_pkg="${1:-}"
  shift || true

  if [[ -z "${desired_pkg}" ]]; then
    echo "WARN: replace_package_before_install requires a desired package."
    return 1
  fi

  if pacman -Qq "${desired_pkg}" >/dev/null 2>&1; then
    echo "DONE: Preferred package already installed: ${desired_pkg}"
    return 0
  fi

  local old_pkg
  for old_pkg in "${@}"; do
    if ! pacman -Qq "${old_pkg}" >/dev/null 2>&1; then
      continue
    fi

    echo ""
    echo "INFO: Replacing ${old_pkg} with ${desired_pkg}..."
    # pacman answers package conflict removal prompts with No under --noconfirm.
    # Remove only explicitly listed alternatives so provider choices stay local
    # to the caller instead of becoming broad automatic conflict resolution.
    run_as_root pacman -Rdd --noconfirm "${old_pkg}" || {
      echo "WARN: Failed to remove ${old_pkg} before installing ${desired_pkg}."
      return 1
    }
  done

  install_package "${desired_pkg}"
} # }}}

install_package_group() { # {{{
  local failed=false
  local group_name
  for group_name in "${@}"; do
    if ! pacman -Sgq "${group_name}" >/dev/null 2>&1; then
      echo "WARN: Skipping package group: ${group_name} (Not found in configured pacman repositories)"
      failed=true
      continue
    fi

    echo ""
    echo "INFO: Installing package group: ${group_name}"
    local -a group_packages=()
    mapfile -t group_packages < <(pacman -Sgq "${group_name}" | sort -u)
    install_package "${group_packages[@]}" || failed=true
  done

  [[ "${failed}" == "false" ]]
} # }}}

upgrade_packages() { # {{{
  echo ""
  echo "INFO: Upgrading Arch Linux packages..."
  if ! run_as_root pacman -Syu --noconfirm; then
    echo "ERROR: pacman system upgrade encountered an issue."
    return 1
  fi

  _pacman_mutations_allowed=true
} # }}}

handle_hardware_drivers() { # {{{
  if [[ "${_pacman_mutations_allowed}" != "true" ]]; then
    echo "ERROR: Skipping hardware driver packages because the full pacman upgrade did not complete."
    return 1
  fi

  if ! command -v lspci &>/dev/null; then
    echo "ERROR: lspci is not installed. Hardware driver setup cannot continue."
    return 1
  fi

  local pci_devices=""
  if ! pci_devices="$(lspci 2>/dev/null)"; then
    echo "ERROR: Failed to inspect PCI hardware."
    return 1
  fi

  local gpu_devices=""
  gpu_devices="$(grep -Ei "vga|3d|display" <<<"${pci_devices}" || true)"
  local failed=false

  # Match GPU vendors only on VGA/3D/Display controller lines. Other PCI
  # devices can contain vendor names that would otherwise trigger false positives.
  if grep -qiE "intel" <<<"${gpu_devices}"; then
    echo "INFO: Intel graphics detected. Installing Intel Vulkan and VA-API drivers..."
    install_package vulkan-intel intel-media-driver || failed=true
  fi

  if grep -qiE "advanced micro devices|amd/ati|ati technologies" <<<"${gpu_devices}"; then
    echo "INFO: AMD graphics detected. Installing AMD Vulkan driver..."
    install_package vulkan-radeon || failed=true
  fi

  if ! grep -qi nvidia <<<"${gpu_devices}"; then
    echo "INFO: No NVIDIA hardware detected."
    [[ "${failed}" == "false" ]]
    return
  fi

  echo "INFO: NVIDIA hardware detected."

  # Prefer Arch's current NVIDIA open-driver path for this personal bootstrap.
  # This intentionally does not parse NVIDIA generations from lspci output:
  # modern RTX/Blackwell-style systems should be handled automatically, while
  # very old GPUs will fail visibly or need a legacy AUR driver chosen manually.
  # Install a matching module package for each stock kernel that is present;
  # otherwise use DKMS so custom kernels can build their own module.
  local installed_stock_nvidia_module=false
  if pacman -Qq linux >/dev/null 2>&1; then
    install_package nvidia-open || failed=true
    installed_stock_nvidia_module=true
  fi

  if pacman -Qq linux-lts >/dev/null 2>&1; then
    install_package nvidia-open-lts || failed=true
    installed_stock_nvidia_module=true
  fi

  if [[ "${installed_stock_nvidia_module}" == "false" ]]; then
    install_package nvidia-open-dkms || failed=true
  fi

  install_package nvidia-utils || failed=true

  # 32-bit Vulkan/OpenGL support is only available when multilib is enabled.
  # These packages are needed for Steam, Proton, Wine, and other 32-bit runtime
  # users. If install_package skips them, enable multilib in /etc/pacman.conf:
  #
  #   [multilib]
  #   Include = /etc/pacman.d/mirrorlist
  #
  # Then refresh package databases and rerun this script:
  #
  #   sudo pacman -Syu
  #
  # Keep this manual because enabling a repository is an OS-level policy choice.
  # install_package will skip these cleanly on systems that keep multilib off.
  install_package lib32-nvidia-utils lib32-vulkan-icd-loader || failed=true

  # Rebuild initramfs after changing the GPU kernel module stack. Package hooks
  # usually cover this, but doing it here makes a nouveau -> nvidia-open bootstrap
  # transition explicit and easier to diagnose from the install log.
  # mkinitcpio may warn about optional firmware such as qat_6xxx. That module is
  # for Intel QuickAssist-style compression/encryption acceleration in server or
  # workstation-class hardware, not a normal personal desktop/laptop requirement.
  if command -v mkinitcpio &>/dev/null; then
    run_as_root mkinitcpio -P || {
      echo "WARN: Failed to rebuild initramfs after NVIDIA driver installation."
      failed=true
    }
  fi

  echo "INFO: Reboot after NVIDIA driver installation, then verify with nvidia-smi and vulkaninfo --summary."
  [[ "${failed}" == "false" ]]
} # }}}

setup_alsa_auto_mute() { # {{{
  if ! command -v amixer &>/dev/null || ! command -v alsactl &>/dev/null; then
    echo "ERROR: ALSA utilities are unavailable. Hardware auto-mute setup cannot continue."
    return 1
  fi

  echo ""
  echo "INFO: Disabling supported ALSA hardware auto-mute controls..."

  local matched_cards=0
  local configured_cards=0
  local card_path
  for card_path in /sys/class/sound/card[0-9]*; do
    [[ -e "${card_path}" ]] || continue

    local card_index="${card_path##*/card}"
    if ! run_as_root amixer -c "${card_index}" sget 'Auto-Mute Mode' &>/dev/null; then
      continue
    fi

    ((matched_cards += 1))
    if run_as_root amixer -c "${card_index}" sset 'Auto-Mute Mode' Disabled; then
      ((configured_cards += 1))
    else
      echo "WARN: Failed to disable ALSA auto-mute on card ${card_index}."
    fi
  done

  if ((matched_cards == 0)); then
    echo "INFO: No ALSA card exposes an Auto-Mute Mode control."
    return 0
  fi

  if ((configured_cards == 0)); then
    echo "ERROR: ALSA auto-mute could not be disabled on any matching card."
    return 1
  fi

  # Arch's package-provided alsa-restore.service loads this state on later
  # boots. Store all cards together so unrelated mixer state is not omitted.
  if ! run_as_root alsactl store; then
    echo "ERROR: Failed to persist ALSA mixer state for the next boot."
    return 1
  fi

  echo "DONE: ALSA hardware auto-mute is disabled on ${configured_cards} card(s)."
} # }}}

_require_package_mutations() { # {{{
  if [[ "${_pacman_mutations_allowed}" != "true" ]]; then
    echo "ERROR: Skipping package installation because the full pacman upgrade did not complete."
    return 1
  fi
} # }}}

_install_required_packages() { # {{{
  local failed=false
  local -a available_packages=()
  local pkg
  for pkg in "${@}"; do
    if pacman -Qq "${pkg}" >/dev/null 2>&1 || pacman -Si "${pkg}" >/dev/null 2>&1; then
      available_packages+=("${pkg}")
    else
      echo "ERROR: Required package not found in configured pacman repositories: ${pkg}"
      failed=true
    fi
  done

  if [[ ${#available_packages[@]} -gt 0 ]]; then
    install_package "${available_packages[@]}" || failed=true

    # Maintained requirements stay explicit even when another package pulled
    # them in first, so orphan cleanup cannot remove a required capability.
    local -a installed_packages=()
    for pkg in "${available_packages[@]}"; do
      if pacman -Qq "${pkg}" >/dev/null 2>&1; then
        installed_packages+=("${pkg}")
      fi
    done

    if [[ ${#installed_packages[@]} -gt 0 ]]; then
      run_as_root pacman -D --asexplicit -- "${installed_packages[@]}" || {
        echo "ERROR: Failed to mark required packages as explicitly installed."
        failed=true
      }
    fi
  fi

  [[ "${failed}" == "false" ]]
} # }}}

_install_required_package_groups() { # {{{
  local failed=false
  local -a available_groups=()
  local group_name
  for group_name in "${@}"; do
    if pacman -Sgq "${group_name}" >/dev/null 2>&1; then
      available_groups+=("${group_name}")
    else
      echo "ERROR: Required package group not found in configured pacman repositories: ${group_name}"
      failed=true
    fi
  done

  if [[ ${#available_groups[@]} -gt 0 ]]; then
    install_package_group "${available_groups[@]}" || failed=true
  fi

  [[ "${failed}" == "false" ]]
} # }}}

install_base_packages() { # {{{
  _require_package_mutations || return 1

  echo ""
  echo "INFO: Installing Arch Linux base packages..."

  local failed=false

  # Maintained interactive shell and general command-line baseline.
  _install_required_packages \
    bash bash-completion tmux neovim fastfetch \
    git ripgrep fd jq git-delta curl wget ca-certificates \
    openssl openssh \
    glibc util-linux base-devel \
    zlib bzip2 readline sqlite libffi xz \
    zip unzip 7zip \
    tree yazi mat2 fontconfig ffmpeg \
    pacman-contrib || failed=true

  # Arch system, hardware, storage, firmware, and network foundations.
  _install_required_packages \
    pciutils mesa vulkan-icd-loader \
    cryptsetup gptfdisk hdparm nvme-cli \
    fwupd \
    networkmanager firewalld || failed=true

  # Keep FUSE 2 compatibility, exFAT utilities, and VeraCrypt together for
  # occasional encrypted removable-media workflows.
  _install_required_packages fuse2 exfatprogs veracrypt || failed=true

  [[ "${failed}" == "false" ]]
} # }}}

install_development_packages() { # {{{
  _require_package_mutations || return 1

  echo ""
  echo "INFO: Installing local development packages..."

  local failed=false

  # User development environment and repository validation baseline. Pacman
  # owns these workstation-wide binaries; project dependencies remain local.
  _install_required_packages \
    mise python \
    clang lldb lua-language-server \
    shellcheck shfmt stylua taplo-cli \
    pre-commit || failed=true

  # Local application dependencies stay project-owned, while Docker and Compose
  # provide the shared runtime used by Spring Boot and other development stacks.
  _install_required_packages docker docker-compose || failed=true

  [[ "${failed}" == "false" ]]
} # }}}

install_desktop_foundation_packages() { # {{{
  _require_package_mutations || return 1

  echo ""
  echo "INFO: Installing shared desktop foundation packages..."

  local failed=false

  # Toolkit, portal, and Wayland application integration shared by the desktop.
  _install_required_packages \
    xkeyboard-config \
    xdg-desktop-portal xdg-desktop-portal-gtk \
    xdg-utils xdg-user-dirs \
    qt5-wayland qt6-wayland \
    wl-clipboard \
    v4l-utils pipewire-v4l2 || failed=true

  # System-backed desktop capabilities do not belong to the compositor.
  # Optional hardware clients stay inert when unsupported.
  _install_required_packages \
    batsignal brightnessctl playerctl \
    bluez bluez-utils \
    polkit \
    gnome-keyring libsecret \
    upower power-profiles-daemon switcheroo-control \
    udisks2 \
    cups bluez-cups \
    libnotify || failed=true

  # Fcitx modules cover native GTK/Qt Wayland clients and XWayland fallbacks.
  _install_required_package_groups fcitx5-im || failed=true
  _install_required_packages fcitx5-hangul || failed=true

  # Audio and shared media support belong to the graphical workstation rather
  # than to one compositor or user-facing application.
  replace_package_before_install pipewire-jack jack2 || failed=true
  _install_required_packages \
    noto-fonts-cjk noto-fonts-emoji glib2 dbus \
    pipewire pipewire-pulse pipewire-alsa pipewire-jack wireplumber gst-plugin-pipewire \
    alsa-utils || failed=true

  [[ "${failed}" == "false" ]]
} # }}}

install_sway_session_packages() { # {{{
  _require_package_mutations || return 1

  echo ""
  echo "INFO: Installing Sway session packages..."

  local failed=false

  # Wayland compositor, login, portal, and compatibility boundary.
  _install_required_packages \
    sway swaybg swayidle swaylock \
    greetd greetd-regreet cage \
    xorg-xwayland \
    xdg-desktop-portal-wlr || failed=true

  # Keep the Sway-owned shell and session adapters in one package slice.
  _install_required_packages \
    waybar swaync fuzzel swayosd \
    kanshi wdisplays \
    grim slurp swappy cliphist wf-recorder \
    wlsunset \
    network-manager-applet \
    blueman \
    lxqt-policykit \
    udiskie || failed=true

  [[ "${failed}" == "false" ]]
} # }}}

install_desktop_application_packages() { # {{{
  _require_package_mutations || return 1

  echo ""
  echo "INFO: Installing desktop application packages..."

  local failed=false

  # User-facing applications and their data-format support are personal desktop
  # choices rather than compositor requirements.
  _install_required_packages \
    pavucontrol \
    libheif poppler-data \
    gst-libav gst-plugin-va gst-plugins-base gst-plugins-good gst-plugins-bad gst-plugins-ugly \
    firefox mpv foot btop thunar tumbler thunar-archive-plugin xarchiver gvfs \
    imv gnome-disk-utility system-config-printer \
    papirus-icon-theme flatpak || failed=true

  [[ "${failed}" == "false" ]]
} # }}}

setup_flatpak_remote() { # {{{
  if [[ "${_pacman_mutations_allowed}" != "true" ]]; then
    echo "ERROR: Skipping Flathub remote configuration because the full pacman upgrade did not complete."
    return 1
  fi

  if ! command -v flatpak &>/dev/null; then
    return 0
  fi

  echo ""
  echo "INFO: Configuring the Flathub remote..."
  run_as_root flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo || {
    echo "WARN: Failed to add Flathub remote."
  }
} # }}}

setup_local_container_runtime() { # {{{
  # Docker is only the shared local container runtime. Projects own database
  # images, credentials, ports, volumes, and lifecycle through Compose or Testcontainers.
  if ! command -v docker &>/dev/null; then
    echo "WARN: Docker is not installed. Skipping local container runtime setup."
    return 1
  fi

  local target_user_name=""
  target_user_name="$(target_user)" || {
    echo "WARN: Could not identify a non-root target user. Skipping Docker access setup."
    return 1
  }

  if ! getent group docker >/dev/null 2>&1; then
    echo "WARN: The docker group does not exist. Skipping Docker access setup."
    return 1
  fi

  if id -nG "${target_user_name}" | tr ' ' '\n' | grep -Fxq docker; then
    echo "DONE: ${target_user_name} already belongs to the docker group."
  else
    # Docker's daemon remains root-owned; membership grants this account
    # root-equivalent control through its socket for local development tools.
    echo "INFO: Granting ${target_user_name} access to the root-privileged Docker socket..."
    run_as_root usermod --append --groups docker "${target_user_name}" || {
      echo "WARN: Failed to add ${target_user_name} to the docker group."
      return 1
    }
    echo "INFO: Docker group membership takes effect after the next login."
  fi

  if ! command -v systemctl &>/dev/null; then
    echo "WARN: systemctl is not available. Skipping Docker socket activation."
    return 1
  fi

  # Socket activation avoids starting the daemon until a local tool requests it.
  run_as_root systemctl enable --now docker.socket || {
    echo "WARN: Failed to enable docker.socket."
    return 1
  }
} # }}}

# Arch Linux system packages }}}

# Arch Linux desktop and system configuration {{{

deploy_dotfiles() { # {{{
  local -r deploy_script="${dotfiles_root}/scripts/deploy_dotfiles.sh"

  if [[ ! -x "${deploy_script}" ]]; then
    echo "ERROR: Dotfile deployment script is missing or not executable: ${deploy_script}"
    return 1
  fi

  echo ""
  echo "INFO: Deploying user configuration..."
  run_as_target_user "${deploy_script}"
} # }}}

setup_kanshi_local_profile() { # {{{
  local target_user_home=""
  target_user_home="$(target_home)" || {
    echo "ERROR: Could not identify the target home for the Kanshi profile."
    return 1
  }

  local -r kanshi_local_config="${target_user_home}/.config/kanshi/local.conf"
  if [[ ! -e "${kanshi_local_config}" && ! -L "${kanshi_local_config}" ]]; then
    # Machine-specific output identities stay outside the shared deployment
    # source and must survive later dotfile and bootstrap runs.
    run_as_target_user install -Dm0644 /dev/null "${kanshi_local_config}" || {
      echo "ERROR: Could not create local Kanshi profile: ${kanshi_local_config}"
      return 1
    }
    echo "INFO: Created local Kanshi profile: ${kanshi_local_config}"
  fi
} # }}}

setup_gtk_file_chooser_preferences() { # {{{
  echo ""
  echo "INFO: Applying GTK file chooser preferences..."

  if ! command -v gsettings &>/dev/null || ! command -v dbus-run-session &>/dev/null; then
    echo "ERROR: gsettings and dbus-run-session are required for GTK preferences."
    return 1
  fi

  local failed=false

  set_file_chooser_setting() {
    local -r schema="${1}"
    local -r key="${2}"
    local -r value="${3}"

    if ! run_as_target_user gsettings list-keys "${schema}" 2>/dev/null | grep -Fxq "${key}"; then
      echo "ERROR: Required GLib setting is unavailable: ${schema} ${key}"
      failed=true
      return
    fi

    run_as_target_user dbus-run-session -- gsettings set "${schema}" "${key}" "${value}" || {
      echo "ERROR: Failed to set GLib preference: ${schema} ${key}"
      failed=true
    }
  }

  local schema
  for schema in org.gtk.Settings.FileChooser org.gtk.gtk4.Settings.FileChooser; do
    set_file_chooser_setting "${schema}" clock-format 24h
    set_file_chooser_setting "${schema}" date-format with-time
    set_file_chooser_setting "${schema}" location-mode path-bar
    set_file_chooser_setting "${schema}" show-hidden false
    set_file_chooser_setting "${schema}" show-size-column true
    set_file_chooser_setting "${schema}" show-type-column true
    set_file_chooser_setting "${schema}" sort-column name
    set_file_chooser_setting "${schema}" sort-directories-first true
    set_file_chooser_setting "${schema}" sort-order ascending
    # Starting in the current directory avoids exposing a cross-application
    # recent-files view each time a file chooser opens.
    set_file_chooser_setting "${schema}" startup-mode cwd
  done
  set_file_chooser_setting org.gtk.gtk4.Settings.FileChooser view-type list

  [[ "${failed}" == "false" ]]
} # }}}

setup_gtk_bookmarks() { # {{{
  local target_user_home=""
  target_user_home="$(target_home)" || {
    echo "ERROR: Could not identify the target home for GTK bookmarks."
    return 1
  }

  local -r gtk_bookmarks="${target_user_home}/.config/gtk-3.0/bookmarks"
  local -a bookmark_specs=(
    "DOWNLOAD:Downloads"
    "DOCUMENTS:Documents"
    "PICTURES:Pictures"
    "MUSIC:Music"
    "VIDEOS:Videos"
    "PROJECTS:Projects"
  )
  local bookmark_spec xdg_name bookmark_label bookmark_dir bookmark_uri
  local bookmark_content=""

  for bookmark_spec in "${bookmark_specs[@]}"; do
    xdg_name="${bookmark_spec%%:*}"
    bookmark_label="${bookmark_spec#*:}"
    bookmark_dir="${target_user_home}/${bookmark_label}"
    if command -v xdg-user-dir >/dev/null 2>&1; then
      bookmark_dir="$(run_as_target_user xdg-user-dir "${xdg_name}" 2>/dev/null || true)"
    fi
    [[ -d "${bookmark_dir}" ]] || continue

    bookmark_uri=""
    if command -v gio >/dev/null 2>&1; then
      bookmark_uri="$(run_as_target_user env LC_ALL=C gio info "${bookmark_dir}" 2>/dev/null | sed -n 's/^uri: //p' | head -n 1)"
    fi
    if [[ -z "${bookmark_uri}" ]]; then
      bookmark_uri="file://${bookmark_dir}"
    fi
    printf -v bookmark_content '%s%s %s\n' "${bookmark_content}" "${bookmark_uri}" "${bookmark_label}"
  done

  run_as_target_user mkdir -p "$(dirname "${gtk_bookmarks}")" || {
    echo "ERROR: Could not create the GTK config directory."
    return 1
  }
  if ! printf '%s' "${bookmark_content}" | run_as_target_user tee "${gtk_bookmarks}" >/dev/null; then
    echo "ERROR: Could not write GTK bookmarks: ${gtk_bookmarks}"
    return 1
  fi
  echo "INFO: Applied GTK Places shortcuts: ${gtk_bookmarks}"
} # }}}

validate_sway_desktop_configuration() { # {{{
  local target_user_home=""
  target_user_home="$(target_home)" || {
    echo "ERROR: Could not determine the target home for Sway validation."
    return 1
  }

  local -r sway_config="${target_user_home}/.config/sway/config"
  local -r sway_launcher="${dotfiles_root}/config/system/sway/start-sway"

  if [[ ! -f "${sway_launcher}" ]]; then
    echo "ERROR: Required Sway session launcher is missing: ${sway_launcher}"
    return 1
  fi
  if [[ ! -f "${sway_config}" ]]; then
    echo "ERROR: Deployed Sway configuration is missing: ${sway_config}"
    return 1
  fi
  if ! command -v sway &>/dev/null; then
    echo "ERROR: sway is required to validate the deployed desktop configuration."
    return 1
  fi
  if ! bash -n "${sway_launcher}"; then
    echo "ERROR: Sway session launcher failed shell syntax validation."
    return 1
  fi

  local -a sway_check_command=(sway -C -c "${sway_config}")
  if [[ -d /sys/module/nvidia_drm || -d /sys/module/nvidia ]]; then
    sway_check_command=(sway --unsupported-gpu -C -c "${sway_config}")
  fi
  if ! run_as_target_user env \
    WLR_BACKENDS=headless \
    WLR_RENDERER=pixman \
    WLR_LIBINPUT_NO_DEVICES=1 \
    "${sway_check_command[@]}"; then
    echo "ERROR: Deployed Sway configuration failed validation."
    return 1
  fi
} # }}}

validate_deployed_user_units() { # {{{
  local target_user_home=""
  target_user_home="$(target_home)" || {
    echo "ERROR: Could not determine the target home for user-unit validation."
    return 1
  }

  if ! command -v systemd-analyze &>/dev/null; then
    echo "ERROR: systemd-analyze is required to validate deployed user units."
    return 1
  fi

  local -r user_unit_dir="${target_user_home}/.config/systemd/user"
  local -a user_units=()
  local unit_file
  for unit_file in "${user_unit_dir}"/*.service "${user_unit_dir}"/*.target "${user_unit_dir}"/*.path "${user_unit_dir}"/*.timer; do
    if [[ -f "${unit_file}" ]]; then
      user_units+=("${unit_file}")
    fi
  done
  if ((${#user_units[@]} == 0)); then
    echo "ERROR: Deployed user units are missing: ${user_unit_dir}"
    return 1
  fi
  if ! run_as_target_user systemd-analyze --user --man=no --generators=no verify "${user_units[@]}"; then
    echo "ERROR: Deployed user units failed validation."
    return 1
  fi
} # }}}

setup_desktop_system_integration() { # {{{
  echo ""
  echo "INFO: Configuring desktop system integration..."

  # Renaming the logind policy also requires explicit removal of its old derived
  # file under /etc; keep both names stable unless that cleanup is in scope.
  local -r logind_config="${dotfiles_root}/config/system/systemd/logind.conf.d/60-sway-desktop.conf"
  local -r system_sound_config="${dotfiles_root}/config/system/modprobe.d/60-silent-system-sounds.conf"
  local source_file
  for source_file in "${logind_config}" "${system_sound_config}"; do
    if [[ ! -f "${source_file}" ]]; then
      echo "ERROR: Required desktop system configuration is missing: ${source_file}"
      return 1
    fi
  done
  local failed=false
  run_as_root install -Dm0644 "${logind_config}" /etc/systemd/logind.conf.d/60-sway-desktop.conf || {
    echo "ERROR: Failed to install the systemd-logind desktop policy."
    failed=true
  }
  run_as_root install -Dm0644 "${system_sound_config}" /etc/modprobe.d/60-silent-system-sounds.conf || {
    echo "ERROR: Failed to install the silent system sound policy."
    failed=true
  }
  if [[ "${failed}" == "true" ]]; then
    return 1
  fi
} # }}}

set_graphical_boot_target() { # {{{
  if ! command -v systemctl &>/dev/null; then
    echo "ERROR: systemctl is required to configure the graphical boot target."
    return 1
  fi
  run_as_root systemctl set-default graphical.target || {
    echo "ERROR: Failed to set graphical.target as the default boot target."
    return 1
  }
} # }}}

setup_desktop_system_services() { # {{{
  echo ""
  echo "INFO: Configuring desktop system services..."

  if ! command -v systemctl &>/dev/null; then
    echo "ERROR: systemctl is required for desktop system services."
    return 1
  fi

  enable_desktop_service() {
    local unit_name
    for unit_name in "${@}"; do
      if ! systemctl list-unit-files "${unit_name}" >/dev/null 2>&1; then
        echo "WARN: Service unit is unavailable: ${unit_name}"
        continue
      fi

      run_as_root systemctl enable --now "${unit_name}" || {
        echo "WARN: Failed to enable desktop service: ${unit_name}"
      }
    done
  }

  enable_desktop_service \
    power-profiles-daemon.service \
    switcheroo-control.service \
    bluetooth.service

  # Keep printing available without a scheduler process on machines that do
  # not use it. Disabling cups.service also disables its associated socket and
  # path units, so explicitly restore only socket activation.
  if systemctl list-unit-files cups.service >/dev/null 2>&1; then
    run_as_root systemctl disable --now cups.service || {
      echo "WARN: Failed to disable the always-on CUPS service."
    }
  fi
  enable_desktop_service cups.socket

  if command -v powerprofilesctl &>/dev/null; then
    run_as_root powerprofilesctl set balanced || {
      echo "WARN: Failed to select the balanced power profile."
    }
  fi
} # }}}

setup_sway_login_session() { # {{{
  echo ""
  echo "INFO: Configuring the Sway login session..."

  local -r greetd_config="${dotfiles_root}/config/system/greetd/config.toml"
  local -r regreet_config="${dotfiles_root}/config/system/greetd/regreet.toml"
  local -r regreet_style="${dotfiles_root}/config/system/greetd/regreet.css"
  local -r greetd_pam_config="${dotfiles_root}/config/system/pam.d/greetd"
  local -r sway_session_file="${dotfiles_root}/config/system/wayland-sessions/sway.desktop"
  local -r sway_launcher="${dotfiles_root}/config/system/sway/start-sway"

  local source_file
  for source_file in "${greetd_config}" "${regreet_config}" "${regreet_style}" "${greetd_pam_config}" "${sway_session_file}" "${sway_launcher}"; do
    if [[ ! -f "${source_file}" ]]; then
      echo "ERROR: Required Sway system configuration is missing: ${source_file}"
      return 1
    fi
  done
  if ! command -v systemctl &>/dev/null; then
    echo "ERROR: systemctl is required for the maintained Sway login session."
    return 1
  fi
  validate_sway_desktop_configuration || return 1
  validate_deployed_user_units || return 1

  local failed=false
  run_as_root install -Dm0644 "${greetd_config}" /etc/greetd/config.toml || {
    echo "ERROR: Failed to install the greetd configuration."
    failed=true
  }
  run_as_root install -Dm0644 "${regreet_config}" /etc/greetd/regreet.toml || {
    echo "ERROR: Failed to install the ReGreet configuration."
    failed=true
  }
  run_as_root install -Dm0644 "${regreet_style}" /etc/greetd/regreet.css || {
    echo "ERROR: Failed to install the ReGreet stylesheet."
    failed=true
  }
  run_as_root install -Dm0644 "${greetd_pam_config}" /etc/pam.d/greetd || {
    echo "ERROR: Failed to install the greetd PAM configuration."
    failed=true
  }
  run_as_root install -Dm0644 "${sway_session_file}" /usr/local/share/wayland-sessions/sway.desktop || {
    echo "ERROR: Failed to install the Sway session descriptor."
    failed=true
  }
  run_as_root install -Dm0755 "${sway_launcher}" /usr/local/bin/start-sway || {
    echo "ERROR: Failed to install the Sway session launcher."
    failed=true
  }
  if [[ "${failed}" == "true" ]]; then
    return 1
  fi

  # The boot target is desktop-neutral, but switch it only after the maintained
  # login session has passed validation and its files were installed.
  set_graphical_boot_target || return 1

  # Display managers own the same display-manager.service alias. Switch it only
  # after required validation and installation have completed, and do not start
  # greetd inside the current graphical session.
  run_as_root systemctl enable --force greetd.service || {
    echo "ERROR: Failed to enable greetd.service."
    return 1
  }

  echo "DONE: Sway and greetd are configured."
} # }}}

setup_locale() { # {{{
  if locale -a 2>/dev/null | grep -Fxq "en_US.utf8" && localectl status 2>/dev/null | grep -Eq '^System Locale: LANG=en_US\.UTF-8$'; then
    echo "DONE: System locale is already UTF-8."
    return 0
  fi

  echo ""
  echo "INFO: Configuring system locale to en_US.UTF-8..."
  local failed=false

  if [[ -f /etc/locale.gen ]]; then
    if grep -Eq '^#?en_US\.UTF-8 UTF-8$' /etc/locale.gen; then
      run_as_root sed -i 's/^#\(en_US\.UTF-8 UTF-8\)$/\1/' /etc/locale.gen || {
        echo "WARN: Failed to enable en_US.UTF-8 in /etc/locale.gen."
        failed=true
      }
    else
      echo "en_US.UTF-8 UTF-8" | run_as_root tee -a /etc/locale.gen >/dev/null || {
        echo "WARN: Failed to add en_US.UTF-8 to /etc/locale.gen."
        failed=true
      }
    fi
  else
    echo "WARN: /etc/locale.gen not found. locale-gen may not generate en_US.UTF-8."
    failed=true
  fi

  if command -v locale-gen &>/dev/null; then
    run_as_root locale-gen || {
      echo "WARN: Failed to generate locales."
      failed=true
    }
  else
    echo "WARN: locale-gen is not available. Skipping locale generation."
    failed=true
  fi

  run_as_root localectl set-locale LANG=en_US.UTF-8 || {
    echo "WARN: Failed to configure system locale."
    failed=true
  }

  [[ "${failed}" == "false" ]]
} # }}}

setup_date_and_time() { # {{{
  if ! command -v timedatectl &>/dev/null; then
    echo "ERROR: timedatectl is not available. Date and time setup cannot continue."
    return 1
  fi

  echo ""
  echo "INFO: Configuring automatic time and the Asia/Seoul time zone..."
  local failed=false

  run_as_root timedatectl set-ntp true || {
    echo "WARN: Failed to enable automatic time synchronization."
    failed=true
  }

  run_as_root timedatectl set-timezone Asia/Seoul || {
    echo "WARN: Failed to set the system time zone to Asia/Seoul."
    failed=true
  }

  [[ "${failed}" == "false" ]]
} # }}}

set_default_shell_to_bash() { # {{{
  # Use the fixed Arch package path so the login shell does not depend on the
  # caller's PATH.
  local -r bash_path="/usr/bin/bash"
  if [[ ! -x "${bash_path}" ]]; then
    echo "ERROR: Bash is not installed at ${bash_path}."
    return 1
  fi

  if ! command -v chsh &>/dev/null; then
    echo "ERROR: chsh is required to configure the maintained login shell."
    return 1
  fi

  if [[ -f /etc/shells ]] && ! grep -Fxq "${bash_path}" /etc/shells; then
    echo "ERROR: ${bash_path} is not listed in /etc/shells."
    return 1
  fi

  local target_user_name=""
  target_user_name="$(target_user)" || {
    echo "ERROR: Could not identify a non-root target user for login shell setup."
    return 1
  }

  local current_shell=""
  current_shell="$(getent passwd "${target_user_name}" | cut -d: -f7)"
  if [[ -z "${current_shell}" ]]; then
    echo "ERROR: Could not find the login shell for ${target_user_name}."
    return 1
  fi

  if [[ "${current_shell}" == "${bash_path}" ]]; then
    echo "DONE: Login shell for ${target_user_name} is already ${bash_path}"
    return 0
  fi

  echo ""
  echo "INFO: Changing login shell for ${target_user_name} to ${bash_path}..."
  run_as_root chsh -s "${bash_path}" "${target_user_name}"
} # }}}

# Arch Linux desktop and system configuration }}}

# User tool setup {{{

create_default_directories() { # {{{
  local target_user_name=""
  target_user_name="$(target_user)" || {
    echo "ERROR: Could not identify a non-root target user for default directory setup."
    return 1
  }

  local target_group=""
  target_group="$(id -gn "${target_user_name}" 2>/dev/null)" || {
    echo "ERROR: Could not identify primary group for ${target_user_name}."
    return 1
  }

  local home_dir=""
  home_dir="$(target_home "${target_user_name}")" || {
    echo "ERROR: Could not identify a non-root target home for default directory setup."
    return 1
  }
  local failed=false

  create_user_dir() {
    local dir_path="${1}"
    run_as_root install -d -m 0755 -o "${target_user_name}" -g "${target_group}" "${dir_path}"
  }

  create_user_dir "${home_dir}/Downloads" || failed=true
  create_user_dir "${home_dir}/Documents" || failed=true
  create_user_dir "${home_dir}/Music" || failed=true
  create_user_dir "${home_dir}/Pictures" || failed=true
  create_user_dir "${home_dir}/Videos" || failed=true
  local -r projects_home="${home_dir}/Projects"
  create_user_dir "${projects_home}" || failed=true
  create_user_dir "${projects_home}/work" || failed=true
  create_user_dir "${projects_home}/personal" || failed=true
  create_user_dir "${projects_home}/opensource" || failed=true
  create_user_dir "${projects_home}/playground" || failed=true
  create_user_dir "${projects_home}/experiments" || failed=true

  if command -v xdg-user-dirs-update &>/dev/null; then
    run_as_target_user xdg-user-dirs-update || {
      echo "WARN: Failed to register standard XDG user directories."
      failed=true
    }
  else
    echo "WARN: xdg-user-dirs-update is not available."
    failed=true
  fi

  [[ "${failed}" == "false" ]]
} # }}}

install_yay() { # {{{
  # yay is convenient for a personal Arch workstation, but AUR availability is
  # outside this repo's control. Failure here should not block the rest of setup.
  if run_as_target_user bash -lc "command -v yay >/dev/null 2>&1"; then
    echo "DONE: yay is already installed."
    return 0
  fi

  if [[ "${_pacman_mutations_allowed}" != "true" ]]; then
    echo "ERROR: Skipping yay installation because the full pacman upgrade did not complete."
    return 1
  fi

  local home_dir=""
  home_dir="$(target_home)" || {
    echo "WARN: Could not identify a non-root target home. Skipping yay setup."
    return 0
  }

  local -r xdg_cache_home="${XDG_CACHE_HOME:-${home_dir}/.cache}"
  local -r yay_dir="${xdg_cache_home}/dotfiles/bootstrap/yay"
  run_as_target_user mkdir -pv "$(dirname "${yay_dir}")"

  if [[ ! -d "${yay_dir}" ]]; then
    echo ""
    echo "INFO: Cloning yay from AUR..."
    run_as_target_user git clone https://aur.archlinux.org/yay.git "${yay_dir}" || {
      echo "WARN: Failed to clone yay from AUR."
      return 0
    }
  elif [[ -d "${yay_dir}/.git" ]]; then
    echo ""
    echo "INFO: Updating yay AUR checkout..."
    run_as_target_user git -C "${yay_dir}" pull --ff-only || {
      echo "WARN: Failed to update yay AUR checkout."
      return 0
    }
  else
    echo "WARN: Skipping yay setup: ${yay_dir} exists but is not a git repository."
    return 0
  fi

  echo ""
  echo "INFO: Building and installing yay..."
  run_as_target_user bash -lc "cd \"${yay_dir}\" && makepkg --syncdeps --install --needed --noconfirm" || {
    echo "WARN: Failed to build or install yay."
  }
} # }}}

install_mise_managed_tools() { # {{{
  local mise_config="${dotfiles_root}/config/mise/config.toml"

  if [[ ! -f "${mise_config}" ]]; then
    echo "ERROR: mise config not found: ${mise_config}"
    return 1
  fi

  if [[ ! -x /usr/bin/mise ]]; then
    echo "ERROR: The Arch mise package is not available at /usr/bin/mise."
    return 1
  fi

  echo ""
  echo "INFO: Installing mise-managed tools from ${mise_config}..."
  # Expand positional parameters inside the target user's shell, not here.
  # shellcheck disable=SC2016
  run_as_target_user bash -lc '
    /usr/bin/mise trust --yes "${1}" || true
    /usr/bin/mise install --yes --cd "$(dirname "${1}")"
  ' bash "${mise_config}"
} # }}}

_retry_mise_cli_install() { # {{{
  local -r display_name="${1:-}"
  local -r command_name="${2:-}"
  local -r tool_id="${3:-}"

  if [[ -z "${display_name}" || -z "${command_name}" || -z "${tool_id}" ]]; then
    echo "ERROR: _retry_mise_cli_install requires a display name, command, and mise tool ID."
    return 1
  fi

  # Expand positional parameters inside the target user's shell, not here.
  # shellcheck disable=SC2016
  if run_as_target_user bash -lc '
    /usr/bin/mise which "${1}" >/dev/null 2>&1
  ' bash "${command_name}"; then
    echo "DONE: ${display_name} is already installed."
    return 0
  fi

  echo ""
  echo "INFO: Retrying ${display_name} installation..."
  # shellcheck disable=SC2016
  if run_as_target_user bash -lc '
    /usr/bin/mise install --yes "${1}@latest"
  ' bash "${tool_id}"; then
    echo "DONE: ${display_name} installation completed."
    return 0
  fi

  echo "WARN: Failed to install ${display_name}."
  echo "INFO: Retry later: mise install ${tool_id}@latest"
  return 1
} # }}}

retry_mise_cli_installs() { # {{{
  # The main mise task installs every configured tool first. Retry selected
  # release-backed CLIs separately because parallel resolution can hit upstream
  # API rate limits without preventing the remaining tools from being installed.
  if [[ ! -x /usr/bin/mise ]]; then
    echo "WARN: mise is not installed. Skipping CLI installation retries."
    return 0
  fi

  local failed=false
  _retry_mise_cli_install "Codex CLI" codex "aqua:openai/codex" || failed=true

  if [[ "${failed}" == "true" ]]; then
    echo "WARN: One or more optional CLI installation retries failed."
  fi

  return 0
} # }}}

install_nerd_font() { # {{{
  local -r font_name="CommitMonoNerdFontMono"
  # Nerd Fonts release assets use versioned URLs, and the extraction below
  # relies on the reviewed archive layout. Reconsider this pin when updating
  # Nerd Fonts, its checksum, or the CommitMono asset layout.
  local -r version="v3.4.0"
  local -r archive_sha256="fa658c4056a304398aea6459146700383a64a82d5bd6ece267e1375e7aa67f23"
  local -r download_url="https://github.com/ryanoasis/nerd-fonts/releases/download/${version}/CommitMono.zip"
  local home_dir=""
  home_dir="$(target_home)" || {
    echo "WARN: Could not identify a non-root target home. Skipping font setup."
    return 0
  }

  local -r xdg_data_home="${XDG_DATA_HOME:-${home_dir}/.local/share}"
  local -r font_dir="${xdg_data_home}/fonts"

  install_commit_mono_nerd_font() {
    if find "${font_dir}" -name "*${font_name}*" | grep -q "."; then
      echo "DONE: ${font_name} is already installed. Skipping..."
      return 0
    fi

    echo ""
    echo "INFO: Installing ${font_name} ${version}..."

    local -r xdg_cache_home="${XDG_CACHE_HOME:-${home_dir}/.cache}"
    local -r temp_dir="${xdg_cache_home}/dotfiles/bootstrap/nerd-fonts"
    local -r archive_path="${temp_dir}/CommitMono.zip"
    run_as_target_user mkdir -pv "${temp_dir}"

    echo ""
    echo "INFO: Downloading font archive..."
    run_as_target_user curl -fLo "${archive_path}" "${download_url}" --retry 3 || {
      echo "WARN: Failed to download ${font_name}."
      return 0
    }

    local actual_sha256=""
    actual_sha256="$(run_as_target_user sha256sum "${archive_path}")" || {
      echo "WARN: Failed to calculate ${font_name} archive checksum."
      return 0
    }
    actual_sha256="${actual_sha256%% *}"
    if [[ "${actual_sha256}" != "${archive_sha256}" ]]; then
      echo "WARN: ${font_name} archive checksum does not match ${version}."
      return 0
    fi

    echo ""
    echo "INFO: Extracting files..."
    run_as_target_user unzip -o "${archive_path}" -d "${temp_dir}" || {
      echo "WARN: Failed to extract ${font_name} archive."
      return 0
    }

    run_as_target_user mkdir -pv "${font_dir}"

    run_as_target_user bash -lc "find \"${temp_dir}\" -name 'CommitMonoNerdFontMono-*.otf' -exec cp {} \"${font_dir}/\" \;" || {
      echo "WARN: Failed to copy ${font_name} files."
      return 0
    }

    echo ""
    echo "INFO: Updating font cache..."
    run_as_target_user fc-cache -f "${font_dir}" || {
      echo "WARN: Failed to update font cache."
      return 0
    }

    echo "DONE: Font installation completed successfully!"
  }
  install_commit_mono_nerd_font
} # }}}

# User tool setup }}}

# Privacy and security {{{

setup_system_data_retention() { # {{{
  echo ""
  echo "INFO: Applying system data retention policy..."

  local -r journald_config="${dotfiles_root}/config/system/systemd/journald.conf.d/60-privacy-retention.conf"
  if [[ ! -f "${journald_config}" ]]; then
    echo "ERROR: systemd-journald retention policy is missing: ${journald_config}"
    return 1
  fi

  run_as_root install -Dm0644 "${journald_config}" /etc/systemd/journald.conf.d/60-privacy-retention.conf || {
    echo "ERROR: Failed to install the systemd-journald retention policy."
    return 1
  }
  run_as_root systemctl restart systemd-journald.service || {
    echo "ERROR: Failed to restart systemd-journald."
    return 1
  }
  run_as_root journalctl --rotate --vacuum-time=1day || {
    echo "ERROR: Failed to remove system journal entries older than one day."
    return 1
  }

  echo "DONE: System journal retention is limited to one day."
} # }}}

setup_failed_authentication_policy() { # {{{
  echo ""
  echo "INFO: Applying failed authentication policy..."

  local -r faillock_config="${dotfiles_root}/config/system/security/faillock.conf"
  if [[ ! -f "${faillock_config}" ]]; then
    echo "ERROR: Failed authentication policy is missing: ${faillock_config}"
    return 1
  fi

  run_as_root install -Dm0644 "${faillock_config}" /etc/security/faillock.conf || {
    echo "ERROR: Failed to install the failed authentication policy."
    return 1
  }

  echo "DONE: Failed authentication policy installed."
} # }}}

setup_firefox_policy() { # {{{
  echo ""
  echo "INFO: Applying Firefox system policy..."

  local -r firefox_policy="${dotfiles_root}/config/system/firefox/policies/policies.json"
  if [[ ! -f "${firefox_policy}" ]]; then
    echo "ERROR: Firefox system policy is missing: ${firefox_policy}"
    return 1
  fi

  run_as_root install -Dm0644 "${firefox_policy}" /etc/firefox/policies/policies.json || {
    echo "ERROR: Failed to install the Firefox system policy."
    return 1
  }

  echo "DONE: Firefox system policy installed."
} # }}}

# Network privacy {{{

setup_basic_firewall() { # {{{
  setup_firewalld_firewall() {
    echo ""
    echo "INFO: Configuring firewalld firewall..."

    # firewalld:
    # - Existing zones and rules are preserved; do not reset the firewall.
    # - On a fresh local bootstrap, remove the packaged public-zone SSH allow
    #   rule. Preserve user-owned overrides and active remote bootstrap access.
    # - Add allow rules manually for inbound SSH or dev servers.
    #   Examples:
    #     sudo firewall-cmd --permanent --add-service=ssh
    #     sudo firewall-cmd --permanent --add-port=8080/tcp
    #     sudo firewall-cmd --reload
    #
    # Commands:
    # - Review rules: sudo firewall-cmd --list-all
    # - Disable firewalld: sudo systemctl disable --now firewalld.service
    if command -v systemctl &>/dev/null; then
      run_as_root systemctl enable --now firewalld.service || {
        echo "WARN: Failed to enable firewalld."
      }
    else
      echo "WARN: systemctl is not available. Skipping firewalld service setup."
      return 0
    fi

    local -r public_zone_override="/etc/firewalld/zones/public.xml"
    if [[ -n "${SSH_CONNECTION:-}" ]]; then
      echo "INFO: SSH session detected. Ensuring inbound SSH remains allowed in firewalld..."
      run_as_root firewall-cmd --permanent --add-service=ssh || {
        echo "WARN: Failed to add an SSH allow rule in firewalld."
      }

      run_as_root firewall-cmd --reload || {
        echo "WARN: Failed to reload firewalld after adding SSH allow rule."
      }
    elif [[ -e "${public_zone_override}" || -L "${public_zone_override}" ]]; then
      echo "INFO: Preserving the user-managed firewalld public zone."
    else
      local default_zone=""
      if ! default_zone="$(firewall-cmd --get-default-zone)"; then
        echo "WARN: Could not inspect the default firewalld zone; preserving its rules."
      elif [[ "${default_zone}" != "public" ]]; then
        echo "INFO: Preserving the non-default firewalld zone policy: ${default_zone}"
      else
        local ssh_query_status=0
        run_as_root firewall-cmd --permanent --zone=public --query-service=ssh >/dev/null
        ssh_query_status=$?
        if ((ssh_query_status == 0)); then
          echo "INFO: Removing the packaged SSH allow rule from the fresh public zone..."
          if run_as_root firewall-cmd --permanent --zone=public --remove-service=ssh; then
            run_as_root firewall-cmd --reload || {
              echo "WARN: Failed to reload firewalld after removing the packaged SSH rule."
            }
          else
            echo "WARN: Failed to remove the packaged SSH allow rule from firewalld."
          fi
        elif ((ssh_query_status != 1)); then
          echo "WARN: Could not inspect the public-zone SSH rule; preserving it."
        fi
      fi
    fi

    if command -v ufw &>/dev/null; then
      run_as_root systemctl disable --now ufw.service >/dev/null 2>&1 || true
    fi
  }

  setup_ufw_firewall() {
    echo ""
    echo "INFO: Configuring UFW firewall..."

    # UFW:
    # - Existing UFW rules are preserved; do not run "ufw reset".
    # - Add allow rules manually for inbound SSH or dev servers.
    #   Examples:
    #     sudo ufw allow 22/tcp     # SSH
    #     sudo ufw allow 8080/tcp   # HTTP server
    #
    # Commands:
    # - Review rules: sudo ufw status verbose
    # - Disable UFW logging: sudo ufw logging off
    # - Disable UFW: sudo ufw disable
    if command -v systemctl &>/dev/null; then
      run_as_root systemctl disable --now firewalld.service >/dev/null 2>&1 || true
    fi

    if [[ -n "${SSH_CONNECTION:-}" ]]; then
      echo "INFO: SSH session detected. Ensuring inbound SSH remains allowed before enabling UFW..."
      run_as_root ufw allow OpenSSH || run_as_root ufw allow 22/tcp || {
        echo "WARN: Failed to add an SSH allow rule before enabling UFW."
      }
    fi

    run_as_root ufw default deny incoming
    run_as_root ufw default allow outgoing
    run_as_root ufw logging low
    echo "y" | run_as_root ufw enable || {
      echo "WARN: Failed to enable UFW."
    }
    if command -v systemctl &>/dev/null; then
      run_as_root systemctl enable ufw.service >/dev/null 2>&1 || true
    fi
  }

  ufw_is_selected() {
    command -v ufw &>/dev/null || return 1

    # Treat UFW as selected only when it is active/enabled. This keeps firewalld
    # as the default when UFW merely exists on the system but is not in use.
    if command -v systemctl &>/dev/null; then
      systemctl is-active --quiet ufw.service || systemctl is-enabled --quiet ufw.service
      return
    fi

    run_as_root ufw status 2>/dev/null | grep -qi "^Status: active"
  }

  # firewalld is the selected default for this Arch/NetworkManager setup. Prefer it
  # when installed, disable UFW if both exist, and install firewalld when no
  # firewall backend exists. Use UFW only when it is active/enabled and firewalld
  # is not installed.
  if pacman -Qq firewalld >/dev/null 2>&1; then
    echo "INFO: Selected firewall backend: firewalld (installed Arch default)."
    setup_firewalld_firewall
  elif ufw_is_selected; then
    echo "INFO: Selected firewall backend: UFW (active or enabled)."
    setup_ufw_firewall
  else
    echo "INFO: Selected firewall backend: firewalld (default)."
    setup_firewalld_firewall
  fi
} # }}}

setup_networkmanager_privacy() { # {{{
  if ! command -v nmcli &>/dev/null; then
    if ! command -v systemctl &>/dev/null || ! systemctl list-unit-files NetworkManager.service >/dev/null 2>&1; then
      echo "WARN: NetworkManager is not installed. Skipping NetworkManager privacy settings."
      return 0
    fi
  fi

  local -r nm_privacy_config="${dotfiles_root}/config/system/NetworkManager/conf.d/99-privacy.conf"
  local -r resolved_privacy_config="${dotfiles_root}/config/system/systemd/resolved.conf.d/60-network-privacy.conf"

  if [[ ! -f "${nm_privacy_config}" ]]; then
    echo "ERROR: NetworkManager privacy config not found: ${nm_privacy_config}"
    return 1
  fi
  if [[ ! -f "${resolved_privacy_config}" ]]; then
    echo "ERROR: systemd-resolved privacy config not found: ${resolved_privacy_config}"
    return 1
  fi
  if ! command -v systemctl &>/dev/null || ! systemctl list-unit-files systemd-resolved.service >/dev/null 2>&1; then
    echo "ERROR: systemd-resolved is required for per-connection encrypted DNS."
    return 1
  fi
  if [[ -d /etc/resolv.conf && ! -L /etc/resolv.conf ]]; then
    echo "ERROR: /etc/resolv.conf is a directory; refusing to replace it."
    return 1
  fi

  run_as_root install -Dm0644 "${nm_privacy_config}" /etc/NetworkManager/conf.d/99-privacy.conf || {
    echo "ERROR: Failed to install NetworkManager privacy config."
    return 1
  }
  run_as_root install -Dm0644 "${resolved_privacy_config}" /etc/systemd/resolved.conf.d/60-network-privacy.conf || {
    echo "ERROR: Failed to install the systemd-resolved privacy config."
    return 1
  }

  # Start the resolver before redirecting libc clients to its local stub. Reload
  # NetworkManager first so active links provide DNS state before the symlink is
  # changed; this ordering avoids creating a local stub with no upstream state.
  run_as_root systemctl enable --now systemd-resolved.service || {
    echo "ERROR: Failed to enable systemd-resolved."
    return 1
  }
  run_as_root systemctl enable --now NetworkManager.service || {
    echo "ERROR: Failed to enable NetworkManager."
    return 1
  }
  run_as_root systemctl reload NetworkManager.service || {
    echo "ERROR: Failed to reload NetworkManager with systemd-resolved integration."
    return 1
  }

  if [[ ! -f /run/systemd/resolve/stub-resolv.conf ]]; then
    echo "ERROR: systemd-resolved did not create its stub resolver file."
    return 1
  fi
  run_as_root ln -sfn /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf || {
    echo "ERROR: Failed to connect /etc/resolv.conf to systemd-resolved."
    return 1
  }
  if [[ "$(readlink -f /etc/resolv.conf 2>/dev/null)" != "/run/systemd/resolve/stub-resolv.conf" ]]; then
    echo "ERROR: /etc/resolv.conf does not resolve to the systemd-resolved stub."
    return 1
  fi

  echo "DONE: NetworkManager and systemd-resolved own per-connection DNS policy."
} # }}}

setup_basic_network_privacy() { # {{{
  # Goal:
  # - Provide conservative desktop/laptop defaults for everyday Arch Linux use.
  # - Block unsolicited inbound traffic with one firewall backend.
  # - Enable Wi-Fi MAC randomization and IPv6 privacy addresses.
  # - Use systemd-resolved so each NetworkManager connection can select strict
  #   encrypted DNS or retain captive-portal and connection-owned DNS behavior,
  #   including VPNs.
  #
  # Non-goals:
  # - Do not implement aggressive network hardening.
  # - Do not force a public DNS provider, override per-connection routing, VPN
  #   split DNS, or existing firewall rules beyond the selected backend's policy.
  # - Do not run "ufw reset" or "firewall-cmd --complete-reload" style resets.
  echo ""
  echo "INFO: Applying basic desktop network privacy settings..."

  setup_basic_firewall || return 1
  setup_networkmanager_privacy || return 1
} # }}}

# Network privacy }}}

# Trusted network defaults {{{

setup_trusted_network_profiles() { # {{{
  if ! command -v nmcli &>/dev/null; then
    echo "ERROR: NetworkManager is required to apply trusted network defaults."
    return 1
  fi
  if ! systemctl is-active --quiet systemd-resolved.service; then
    echo "ERROR: systemd-resolved is not active; trusted defaults were not applied."
    return 1
  fi
  if [[ "$(readlink -f /etc/resolv.conf 2>/dev/null)" != "/run/systemd/resolve/stub-resolv.conf" ]]; then
    echo "ERROR: /etc/resolv.conf is not connected to systemd-resolved; trusted defaults were not applied."
    return 1
  fi

  local -r trusted_ipv4_dns="1.1.1.1#one.one.one.one 1.0.0.1#one.one.one.one"
  local profile_list
  local profile_uuid
  local connection_type
  local cloned_mac_property
  local applied_profile_count=0
  local failed_profile_count=0

  profile_list="$(run_as_root nmcli --terse --escape no --fields UUID,TYPE connection show)" || {
    echo "ERROR: Failed to list NetworkManager connection profiles."
    return 1
  }

  while IFS=: read -r profile_uuid connection_type; do
    [[ -n "${profile_uuid}" ]] || continue

    case "${connection_type}" in
      802-11-wireless) cloned_mac_property="802-11-wireless.cloned-mac-address" ;;
      802-3-ethernet) cloned_mac_property="802-3-ethernet.cloned-mac-address" ;;
      *) continue ;;
    esac

    if run_as_root nmcli connection modify uuid "${profile_uuid}" \
      "${cloned_mac_property}" random \
      connection.dns-over-tls yes \
      ipv4.ignore-auto-dns yes \
      ipv4.dns "${trusted_ipv4_dns}" \
      ipv6.method disabled \
      ipv6.ignore-auto-dns yes \
      ipv6.dns ""; then
      ((applied_profile_count += 1))
    else
      echo "ERROR: Failed to apply trusted defaults to profile UUID: ${profile_uuid}"
      ((failed_profile_count += 1))
    fi
  done <<<"${profile_list}"

  if ((applied_profile_count == 0 && failed_profile_count == 0)); then
    echo "WARN: No Wi-Fi or Ethernet profiles exist yet; no trusted defaults were applied."
    return 0
  fi
  if ((failed_profile_count > 0)); then
    echo "ERROR: Failed to apply trusted defaults to ${failed_profile_count} profile(s)."
    return 1
  fi

  echo "DONE: Trusted defaults saved to ${applied_profile_count} profile(s); they take effect on next activation."
} # }}}

# Trusted network defaults }}}

# Privacy and security }}}

# Completion notice {{{

show_completion_notice() { # {{{
  local -a failed_tasks=("${@}")

  echo ""
  if ((${#failed_tasks[@]} > 0)); then
    echo "ERROR: Bootstrap reached the end with failed tasks:"
    printf "  - %s\n" "${failed_tasks[@]}"
    echo "INFO: Review the failures above, fix their causes, and rerun the bootstrap."
    return 1
  fi

  echo "DONE: Bootstrap complete. Reboot to start greetd and select Sway."
  echo "INFO: If WARN lines appeared, review them before rebooting."
  echo ""
  echo "Reboot command:"
  echo "  sudo reboot"
} # }}}

# Completion notice }}}

# Main {{{

main() { # {{{
  start_logging

  if (($# > 0)); then
    echo "ERROR: bootstrap.sh does not accept options."
    echo "   Run without arguments."
    exit 1
  fi

  if ! is_supported_platform; then
    echo "ERROR: Unsupported platform."
    echo "   bootstrap.sh supports the maintained Arch Linux platform only."
    exit 1
  fi

  refuse_root_execution
  find_and_move_to_dotfiles_root || exit 1

  local -a tasks=(
    show_script_info
    upgrade_packages
    install_base_packages
    install_development_packages
    install_desktop_foundation_packages
    install_sway_session_packages
    install_desktop_application_packages
    setup_flatpak_remote
    setup_local_container_runtime
    handle_hardware_drivers
    setup_alsa_auto_mute
    setup_locale
    setup_date_and_time
    set_default_shell_to_bash
    create_default_directories
    deploy_dotfiles
    setup_kanshi_local_profile
    setup_gtk_file_chooser_preferences
    setup_gtk_bookmarks
    setup_desktop_system_integration
    setup_desktop_system_services
    setup_sway_login_session
    install_yay
    install_mise_managed_tools
    retry_mise_cli_installs
    install_nerd_font
    setup_system_data_retention
    setup_failed_authentication_policy
    setup_firefox_policy
    setup_basic_network_privacy
    setup_trusted_network_profiles
  )
  local -a failed_tasks=()

  local task
  for task in "${tasks[@]}"; do
    if declare -f "${task}" >/dev/null; then
      echo "============================================================"
      echo "${task}"
      echo "============================================================"
      if ! "${task}"; then
        echo "ERROR: Task failed; continuing bootstrap: ${task}"
        failed_tasks+=("${task}")
      fi
      echo ""
      echo ""
      echo ""
    else
      echo "ERROR: Task function not found; continuing bootstrap: ${task}"
      failed_tasks+=("${task}")
    fi
  done

  show_completion_notice "${failed_tasks[@]}"
} # }}}

# Main }}}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "${@}"
fi
