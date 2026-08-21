#!/usr/bin/env bash

# Bootstrap Arch Linux from a minimal/non-graphical install to a personal Sway desktop.
# Keep the OS baseline Arch-native and the graphical session Wayland-first.

# Common helpers and environment detection {{{

start_logging() { # {{{
  local -r log_dir="${HOME}/tmp/logs"
  local -r log_file="${log_dir}/$(date +%Y%m%d-%H%M%S)-setup-arch-bootstrap.log"

  if ! command -v tee >/dev/null 2>&1; then
    echo "ERROR: tee is required for logging." >&2
    exit 1
  fi

  if ! mkdir -p "${log_dir}"; then
    echo "ERROR: Could not create log directory: ${log_dir}" >&2
    exit 1
  fi

  if ! touch "${log_file}"; then
    echo "ERROR: Could not create log file: ${log_file}" >&2
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

refuse_root_execution() { # {{{
  if ((EUID == 0)); then
    echo "ERROR: Do not run setup_arch_bootstrap.sh as root."
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
  local group_name
  for group_name in "${@}"; do
    if ! pacman -Sgq "${group_name}" >/dev/null 2>&1; then
      echo "WARN: Skipping package group: ${group_name} (Not found in configured pacman repositories)"
      continue
    fi

    echo ""
    echo "INFO: Installing package group: ${group_name}"
    local -a group_packages=()
    mapfile -t group_packages < <(pacman -Sgq "${group_name}" | sort -u)
    install_package "${group_packages[@]}"
  done
} # }}}

upgrade_packages() { # {{{
  echo ""
  echo "INFO: Upgrading Arch Linux packages..."
  run_as_root pacman -Syu --noconfirm || {
    echo "ERROR: pacman system upgrade encountered an issue."
    return 1
  }
} # }}}

handle_hardware_drivers() { # {{{
  if ! command -v lspci &>/dev/null; then
    echo "WARN: lspci is not installed. Skipping hardware driver setup."
    return 0
  fi

  local pci_devices=""
  pci_devices="$(lspci 2>/dev/null || true)"
  local gpu_devices=""
  gpu_devices="$(grep -Ei "vga|3d|display" <<<"${pci_devices}" || true)"

  # Match GPU vendors only on VGA/3D/Display controller lines. Other PCI
  # devices can contain vendor names that would otherwise trigger false positives.
  if grep -qiE "intel" <<<"${gpu_devices}"; then
    echo "INFO: Intel graphics detected. Installing Intel Vulkan and VA-API drivers..."
    install_package vulkan-intel intel-media-driver
  fi

  if grep -qiE "advanced micro devices|amd/ati|ati technologies" <<<"${gpu_devices}"; then
    echo "INFO: AMD graphics detected. Installing AMD Vulkan driver..."
    install_package vulkan-radeon
  fi

  if ! grep -qi nvidia <<<"${gpu_devices}"; then
    echo "INFO: No NVIDIA hardware detected."
    return 0
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
    install_package nvidia-open
    installed_stock_nvidia_module=true
  fi

  if pacman -Qq linux-lts >/dev/null 2>&1; then
    install_package nvidia-open-lts
    installed_stock_nvidia_module=true
  fi

  if [[ "${installed_stock_nvidia_module}" == "false" ]]; then
    install_package nvidia-open-dkms
  fi

  install_package nvidia-utils

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
  install_package lib32-nvidia-utils lib32-vulkan-icd-loader

  # Rebuild initramfs after changing the GPU kernel module stack. Package hooks
  # usually cover this, but doing it here makes a nouveau -> nvidia-open bootstrap
  # transition explicit and easier to diagnose from the install log.
  # mkinitcpio may warn about optional firmware such as qat_6xxx. That module is
  # for Intel QuickAssist-style compression/encryption acceleration in server or
  # workstation-class hardware, not a normal personal desktop/laptop requirement.
  if command -v mkinitcpio &>/dev/null; then
    run_as_root mkinitcpio -P || {
      echo "WARN: Failed to rebuild initramfs after NVIDIA driver installation."
    }
  fi

  echo "INFO: Reboot after NVIDIA driver installation, then verify with nvidia-smi and vulkaninfo --summary."
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

install_base_packages() { # {{{
  echo ""
  echo "INFO: Installing Arch Linux packages..."

  local failed=false
  install_required_packages() {
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

      # Desktop requirements stay explicit even when another package pulled
      # them in first. This protects the Sway baseline during orphan cleanup.
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
  }

  install_required_package_groups() {
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
  }

  # Maintained interactive shell and general command-line baseline.
  install_required_packages \
    bash bash-completion tmux starship neovim \
    git ripgrep fd jq git-delta curl wget ca-certificates \
    openssl openssh \
    zlib bzip2 readline sqlite libffi xz \
    zip unzip 7zip \
    tree mat2 fontconfig \
    wl-clipboard \
    util-linux pacman-contrib

  # Keep FUSE 2 compatibility, exFAT utilities, and VeraCrypt together for
  # occasional encrypted removable-media workflows.
  install_required_packages fuse2 exfatprogs veracrypt

  # User development environment and repository validation baseline. Pacman
  # owns these workstation-wide binaries; project dependencies remain local.
  install_required_packages \
    mise \
    clang lldb \
    shellcheck shfmt stylua taplo-cli lua-language-server \
    pre-commit

  # Local application dependencies stay project-owned, while Docker and Compose
  # provide the shared runtime used by Spring Boot and other development stacks.
  install_required_packages \
    docker docker-compose

  # Arch system, package-build, hardware, storage, firmware, and network foundations.
  install_required_packages \
    glibc util-linux base-devel \
    pciutils mesa vulkan-icd-loader \
    cryptsetup gptfdisk hdparm nvme-cli \
    fwupd \
    xkeyboard-config \
    networkmanager firewalld

  # Wayland compositor, login, portal, and compatibility boundary.
  install_required_packages \
    sway swaybg swayidle swaylock \
    greetd greetd-regreet cage \
    xorg-xwayland \
    xdg-desktop-portal xdg-desktop-portal-wlr xdg-desktop-portal-gtk \
    xdg-utils xdg-user-dirs \
    qt5-wayland qt6-wayland

  # Desktop shell and hardware-adaptive conveniences. Battery and backlight
  # clients remain inert when their matching laptop hardware does not exist.
  install_required_packages \
    waybar swaync fuzzel swayosd \
    kanshi wdisplays \
    grim slurp swappy cliphist wf-recorder \
    batsignal wlsunset \
    brightnessctl playerctl \
    network-manager-applet \
    bluez bluez-utils blueman \
    polkit lxqt-policykit \
    gnome-keyring libsecret \
    upower power-profiles-daemon switcheroo-control \
    udisks2 udiskie gnome-disk-utility \
    cups system-config-printer bluez-cups \
    libnotify papirus-icon-theme

  # Fcitx modules cover native GTK/Qt Wayland clients and XWayland fallbacks.
  install_required_package_groups fcitx5-im
  install_required_packages fcitx5-hangul

  # Audio, media, and user-facing applications selected for this workstation.
  replace_package_before_install pipewire-jack jack2 || failed=true
  install_required_packages \
    noto-fonts-cjk noto-fonts-emoji glib2 dbus \
    pipewire pipewire-pulse pipewire-alsa pipewire-jack wireplumber gst-plugin-pipewire \
    alsa-utils pavucontrol \
    ffmpeg libheif poppler-data \
    gst-libav gst-plugin-va gst-plugins-base gst-plugins-good gst-plugins-bad gst-plugins-ugly \
    firefox mpv foot btop thunar tumbler thunar-volman thunar-archive-plugin xarchiver gvfs gvfs-mtp \
    imv \
    flatpak

  if command -v flatpak &>/dev/null; then
    run_as_root flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo || {
      echo "WARN: Failed to add Flathub remote."
    }
  fi

  [[ "${failed}" == "false" ]]
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
  local -r setup_script="${dotfiles_root}/scripts/setup_dotfiles.sh"

  if [[ ! -x "${setup_script}" ]]; then
    echo "ERROR: Dotfile deployment script is missing or not executable: ${setup_script}"
    return 1
  fi

  echo ""
  echo "INFO: Deploying user configuration..."
  run_as_target_user "${setup_script}"
} # }}}

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

setup_sway_user_preferences() { # {{{
  local target_user_home=""
  target_user_home="$(target_home)" || {
    echo "ERROR: Could not identify the target home for Sway preferences."
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

  setup_thunar_bookmarks() {
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
      failed=true
      return
    }
    if ! printf '%s' "${bookmark_content}" | run_as_target_user tee "${gtk_bookmarks}" >/dev/null; then
      echo "ERROR: Could not write Thunar bookmarks: ${gtk_bookmarks}"
      failed=true
      return
    fi
    echo "INFO: Applied Thunar Places shortcuts: ${gtk_bookmarks}"
  }
  setup_thunar_bookmarks

  [[ "${failed}" == "false" ]]
} # }}}

setup_sway_desktop() { # {{{
  echo ""
  echo "INFO: Configuring the Sway desktop session..."

  local -r greetd_config="${dotfiles_root}/config/system/greetd/config.toml"
  local -r regreet_config="${dotfiles_root}/config/system/greetd/regreet.toml"
  local -r regreet_style="${dotfiles_root}/config/system/greetd/regreet.css"
  local -r greetd_pam_config="${dotfiles_root}/config/system/pam.d/greetd"
  local -r sway_session_file="${dotfiles_root}/config/system/wayland-sessions/sway.desktop"
  local -r sway_launcher="${dotfiles_root}/config/system/sway/start-sway"
  local -r logind_config="${dotfiles_root}/config/system/systemd/logind.conf.d/60-sway-desktop.conf"
  local -r system_sound_config="${dotfiles_root}/config/system/modprobe.d/60-silent-system-sounds.conf"
  local -r faillock_config="${dotfiles_root}/config/system/security/faillock.conf"
  local -r firefox_policy="${dotfiles_root}/config/system/firefox/policies/policies.json"

  local target_user_name=""
  target_user_name="$(target_user)" || {
    echo "ERROR: Could not determine the target desktop user."
    return 1
  }

  local target_user_home=""
  target_user_home="$(target_home "${target_user_name}")" || {
    echo "ERROR: Could not determine the home directory for ${target_user_name}."
    return 1
  }

  local -r sway_config="${target_user_home}/.config/sway/config"
  local -r sway_user_unit_dir="${target_user_home}/.config/systemd/user"

  local source_file
  for source_file in "${greetd_config}" "${regreet_config}" "${regreet_style}" "${greetd_pam_config}" "${sway_session_file}" "${sway_launcher}" "${logind_config}" "${system_sound_config}" "${faillock_config}" "${firefox_policy}"; do
    if [[ ! -f "${source_file}" ]]; then
      echo "ERROR: Required Sway system configuration is missing: ${source_file}"
      return 1
    fi
  done

  if ! command -v systemctl &>/dev/null; then
    echo "ERROR: systemctl is required for the maintained Sway desktop."
    return 1
  fi
  if ! command -v systemd-analyze &>/dev/null; then
    echo "ERROR: systemd-analyze is required to validate the Sway user session."
    return 1
  fi
  if ! command -v sway &>/dev/null; then
    echo "ERROR: sway is required to validate the deployed desktop configuration."
    return 1
  fi
  if [[ ! -f "${sway_config}" ]]; then
    echo "ERROR: Deployed Sway configuration is missing: ${sway_config}"
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

  local -a sway_user_units=()
  local unit_file
  for unit_file in "${sway_user_unit_dir}"/*.service "${sway_user_unit_dir}"/*.target "${sway_user_unit_dir}"/*.path "${sway_user_unit_dir}"/*.timer; do
    if [[ -f "${unit_file}" ]]; then
      sway_user_units+=("${unit_file}")
    fi
  done
  if ((${#sway_user_units[@]} == 0)); then
    echo "ERROR: Deployed Sway user units are missing: ${sway_user_unit_dir}"
    return 1
  fi
  if ! run_as_target_user systemd-analyze --user --man=no --generators=no verify "${sway_user_units[@]}"; then
    echo "ERROR: Deployed Sway user units failed validation."
    return 1
  fi

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
  run_as_root install -Dm0644 "${logind_config}" /etc/systemd/logind.conf.d/60-sway-desktop.conf || {
    echo "ERROR: Failed to install the systemd-logind desktop policy."
    failed=true
  }
  run_as_root install -Dm0644 "${system_sound_config}" /etc/modprobe.d/60-silent-system-sounds.conf || {
    echo "ERROR: Failed to install the silent system sound policy."
    failed=true
  }
  run_as_root install -Dm0644 "${faillock_config}" /etc/security/faillock.conf || {
    echo "ERROR: Failed to install the failed authentication policy."
    failed=true
  }
  run_as_root install -Dm0644 "${firefox_policy}" /etc/firefox/policies/policies.json || {
    echo "ERROR: Failed to install the Firefox system policy."
    failed=true
  }

  if [[ "${failed}" == "true" ]]; then
    return 1
  fi

  # ReGreet now sends warning-level diagnostics to journald. Remove the legacy
  # standalone log only after the replacement configuration is installed.
  run_as_root rm -f -- /var/log/regreet/log || {
    echo "ERROR: Failed to remove the legacy ReGreet log."
    return 1
  }

  run_as_root systemctl set-default graphical.target || {
    echo "ERROR: Failed to set graphical.target as the default boot target."
    return 1
  }

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
  # path units, so restore only socket activation after that migration.
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

  # Display managers own the same display-manager.service alias. Switch it only
  # after required validation and installation have completed, and do not start
  # greetd inside the current graphical session.
  run_as_root systemctl enable --force greetd.service || {
    echo "ERROR: Failed to enable greetd.service."
    return 1
  }

  echo "DONE: Sway, greetd, and adaptive desktop services are configured."
} # }}}

setup_locale() { # {{{
  if locale -a 2>/dev/null | grep -Fxq "en_US.utf8" && localectl status 2>/dev/null | grep -Eq '^System Locale: LANG=en_US\.UTF-8$'; then
    echo "DONE: System locale is already UTF-8."
    return 0
  fi

  echo ""
  echo "INFO: Configuring system locale to en_US.UTF-8..."

  if [[ -f /etc/locale.gen ]]; then
    if grep -Eq '^#?en_US\.UTF-8 UTF-8$' /etc/locale.gen; then
      run_as_root sed -i 's/^#\(en_US\.UTF-8 UTF-8\)$/\1/' /etc/locale.gen
    else
      echo "en_US.UTF-8 UTF-8" | run_as_root tee -a /etc/locale.gen >/dev/null
    fi
  else
    echo "WARN: /etc/locale.gen not found. locale-gen may not generate en_US.UTF-8."
  fi

  if command -v locale-gen &>/dev/null; then
    run_as_root locale-gen || {
      echo "WARN: Failed to generate locales."
    }
  else
    echo "WARN: locale-gen is not available. Skipping locale generation."
  fi

  run_as_root localectl set-locale LANG=en_US.UTF-8 || {
    echo "WARN: Failed to configure system locale."
  }
} # }}}

setup_date_and_time() { # {{{
  if ! command -v timedatectl &>/dev/null; then
    echo "WARN: timedatectl is not available. Skipping date and time setup."
    return 0
  fi

  echo ""
  echo "INFO: Configuring automatic time and the Asia/Seoul time zone..."

  run_as_root timedatectl set-ntp true || {
    echo "WARN: Failed to enable automatic time synchronization."
  }

  run_as_root timedatectl set-timezone Asia/Seoul || {
    echo "WARN: Failed to set the system time zone to Asia/Seoul."
  }
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
    echo "WARN: Could not identify a non-root target user. Skipping default directory setup."
    return 0
  }

  local target_group=""
  target_group="$(id -gn "${target_user_name}" 2>/dev/null)" || {
    echo "WARN: Could not identify primary group for ${target_user_name}. Skipping default directory setup."
    return 0
  }

  local home_dir=""
  home_dir="$(target_home "${target_user_name}")" || {
    echo "WARN: Could not identify a non-root target home. Skipping default directory setup."
    return 0
  }

  create_user_dir() {
    local dir_path="${1}"
    run_as_root install -d -m 0755 -o "${target_user_name}" -g "${target_group}" "${dir_path}"
  }

  create_user_dir "${home_dir}/Downloads"
  create_user_dir "${home_dir}/Documents"
  create_user_dir "${home_dir}/Music"
  create_user_dir "${home_dir}/Pictures"
  create_user_dir "${home_dir}/Videos"
  create_user_dir "${home_dir}/tmp"

  _PROJECTS_HOME="${home_dir}/Projects"
  create_user_dir "${_PROJECTS_HOME}"
  create_user_dir "${_PROJECTS_HOME}/work"
  create_user_dir "${_PROJECTS_HOME}/personal"
  create_user_dir "${_PROJECTS_HOME}/opensource"
  create_user_dir "${_PROJECTS_HOME}/playground"
  create_user_dir "${_PROJECTS_HOME}/experiments"

  if command -v xdg-user-dirs-update &>/dev/null; then
    run_as_target_user xdg-user-dirs-update || {
      echo "WARN: Failed to register standard XDG user directories."
    }
  fi
} # }}}

install_yay() { # {{{
  # yay is convenient for a personal Arch workstation, but AUR availability is
  # outside this repo's control. Failure here should not block the rest of setup.
  if run_as_target_user bash -lc "command -v yay >/dev/null 2>&1"; then
    echo "DONE: yay is already installed."
    return 0
  fi

  local home_dir=""
  home_dir="$(target_home)" || {
    echo "WARN: Could not identify a non-root target home. Skipping yay setup."
    return 0
  }

  local -r yay_dir="${home_dir}/tmp/packages/yay"
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

set_default_browser_to_firefox() { # {{{
  local -r desktop_file="firefox.desktop"

  if ! run_as_target_user bash -lc "command -v firefox >/dev/null 2>&1"; then
    echo "WARN: Firefox is not installed. Skipping default browser setup."
    return 0
  fi

  if ! command -v xdg-settings &>/dev/null; then
    echo "WARN: xdg-settings is not installed. Skipping default browser setup."
    return 0
  fi

  if [[ ! -f "/usr/share/applications/${desktop_file}" ]]; then
    echo "WARN: Firefox desktop file not found. Skipping default browser setup."
    return 0
  fi

  echo ""
  echo "INFO: Setting Firefox as the default browser..."
  run_as_target_user xdg-settings set default-web-browser "${desktop_file}" || {
    echo "WARN: Failed to set Firefox as the default browser."
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
  # Nerd Fonts or when the CommitMono asset layout changes.
  local -r version="v3.4.0"
  local -r download_url="https://github.com/ryanoasis/nerd-fonts/releases/download/${version}/CommitMono.zip"
  local home_dir=""
  home_dir="$(target_home)" || {
    echo "WARN: Could not identify a non-root target home. Skipping font setup."
    return 0
  }

  local -r font_dir="${home_dir}/.local/share/fonts"

  install_commit_mono_nerd_font() {
    if find "${font_dir}" -name "*${font_name}*" | grep -q "."; then
      echo "DONE: ${font_name} is already installed. Skipping..."
      return 0
    fi

    echo ""
    echo "INFO: Installing ${font_name} ${version}..."

    local -r temp_dir="${home_dir}/tmp/packages/nerd_fonts_setup"
    run_as_target_user mkdir -pv "${temp_dir}"

    echo ""
    echo "INFO: Downloading font archive..."
    run_as_target_user curl -fLo "${temp_dir}/CommitMono.zip" "${download_url}" --retry 3 || {
      echo "WARN: Failed to download ${font_name}."
      return 0
    }

    echo ""
    echo "INFO: Extracting files..."
    run_as_target_user unzip -o "${temp_dir}/CommitMono.zip" -d "${temp_dir}" || {
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

# Arch Linux network privacy {{{

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
        firewall-cmd --permanent --zone=public --query-service=ssh >/dev/null
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

# Arch Linux network privacy }}}

# Completion notice {{{

show_reboot_notice() { # {{{
  echo ""
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
    echo "ERROR: setup_arch_bootstrap.sh does not accept options."
    echo "   Run without arguments."
    exit 1
  fi

  if ! is_arch; then
    echo "ERROR: Distro mismatch. Arch Linux only."
    exit 1
  fi

  refuse_root_execution
  find_and_move_to_dotfiles_root

  local -a tasks=(
    show_script_info
    upgrade_packages
    install_base_packages
    setup_local_container_runtime
    handle_hardware_drivers
    setup_alsa_auto_mute
    setup_locale
    setup_date_and_time
    setup_system_data_retention
    set_default_shell_to_bash
    create_default_directories
    deploy_dotfiles
    setup_sway_user_preferences
    setup_sway_desktop
    install_yay
    set_default_browser_to_firefox
    install_mise_managed_tools
    retry_mise_cli_installs
    install_nerd_font
    setup_basic_network_privacy
  )

  local task
  for task in "${tasks[@]}"; do
    if declare -f "${task}" >/dev/null; then
      echo "============================================================"
      echo "${task}"
      echo "============================================================"
      if ! "${task}"; then
        if [[ "${task}" == "upgrade_packages" ]]; then
          echo "ERROR: System upgrade failed. Stop before installing additional packages."
          exit 1
        fi
        if [[ "${task}" == "install_base_packages" ]]; then
          echo "ERROR: Required package installation failed. Stop before applying dependent configuration."
          exit 1
        fi
        if [[ "${task}" == "setup_system_data_retention" ]]; then
          echo "ERROR: Required system data retention policy failed."
          exit 1
        fi
        if [[ "${task}" == "set_default_shell_to_bash" ]]; then
          echo "ERROR: Required Bash login shell setup failed."
          exit 1
        fi
        if [[ "${task}" == "setup_basic_network_privacy" ]]; then
          echo "ERROR: Required firewall or network privacy policy failed."
          exit 1
        fi
        if [[ "${task}" == "deploy_dotfiles" || "${task}" == "setup_sway_user_preferences" || "${task}" == "setup_sway_desktop" ]]; then
          echo "ERROR: Required Sway preferences or deployment failed. Stop before reporting a bootable desktop."
          exit 1
        fi
        echo "ERROR: Task failed, continuing: ${task}"
      fi
      echo ""
      echo ""
      echo ""
    else
      echo "WARN: Function '${task}' not found."
    fi
  done

  show_reboot_notice
} # }}}

# Main }}}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "${@}"
fi
