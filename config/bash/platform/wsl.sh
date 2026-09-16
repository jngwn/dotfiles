_reset_shell_names sunset firmware_update fwup

_platform_keep_awake() {
  echo "ERROR: keep_awake cannot inhibit sleep on the Windows host." >&2
  return 1
}
