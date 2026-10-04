return {
  cmd = { 'clangd', '--clang-tidy' },
  filetypes = { 'c' },
  root_markers = { '.clangd', 'compile_commands.json', 'compile_flags.txt', '.git' },
}
