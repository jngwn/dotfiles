# Initial Setup

## Native Arch Linux

### Live ISO

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

### Installer choices

Install a terminal/base system without a desktop profile. If menu names have
changed, use `archinstall --dry-run` on the live ISO to inspect the current options.

- Archinstall language: English.
- Mirrors: choose nearby country mirrors.
- Locales: keyboard us, language en_US.UTF-8, encoding UTF-8.
- Disk configuration:
  - Partition table: GPT on UEFI systems.
  - Use Best Effort default partitioning on the whole target disk for a fresh
    single-boot machine.
  - Use manual partitioning for dual-boot, preserving existing partitions, or
    non-default boot layouts.
  - Filesystem: ext4.
  - Mountpoints: let archinstall create the default EFI/root layout unless
    manual partitioning is required.
  - Separate `/home`: disabled.
  - LVM: disabled.
- Disk encryption: enable LUKS by default for the system and user-data
  partitions. Leave only the boot components required by the selected bootloader
  unencrypted.
  - Leave dm-crypt discard/TRIM pass-through disabled for encrypted system
    volumes. See [`POWER-001`](docs/contracts.md#power-001) before changing it.
- Bootloader: systemd-boot on UEFI. On BIOS systems, use GRUB or Limine.
- Unified kernel images: leave disabled unless UKI and Secure Boot are part of
  the explicit boot plan.
- Removable boot: disabled by default. Enable only for removable media or
  machines where NVRAM boot entries are unreliable.
- Swap: zram, with zstd compression if asked.
- Hostname: pick a short lowercase machine name.
- Root password: leave unset.
- User account: create a normal user and allow sudo/admin privileges.
- Profile: none.
- Graphics/GPU driver: leave configuration to bootstrap.
- Audio: none.
- Kernels: linux.
- Network configuration: NetworkManager.
- Timezone: Asia/Seoul.
- NTP: enabled.
- Optional repositories: none.
- Additional packages: git.
- Additional services: none.
- Other installer options: keep the defaults, with accessibility tools disabled
  and no custom commands.
- Save configuration: do not save by default. If reuse is intentional, encrypt
  the credentials file because it can contain the LUKS passphrase, and remove
  saved credentials after use.

Review the disk operations in the summary, install, and reboot into the installed
system.

### First boot Wi-Fi

After rebooting into the installed system, make Wi-Fi work before running the
bootstrap script.

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

If `nmcli` is missing but `iwctl` exists, use iwd for a temporary connection:

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
network tools. The commands below use the ext4-on-LUKS layout described above.
Identify `<ROOT_PARTITION>` with `lsblk -f`; it should have type `crypto_LUKS`.
For an unencrypted root, mount `<ROOT_PARTITION>` directly at `/mnt` instead
and omit both `cryptsetup` commands.

```sh
iwctl
device list
station <WIFI_DEVICE> scan
station <WIFI_DEVICE> get-networks
station <WIFI_DEVICE> connect <WIFI_NAME>
exit
ping -c 3 archlinux.org

lsblk -f
cryptsetup open --type luks <ROOT_PARTITION> cryptroot
mount /dev/mapper/cryptroot /mnt
cat /mnt/etc/fstab
```

Match the boot/EFI partitions to `/mnt/etc/fstab` using the UUIDs from `lsblk -f`.
The example below assumes a separate boot partition mounted at `/boot`; adjust
the destination if fstab uses `/efi` or `/boot/efi`. Mount all separate boot/EFI
filesystems at their corresponding paths under `/mnt` before entering the chroot,
because the full package upgrade can update the kernel and initramfs.

```sh
mount --mkdir <BOOT_PARTITION> /mnt/boot
arch-chroot /mnt
pacman -Syu networkmanager
systemctl enable NetworkManager.service
exit
umount -R /mnt
cryptsetup close cryptroot
reboot
```

## Arch Linux on WSL

Create a normal user with Bash as the login shell and grant sudo access from the
initial root shell:

```sh
pacman -Syu sudo vim git
useradd -m -G wheel -s /usr/bin/bash <USER_NAME>
passwd <USER_NAME>
EDITOR=vim visudo
```

In `visudo`, enable the wheel group:

```conf
%wheel ALL=(ALL:ALL) ALL
```

Enable systemd and set the default WSL account in `/etc/wsl.conf`:

```conf
[boot]
systemd=true

[user]
default=<USER_NAME>
```

Terminate the distribution from Windows PowerShell, then reopen it so both
settings take effect:

```powershell
wsl.exe -t <DISTRO_NAME>
```

Continue with [Bootstrap](#bootstrap) as the normal user.

## Bootstrap

Run from the checkout as the normal user, without `sudo` or arguments. Native Arch
Linux and Arch WSL require network access and sudo privileges; bootstrap performs
a full Arch package upgrade.

Native Arch Linux receives the full system setup, Arch WSL receives CLI and
development setup, and other supported systems receive dotfiles only. For
dotfile-only setup, install Bash and the applications you use yourself. Git expects
`delta`; Ghostty expects `CommitMono Nerd Font Mono`.

```sh
./scripts/bootstrap.sh
```

If yay is unavailable on Arch, bootstrap builds and installs it automatically from
AUR. Authentication and package-manager prompts may still require input.

If a task fails, review the final failure list and logged errors, fix the cause,
and rerun the same command. Review warnings before using the result.

After successful Native Arch setup, reboot to enter Sway. On Arch WSL and
dotfile-only setups, start a new Bash login shell:

```sh
exec bash -l
```

For later deployment and backup recovery, see [Maintenance](docs/maintenance.md).
