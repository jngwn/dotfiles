return {
  cmd = { 'clangd', '--clang-tidy', '--header-insertion=never' },
  filetypes = { 'c', 'cpp' },
  root_markers = { '.clangd', 'compile_commands.json', 'compile_flags.txt', '.git' },
}
