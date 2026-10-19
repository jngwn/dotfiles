local packages = {
  { src = 'https://github.com/stevearc/oil.nvim' },
}

local function load_package(package) vim.cmd.packadd(package.spec.name) end

local ok, err = pcall(vim.pack.add, packages, { load = load_package })
if not ok then vim.notify(('Failed to add plugins:\n%s'):format(err), vim.log.levels.ERROR) end
