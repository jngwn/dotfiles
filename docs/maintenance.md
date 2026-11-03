# Maintenance

## Deploy user configuration

Edit the intended checkout and run from it as the normal user, without `sudo`:

```sh
./scripts/deploy_dotfiles.sh
```

Start a new Bash login shell to use deployed shell changes:

```sh
exec bash -l
```

Apply running application changes using the
[Sway](sway-workflow.md#설정-적용-시점) or
[tmux](tmux-workflow.md#설정-적용과-복구) workflow. The Sway table also covers system
configuration changes that require bootstrap installation and a later login or
reboot.

## Logs and backup recovery

- Logs: `${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles/logs/`
- Backups: `${XDG_DATA_HOME:-$HOME/.local/share}/dotfiles/backups/`

Choose the backup directory for the deployment to recover and inspect the
matching entry and its original destination. Remove an unwanted deployed symlink
without following it; move a directory or other replacement aside before
restoring the backup entry to that path. If the backup entry is a symlink, inspect
its target before restoring it.

If deployment stopped after moving the previous `~/.dotfiles`, restore
`dotfiles_old` from that run's backup to `~/.dotfiles`, or rerun deployment from the
intended checkout. Preserve any replacement `~/.dotfiles` before restoring the old
copy.

## macOS Ghostty configuration

If deployment warns about a configuration under
`~/Library/Application Support/com.mitchellh.ghostty/`, inspect that file. Ghostty
reads it after the deployed XDG configuration; merge or remove it if it
unintentionally overrides the deployed settings.
