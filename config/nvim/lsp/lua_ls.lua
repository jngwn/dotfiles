return {
  cmd = { 'lua-language-server' },
  filetypes = { 'lua' },
  root_dir = function(bufnr, on_dir)
    local root = vim.fs.root(bufnr, { '.stylua.toml' })
    if root and vim.uv.fs_stat(vim.fs.joinpath(root, 'init.lua')) then on_dir(root) end
  end,
  settings = {
    Lua = {
      runtime = {
        version = 'LuaJIT',
      },
      workspace = {
        checkThirdParty = false,
        library = { vim.env.VIMRUNTIME },
      },
    },
  },
}
