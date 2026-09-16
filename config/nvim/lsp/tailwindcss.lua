local config_files = {
  'tailwind.config.js',
  'tailwind.config.cjs',
  'tailwind.config.mjs',
  'tailwind.config.ts',
  'tailwind.config.cts',
  'tailwind.config.mts',
}

local function package_uses_tailwind(path)
  local file = io.open(path, 'r')
  if not file then return false end
  local content = file:read '*a'
  file:close()

  local ok, package = pcall(vim.json.decode, content)
  if not ok or type(package) ~= 'table' then return false end
  for _, section in ipairs {
    'dependencies',
    'devDependencies',
    'peerDependencies',
    'optionalDependencies',
  } do
    if type(package[section]) == 'table' and package[section].tailwindcss then return true end
  end
  return false
end

return {
  cmd = { 'tailwindcss-language-server', '--stdio' },
  filetypes = {
    'html',
    'css',
    'javascript',
    'javascriptreact',
    'typescript',
    'typescriptreact',
  },
  root_dir = function(bufnr, on_dir)
    local path = vim.api.nvim_buf_get_name(bufnr)
    local start_dir = vim.fs.dirname(path)
    local config = vim.fs.find(config_files, { path = start_dir, upward = true, type = 'file' })[1]
    if config then
      on_dir(vim.fs.dirname(config))
      return
    end

    local packages = vim.fs.find('package.json', {
      path = start_dir,
      upward = true,
      type = 'file',
      limit = math.huge,
    })
    for _, package in ipairs(packages) do
      if package_uses_tailwind(package) then
        on_dir(vim.fs.dirname(package))
        return
      end
    end
  end,
}
