local packages = {
  { src = 'https://github.com/stevearc/oil.nvim' },
  { src = 'https://github.com/lewis6991/gitsigns.nvim' },
  { src = 'https://github.com/nvim-mini/mini.indentscope' },
  {
    src = 'https://github.com/mechatroner/rainbow_csv',
    data = { preload = 'rainbow-csv.lua' },
  },
  {
    src = 'https://github.com/AndrewRadev/tagalong.vim',
    data = { preload = 'tagalong.lua' },
  },
  {
    src = 'https://github.com/alvan/vim-closetag',
    data = { preload = 'vim-closetag.lua' },
  },
}

local function load_package(package)
  local preload = package.spec.data and package.spec.data.preload
  if preload then
    local path = vim.fs.joinpath(vim.fn.stdpath 'config', 'after', 'plugin', preload)
    local configured, config_err = pcall(dofile, path)
    if not configured then
      vim.notify_once(
        ('Failed to configure %s:\n%s'):format(package.spec.name, config_err),
        vim.log.levels.WARN
      )
      return
    end
  end

  vim.cmd.packadd(package.spec.name)
end

local ok, err = pcall(vim.pack.add, packages, { load = load_package })
if not ok then vim.notify(('Failed to add plugins:\n%s'):format(err), vim.log.levels.ERROR) end
