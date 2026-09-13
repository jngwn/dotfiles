#!/usr/bin/env bash

start_logging() {
  local -r xdg_state_home="${XDG_STATE_HOME:-${HOME}/.local/state}"
  local -r log_dir="${xdg_state_home}/dotfiles/logs"
  local -r log_file="${log_dir}/$(date +%Y%m%d-%H%M%S)-deploy-dotfiles.log"

  if ! command -v tee >/dev/null 2>&1; then
    echo "ERROR: tee is required for logging." >&2
    exit 1
  fi

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
}

show_script_info() {
  echo "INFO: basename: ${0##*/}"
  echo "INFO: dirname : $(dirname "${0}")"
  echo "INFO: pwd     : $(pwd)"
  echo ""
}

is_arch() {
  [[ -f /etc/os-release ]] || return 1
  (
    source /etc/os-release
    [[ "${ID}" == "arch" ]]
  )
}

is_wsl() {
  local os_release=""
  [[ -r /proc/sys/kernel/osrelease ]] || return 1
  IFS= read -r os_release </proc/sys/kernel/osrelease || return 1

  case "${os_release}" in
    *[Mm]icrosoft* | *[Ww][Ss][Ll]*) return 0 ;;
    *) return 1 ;;
  esac
}

is_linux() {
  [[ "$(uname -s)" == "Linux" ]]
}

is_macos() {
  [[ "$(uname -s)" == "Darwin" ]]
}

warn_macos_ghostty_override() {
  local -r native_config_dir="${HOME}/Library/Application Support/com.mitchellh.ghostty"
  local native_config

  for native_config in "${native_config_dir}/config.ghostty" "${native_config_dir}/config"; do
    if [[ -e "${native_config}" || -L "${native_config}" ]]; then
      echo "WARN: macOS Ghostty config takes precedence over the deployed XDG config:"
      echo "   ${native_config}"
    fi
  done
}

detect_deployment_profile() {
  if is_wsl; then
    printf '%s\n' 'wsl'
  elif is_arch; then
    printf '%s\n' 'native_arch'
  elif is_linux; then
    printf '%s\n' 'linux'
  elif is_macos; then
    printf '%s\n' 'macos'
  else
    return 1
  fi
}

validate_platform() {
  deployment_profile="$(detect_deployment_profile)" || {
    echo "ERROR: Unsupported platform."
    echo "   deploy_dotfiles.sh supports native Arch Linux, Linux distributions on WSL,"
    echo "   other Linux systems, and macOS."
    return 1
  }
}

refuse_root_execution() {
  if ((EUID == 0)); then
    echo "ERROR: Do not run deploy_dotfiles.sh as root."
    echo "   Run it as your normal user so HOME points to the account that owns these dotfiles."
    exit 1
  fi
}

initialize_variables() {
  dotfiles_base="${HOME}/.dotfiles"
  config_home="${XDG_CONFIG_HOME:-${HOME}/.config}"
  backup_dir="${XDG_DATA_HOME:-${HOME}/.local/share}/dotfiles/backups"
  backup_run_dir="${backup_dir}/dotfiles-$(date +"%Y%m%d_%H%M%S")-$$"
  backup_run_dir_created=false
  deployment_state_dir="${XDG_STATE_HOME:-${HOME}/.local/state}/dotfiles"
  deployment_manifest="${deployment_state_dir}/deployment-manifest"
  deployment_manifest_temp=""
}

cleanup_deployment_manifest_temp() {
  if [[ -n "${deployment_manifest_temp:-}" ]]; then
    rm -f -- "${deployment_manifest_temp}"
  fi
}

initialize_deployment_manifest() {
  if [[ -L "${deployment_manifest}" ]] ||
    [[ -e "${deployment_manifest}" &&
      (! -f "${deployment_manifest}" || ! -O "${deployment_manifest}" || ! -r "${deployment_manifest}") ]]; then
    echo "ERROR: Refusing an unsafe deployment manifest: ${deployment_manifest}"
    return 1
  fi

  mkdir -p "${deployment_state_dir}" || return
  chmod 0700 "${deployment_state_dir}" || return
  deployment_manifest_temp="$(mktemp "${deployment_state_dir}/deployment-manifest.XXXXXX")" || return
  chmod 0600 "${deployment_manifest_temp}" || return
}

record_managed_symlink() {
  local -r source_path="${1}"
  local -r target_path="${2}"

  if [[ "${source_path}" == *$'\n'* || "${source_path}" == *$'\t'* ||
    "${target_path}" == *$'\n'* || "${target_path}" == *$'\t'* ]]; then
    echo "ERROR: Deployment paths cannot contain tabs or newlines: ${target_path}"
    return 1
  fi

  printf '%s\t%s\n' "${source_path}" "${target_path}" >>"${deployment_manifest_temp}"
}

create_backup_run_dir() {
  if [[ "${backup_run_dir_created}" == "true" ]]; then
    return 0
  fi

  mkdir -p "${backup_run_dir}" || return
  # The private parents protect moved files without rewriting their original modes.
  chmod 0700 "${backup_dir}" "${backup_run_dir}" || return
  backup_run_dir_created=true
}

find_and_move_to_dotfiles_root() {
  dotfiles_root="$(cd "$(dirname "$0")/.." && pwd)" || {
    echo "ERROR: Unable to find dotfiles root from script location."
    return 1
  }

  echo "INFO: Dotfiles root: ${dotfiles_root}"
  cd "${dotfiles_root}" || {
    echo "ERROR: Unable to move to directory '${dotfiles_root}'."
    return 1
  }
}

create_dir() {
  mkdir -p "${1}"
}

backup_if_exists() {
  local target_path="${1}"
  if [ ! -e "${target_path}" ] && [ ! -L "${target_path}" ]; then
    return 0
  fi

  local relative_path="${target_path#"${HOME}/"}"
  local backup_path="${backup_run_dir}/${relative_path}"

  echo "INFO: Backing up existing file/directory: ${target_path}"
  create_backup_run_dir || return
  mkdir -p "$(dirname "${backup_path}")" || return
  mv -f "${target_path}" "${backup_path}"
}

create_symlink() {
  local source_path="${1}"
  local target_path="${2}"

  if [ ! -e "${source_path}" ]; then
    echo "ERROR: Source file/directory not found: ${source_path}"
    return 1
  fi

  if [ -L "${target_path}" ] && [ "$(readlink "${target_path}")" = "${source_path}" ]; then
    echo "DONE: Symlink already exists and is correct: ${target_path}"
    record_managed_symlink "${source_path}" "${target_path}"
    return
  fi

  backup_if_exists "${target_path}" || return

  ln -s "${source_path}" "${target_path}" || return
  echo "DONE: Created symlink: ${target_path} -> ${source_path}"
  record_managed_symlink "${source_path}" "${target_path}"
}

reconcile_removed_symlinks() {
  if [[ ! -f "${deployment_manifest}" ]]; then
    return 0
  fi

  local old_source_path
  local old_target_path
  local failed=false
  while IFS=$'\t' read -r old_source_path old_target_path; do
    if [[ -z "${old_source_path}" || -z "${old_target_path}" ]]; then
      echo "WARN: Ignoring an invalid entry in the previous deployment manifest."
      continue
    fi
    if grep -Fqx -- "${old_source_path}"$'\t'"${old_target_path}" "${deployment_manifest_temp}"; then
      continue
    fi

    if [[ -L "${old_target_path}" ]] &&
      [[ "$(readlink "${old_target_path}")" == "${old_source_path}" ]]; then
      echo "INFO: Backing up a symlink removed from the deployment scope: ${old_target_path}"
      backup_if_exists "${old_target_path}" || failed=true
    fi
  done <"${deployment_manifest}"

  [[ "${failed}" == "false" ]]
}

publish_deployment_manifest() {
  mv -f -- "${deployment_manifest_temp}" "${deployment_manifest}" || return
  deployment_manifest_temp=""
}

link_recursive() {
  local src_dir="${1}"
  local dest_dir="${2}"

  if [[ -L "${dest_dir}" ]] || [[ -e "${dest_dir}" && ! -d "${dest_dir}" ]]; then
    backup_if_exists "${dest_dir}" || return
  fi

  create_dir "${dest_dir}" || return

  shopt -s dotglob nullglob

  local failed=false

  for item_path in "${src_dir}"/*; do
    local item_name="${item_path##*/}"
    local src_item="${src_dir}/${item_name}"
    local dest_item="${dest_dir}/${item_name}"

    if [ -d "${src_item}" ]; then
      link_recursive "${src_item}" "${dest_item}" || failed=true
    else
      create_symlink "${src_item}" "${dest_item}" || failed=true
    fi
  done

  shopt -u dotglob nullglob
  [[ "${failed}" == "false" ]]
}

link_selected_entries() {
  local src_dir="${1}"
  local dest_dir="${2}"
  shift 2

  local failed=false
  local item_name
  for item_name in "${@}"; do
    local src_item="${src_dir}/${item_name}"
    local dest_item="${dest_dir}/${item_name}"

    if [[ ! -e "${src_item}" && ! -L "${src_item}" ]]; then
      echo "ERROR: Required deployment source is missing: ${src_item}"
      failed=true
      continue
    fi

    if [[ -d "${src_item}" ]]; then
      link_recursive "${src_item}" "${dest_item}" || failed=true
    else
      create_dir "$(dirname "${dest_item}")" || {
        failed=true
        continue
      }
      create_symlink "${src_item}" "${dest_item}" || failed=true
    fi
  done

  [[ "${failed}" == "false" ]]
}

backup_and_copy_dotfiles() {
  if [ "${dotfiles_root}" != "${dotfiles_base}" ]; then
    if [[ -e "${dotfiles_base}" || -L "${dotfiles_base}" ]]; then
      create_backup_run_dir || return
      mv -f "${dotfiles_base}" "${backup_run_dir}/dotfiles_old" || return
    fi

    if command -v rsync &>/dev/null; then
      rsync -av --exclude='.git' --exclude='.github' "${dotfiles_root}/" "${dotfiles_base}/" || return
    else
      create_dir "${dotfiles_base}" || return
      shopt -s dotglob
      local failed=false
      for item in "${dotfiles_root}"/*; do
        local item_name="${item##*/}"
        if [[ "${item_name}" == ".git" || "${item_name}" == ".github" ]]; then
          continue
        fi

        cp -RPp "${item}" "${dotfiles_base}" || failed=true
      done
      shopt -u dotglob
      if [[ "${failed}" == "true" ]]; then
        return 1
      fi
    fi

    cd "${dotfiles_base}" || return
  fi
}

symlink_limited_dotfiles() {
  local -a config_entries=(bash mise nvim tmux yazi "${@}")
  local failed=false

  link_selected_entries "${dotfiles_base}/home" "${HOME}" \
    .bash_profile .bashrc .codex .editorconfig .local/bin/open-path \
    .gitconfig .gitignore_global .ideavimrc || failed=true

  create_dir "${config_home}" || return
  link_selected_entries "${dotfiles_base}/config" "${config_home}" \
    "${config_entries[@]}" || failed=true

  [[ "${failed}" == "false" ]]
}

symlink_full_dotfiles() {
  local failed=false
  local repo_home_dir="${dotfiles_base}/home"
  if [ -d "${repo_home_dir}" ]; then
    link_recursive "${repo_home_dir}" "${HOME}" || failed=true
  fi

  local repo_config_dir="${dotfiles_base}/config"
  if [ -d "${repo_config_dir}" ]; then
    create_dir "${config_home}" || return

    shopt -s dotglob nullglob
    for item_path in "${repo_config_dir}"/*; do
      local item_name="${item_path##*/}"
      if [[ "${item_name}" == "system" ]]; then
        # Bootstrap installs this subtree into system paths; never link it as user config.
        echo "INFO: Skipping system config symlinks: ${item_path}"
        continue
      fi

      if [ -d "${item_path}" ]; then
        link_recursive "${item_path}" "${config_home}/${item_name}" || failed=true
      else
        create_symlink "${item_path}" "${config_home}/${item_name}" || failed=true
      fi
    done
    shopt -u dotglob nullglob
  fi

  [[ "${failed}" == "false" ]]
}

symlink_dotfiles() {
  case "${deployment_profile}" in
    native_arch)
      symlink_full_dotfiles
      ;;
    wsl)
      symlink_limited_dotfiles
      ;;
    linux)
      symlink_limited_dotfiles ghostty mpv
      ;;
    macos)
      warn_macos_ghostty_override
      symlink_limited_dotfiles ghostty
      ;;
    *)
      echo "ERROR: Unknown deployment profile: ${deployment_profile}" >&2
      return 1
      ;;
  esac
}

main() {
  start_logging
  trap cleanup_deployment_manifest_temp EXIT

  if (($# > 0)); then
    echo "ERROR: deploy_dotfiles.sh does not accept options."
    echo "   Run without arguments."
    exit 1
  fi

  refuse_root_execution
  validate_platform || exit 1
  echo "INFO: Deployment profile: ${deployment_profile}"
  echo ""
  show_script_info
  initialize_variables || {
    echo "ERROR: Could not initialize dotfile deployment paths."
    exit 1
  }
  initialize_deployment_manifest || {
    echo "ERROR: Could not initialize the deployment manifest."
    exit 1
  }
  find_and_move_to_dotfiles_root || exit 1

  echo ""
  echo "INFO: Setup dotfiles start"
  printf "%0.s-" {1..60}
  echo ""

  backup_and_copy_dotfiles || {
    echo "ERROR: Could not prepare the ~/.dotfiles deployment copy."
    exit 1
  }
  symlink_dotfiles || {
    echo "ERROR: One or more dotfile symlinks could not be deployed."
    exit 1
  }
  reconcile_removed_symlinks || {
    echo "ERROR: One or more removed dotfile symlinks could not be backed up."
    exit 1
  }
  publish_deployment_manifest || {
    echo "ERROR: Could not publish the deployment manifest."
    exit 1
  }

  echo ""
  printf "%0.s-" {1..60}
  printf "\nDONE: Setup dotfiles done!\n"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "${@}"
fi
