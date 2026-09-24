return {
  cmd = { 'emmet-language-server', '--stdio' },
  filetypes = { 'html', 'css', 'scss', 'less', 'javascriptreact', 'typescriptreact' },
  root_markers = {
    { 'package-lock.json', 'pnpm-lock.yaml', 'yarn.lock', 'bun.lock', 'bun.lockb' },
    'package.json',
    '.git',
  },
  workspace_required = false,
  init_options = {
    showSuggestionsAsSnippets = true,
  },
}
