return {
  cmd = { 'tsc', '--lsp', '--stdio' },
  filetypes = { 'javascript', 'javascriptreact', 'typescript', 'typescriptreact' },
  root_dir = function(bufnr, on_dir)
    local deno_root = vim.fs.root(bufnr, { 'deno.json', 'deno.jsonc', 'deno.lock' })
    local project_root = vim.fs.root(bufnr, {
      'tsconfig.json',
      'jsconfig.json',
      'package.json',
      'package-lock.json',
      'pnpm-lock.yaml',
      'yarn.lock',
      'bun.lock',
      'bun.lockb',
      '.git',
    })

    if deno_root and (not project_root or #deno_root >= #project_root) then return end
    on_dir(project_root or vim.fn.getcwd())
  end,
}
