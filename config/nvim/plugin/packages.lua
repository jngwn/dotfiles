-- Plugin packages {{{
local packages = {
  { src = 'https://github.com/stevearc/oil.nvim' },
}

local ok, err = pcall(vim.pack.add, packages, { load = true })
if not ok then vim.notify(('Failed to add plugins:\n%s'):format(err), vim.log.levels.ERROR) end
-- }}}
