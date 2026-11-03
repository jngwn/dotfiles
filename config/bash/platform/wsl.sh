_reset_shell_names sunset firmware_update fwup

_platform_keep_awake() {
  echo "ERROR: keep_awake cannot inhibit sleep on the Windows host." >&2
  return 1
}

_platform_copy_to_clipboard() {
  _copy_to_terminal_clipboard
}
