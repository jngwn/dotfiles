local config_files = { 'biome.json', 'biome.jsonc' }
local lockfiles = { 'package-lock.json', 'pnpm-lock.yaml', 'yarn.lock', 'bun.lock', 'bun.lockb' }

return {
  cmd = { 'biome', 'lsp-proxy' },
  filetypes = {
    'javascript',
    'javascriptreact',
    'typescript',
    'typescriptreact',
    'json',
    'jsonc',
    'css',
    'html',
  },
  root_markers = { config_files, lockfiles, 'package.json', '.git' },
  workspace_required = false,
}
