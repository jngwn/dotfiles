Personal installation, bootstrap, deployment, and recovery notes for Native Arch
Linux and Arch Linux on WSL. Limited dotfile deployment also supports macOS and
other Linux distributions, whether native or running on WSL.

## Arch Linux Install Notes

Initial live ISO commands:

Replace `<WIFI_DEVICE>` with the device name from `device list`, and replace
`<WIFI_NAME>` with the target Wi-Fi network name.

```sh
ping -c 3 archlinux.org

iwctl
device list
station <WIFI_DEVICE> scan
station <WIFI_DEVICE> get-networks
station <WIFI_DEVICE> connect <WIFI_NAME>
exit

ping -c 3 archlinux.org
archinstall
```

Install a clean terminal/base Arch system and reboot. The repository bootstrap
then owns Sway, greetd, Fcitx5 Hangul input, user tools, and network policy. Menu
names change across archinstall releases; run `archinstall --dry-run` on the live
ISO when the exact current menu or config keys are needed.

Use these `archinstall` choices:

- Archinstall language: English.
- Mirrors: choose nearby country mirrors.
- Locales:
  - Keyboard layout: us.
  - Locale language: en_US.UTF-8.
  - Locale encoding: UTF-8.
- Disk configuration:
  - Partition table: GPT on UEFI systems.
  - Use Best Effort default partitioning on the whole target disk for a fresh
    single-boot machine.
  - Use manual partitioning for dual-boot, preserving existing partitions, or
    non-default boot layouts.
  - Filesystem: ext4.
  - Mountpoints: let archinstall create the default EFI/root layout unless
    manual partitioning is required.
  - Separate `/home`: disabled. Keep home data in the single root filesystem.
  - LVM: disabled. This single-disk layout does not need independently resized
    logical volumes or pooled storage.
- Disk encryption: enable LUKS by default for the system and user-data
  partitions. Leave only the boot components required by the selected bootloader
  unencrypted.
  - Encryption password: use a strong passphrase that can be typed reliably on
    the selected keyboard layout.
  - Leave dm-crypt discard/TRIM pass-through disabled for encrypted system
    volumes. See [`POWER-001`](docs/contracts.md#power-001) before changing it.
- Bootloader: systemd-boot on UEFI. On BIOS systems, use GRUB or Limine.
- Unified kernel images: leave disabled unless UKI and Secure Boot are part of
  the explicit boot plan.
- Removable boot: disabled by default. Enable only for removable media or
  machines where NVRAM boot entries are unreliable.
- Swap: zram.
  - Compression algorithm: zstd if archinstall asks. It is a practical default
    for desktop use because it balances compression ratio and speed well.
- Hostname: pick a short lowercase machine name.
- Root password: leave unset. Use the normal user's password with sudo; the LUKS
  passphrase separately protects data at rest.
- User account: create a normal user and allow sudo/admin privileges.
- Profile: do not select a profile. This script owns desktop/bootstrap setup.
- Graphics/GPU driver: skip if no menu appears. This script installs Mesa for
  all desktops and the current Arch NVIDIA open-driver path when NVIDIA hardware
  is detected.
- Audio: none. This script installs PipeWire explicitly.
- Kernels: linux.
- Network configuration: NetworkManager.
- Timezone: Asia/Seoul.
- NTP: enabled.
- Optional repositories: none by default. Enable multilib when Steam, Wine,
  Proton, or other 32-bit runtime support is needed. NVIDIA gaming setups also
  need multilib for lib32-nvidia-utils/lib32-vulkan-icd-loader.
- Additional packages: git.
- Additional services: none. This script enables desktop and network services
  after the base system is installed.
- Other installer options: keep the defaults, with accessibility tools disabled
  and no custom commands.
- Save configuration: do not save by default. If reuse is intentional, encrypt
  the credentials file because it can contain the LUKS passphrase, and remove
  saved credentials after use.
- Install: review the summary carefully before confirming destructive disk
  operations.

## First Boot Wi-Fi

After rebooting into the installed system, make Wi-Fi work before running the
bootstrap script.

Do not rely on `which`; it may not be installed. Use `command -v` instead.

```sh
command -v nmcli
command -v iwctl
```

If `nmcli` exists, use NetworkManager:

```sh
sudo systemctl enable --now NetworkManager.service
nmcli radio wifi on
nmcli device status
nmcli device wifi rescan
nmcli device wifi list
nmcli device wifi connect <WIFI_NAME> --ask
ping -c 3 archlinux.org
```

If the Wi-Fi device is unavailable or blocked:

```sh
rfkill list
sudo rfkill unblock wifi
nmcli device status
```

If `nmcli` is missing but `iwctl` exists, use iwd for a temporary connection.
This is only a fallback; NetworkManager with its default backend does not need
iwd on the installed system.

```sh
sudo systemctl enable --now iwd.service
iwctl
device list
station <WIFI_DEVICE> scan
station <WIFI_DEVICE> get-networks
station <WIFI_DEVICE> connect <WIFI_NAME>
exit
ping -c 3 archlinux.org
```

After a temporary iwd connection, install and enable NetworkManager:

```sh
sudo pacman -Syu networkmanager
sudo systemctl disable --now iwd.service
sudo systemctl enable --now NetworkManager.service
```

If both `nmcli` and `iwctl` are missing, boot the Arch ISO again, connect from
the live environment, chroot into the installed system, and install the missing
network tools:

```sh
iwctl
device list
station <WIFI_DEVICE> scan
station <WIFI_DEVICE> get-networks
station <WIFI_DEVICE> connect <WIFI_NAME>
exit
ping -c 3 archlinux.org

mount <ROOT_PARTITION> /mnt
arch-chroot /mnt
pacman -Syu networkmanager
systemctl enable NetworkManager.service
exit
umount -R /mnt
reboot
```

## Bootstrap, Dotfile Deployment, and Recovery

Run repository workflows from an existing checkout as the normal user. Both
scripts accept no arguments and refuse root execution; do not prefix them with
`sudo`. The bootstrap requests sudo only for the tasks that need system access.
It supports Native Arch Linux and Arch Linux on WSL only.

The bootstrap performs a full Arch package upgrade before installing and
configuring the environment, so establish network access first. Run:

```sh
./scripts/bootstrap.sh
```

After setup begins, the bootstrap attempts every declared task even if an earlier
one fails. At the end it lists all failed tasks and exits nonzero; review the
earlier error output, correct the causes, and rerun the same command. Warnings do
not by themselves define success: use the final failed-task summary and exit
status, and review warnings before using the result. Successful native setup
requires a reboot to enter the configured Sway session. Successful WSL setup
requires starting a new shell.

Bootstrap creates missing standard user directories with mode `0755` but preserves
the owner and mode of directories that already exist. It refreshes the standard GTK
Places shortcuts while retaining custom bookmarks with other labels.

If networking fails after native bootstrap, inspect the connection and resolver
state before changing settings:

```sh
nmcli device status
readlink -f /etc/resolv.conf
resolvectl status
resolvectl query example.com
```

In Firefox, open `about:policies` to inspect the applied browser policy. These
checks help distinguish connection, resolver, and browser problems; the intended
network behavior and change boundary are in
[`NETWORK-001`](docs/contracts.md#network-001).

To deploy only the dotfiles without package installation or system setup, run:

```sh
./scripts/deploy_dotfiles.sh
```

To use deployed Bash changes in an existing shell, replace it with a new login
shell:

```sh
exec bash -l
```

The deployment script detects the environment automatically; it has no platform
option.

| Environment | Deployment scope |
| --- | --- |
| Native Arch Linux | Full user configuration |
| Linux distributions on WSL | Common limited configuration |
| Other Linux systems outside WSL | Common limited configuration, Ghostty, and mpv |
| macOS | Common limited configuration and Ghostty |

Platforms outside Linux and macOS are rejected. The exact inventories and support
boundary are maintained in
[`DEPLOY-001`](docs/contracts.md#deploy-001) and
[`PLATFORM-001`](docs/contracts.md#platform-001).

On platforms without bootstrap support—other WSL distributions, other Linux
systems outside WSL, and macOS—install Bash and the applications whose configuration
you intend to use independently. The deployment script does not invoke a package
manager, change the login shell, or configure the operating system. The Git
configuration expects `delta`; where Ghostty configuration is deployed, its
appearance expects `CommitMono Nerd Font Mono`. A missing application does not
prevent deployment, but its configuration remains unused until it is installed.

On WSL, the deployed `open-path` command, Bash `f` command, and Yazi opener forward
only paths or URLs selected in that invocation to the Windows host. Trash operations
remain inside the WSL guest through GIO; no opener or cleanup is invoked
automatically.

Deployment links managed entries through `~/.dotfiles`. When invoked from another
checkout, it replaces that derived copy and preserves the previous copy as
`dotfiles_old` in the run-specific backup directory. Conflicting destination
entries are moved into the same backup before links are created. Native Arch Linux
manages all entries under `home/` and `config/` except `config/system/`, which
remains bootstrap-owned source material.

Each successful deployment records its managed symlinks in
`${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles/deployment-manifest`. On a later
deployment, a previously managed symlink that is no longer in the selected profile
is moved into that run's backup only when it still points to the recorded source.
At destinations removed from the profile, regular files and symlinks retargeted by
the user are preserved.

- Backups: `${XDG_DATA_HOME:-$HOME/.local/share}/dotfiles/backups/`
- Logs: `${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles/logs/`

Recovery is manual: remove an unwanted deployed link and move the corresponding
entry back from the latest backup directory. If deployment stopped after moving
the previous `~/.dotfiles`, either restore `dotfiles_old` or rerun deployment from
the intended checkout.

System files installed by bootstrap are copied rather than linked. Removing or
renaming their repository sources does not remove an existing `/etc` or
`/usr/local` destination; the authorized source change must include explicit cleanup
and recovery for the former destination.

On macOS, Ghostty also reads configuration from
`~/Library/Application Support/com.mitchellh.ghostty/` after the deployed XDG
configuration. Deployment warns when a configuration exists there but does not
change it. Merge or remove that file if it unintentionally overrides the deployed
settings.

## Arch Linux on WSL

Arch Linux on WSL is a command-line bootstrap and restricted deployment target.
Its exact support boundary is [`PLATFORM-001`](docs/contracts.md#platform-001).

Create a normal user with Bash as the login shell and grant sudo access from the
initial root shell:

```sh
pacman -Syu sudo vim
useradd -m -G wheel -s /usr/bin/bash <USER_NAME>
passwd <USER_NAME>
EDITOR=vim visudo
```

In `visudo`, enable the wheel group:

```conf
%wheel ALL=(ALL:ALL) ALL
```

Enable systemd user services and make the account the default WSL user in
`/etc/wsl.conf`:

```conf
[boot]
systemd=true

[user]
default=<USER_NAME>
```

This configuration works for distributions installed through a launcher as well as
imported distributions. Restart the distribution from Windows PowerShell so WSL
applies both settings:

```powershell
wsl --terminate <DISTRO_NAME>
```

Start the distribution as the normal user and run the common bootstrap workflow
above. In that environment, the bootstrap installs the maintained command-line and
development tools, configures the UTF-8 locale and user directories, deploys the
restricted dotfile set, and installs the tools managed by mise. It leaves host-owned
and native-only tasks inert.
