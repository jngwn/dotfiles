-- Quickfix reference {{{
-- <leader> = \
--
-- Search
--   <leader>sg         Search project contents with ripgrep
--   <leader>sf         Search project file names with fd
--   Visual (one line)  Use the same mappings for a literal search
--
-- Quickfix
--   <leader>qf         Toggle the quickfix window
--   <leader>qd         Send known diagnostics to quickfix
--   q                  Close the quickfix window
--   Enter              Open an item and keep quickfix available
-- }}}

local quickfix_height = 20
local search_generation = 0
local quickfix_group = vim.api.nvim_create_augroup('builtin_quickfix', { clear = true })

local function quickfix_window() return vim.fn.getqflist({ winid = 0 }).winid end

local function open_quickfix() vim.cmd(('botright copen %d'):format(quickfix_height)) end

local function toggle_quickfix()
  if quickfix_window() ~= 0 then
    vim.cmd.cclose()
    return
  end

  if vim.fn.getqflist({ size = 0 }).size == 0 then
    vim.notify('Quickfix is empty.', vim.log.levels.INFO)
    return
  end

  open_quickfix()
end

local function absolute_path(cwd, path)
  if path:sub(1, 1) == '/' then return vim.fs.normalize(path) end
  return vim.fs.normalize(vim.fs.joinpath(cwd, path))
end

local function set_quickfix(title, items, empty_message, text_function)
  local list = {
    title = title,
    items = items,
  }
  if text_function then list.quickfixtextfunc = text_function end
  vim.fn.setqflist({}, ' ', list)

  if #items == 0 then
    vim.notify(empty_message, vim.log.levels.INFO)
    return
  end

  open_quickfix()
end

local function command_error(label, result)
  local detail = vim.trim(result.stderr or '')
  vim.notify(label .. ' failed' .. (detail == '' and '.' or ':\n' .. detail), vim.log.levels.ERROR)
end

local function next_search()
  search_generation = search_generation + 1
  return search_generation
end

local function current_search(generation) return generation == search_generation end

local function file_quickfix_text(info)
  local items = vim.fn.getqflist({ id = info.id, items = 0 }).items
  local lines = {}
  for index = info.start_idx, info.end_idx do
    local item = items[index]
    local path = item and item.user_data
    if type(path) ~= 'string' or path == '' then
      path = item and vim.fn.fnamemodify(vim.fn.bufname(item.bufnr), ':p:.') or ''
    end
    table.insert(lines, path)
  end
  return lines
end

local function grep_project(query, literal)
  if vim.fn.executable 'rg' ~= 1 then
    vim.notify('ripgrep is unavailable.', vim.log.levels.ERROR)
    return
  end

  local cwd = vim.fn.getcwd()
  local generation = next_search()
  local command = {
    'rg',
    '--vimgrep',
    '--smart-case',
    '--hidden',
    '--glob',
    '!**/.git/**',
  }
  if literal then table.insert(command, '--fixed-strings') end
  vim.list_extend(command, { '--', query, '.' })

  vim.system(command, { cwd = cwd, text = true }, function(result)
    vim.schedule(function()
      if not current_search(generation) then return end

      local title = 'Grep: ' .. query
      if result.code == 1 then
        set_quickfix(title, {}, 'No grep matches.')
        return
      end
      if result.code ~= 0 then
        command_error('ripgrep', result)
        return
      end

      local items = {}
      for line in vim.gsplit(result.stdout or '', '\n', { plain = true, trimempty = true }) do
        local path, lnum, col, text = line:match '^(.-):(%d+):(%d+):(.*)$'
        if path then
          table.insert(items, {
            filename = absolute_path(cwd, path),
            lnum = tonumber(lnum),
            col = tonumber(col),
            text = text,
          })
        end
      end
      set_quickfix(title, items, 'No grep matches.')
    end)
  end)
end

local function find_project_files(query)
  if vim.fn.executable 'fd' ~= 1 then
    vim.notify('fd is unavailable.', vim.log.levels.ERROR)
    return
  end

  local cwd = vim.fn.getcwd()
  local generation = next_search()
  local command = {
    'fd',
    '--type',
    'file',
    '--hidden',
    '--exclude',
    '.git',
    '--fixed-strings',
    '--full-path',
    '--',
    query,
    '.',
  }

  vim.system(command, { cwd = cwd, text = true }, function(result)
    vim.schedule(function()
      if not current_search(generation) then return end
      if result.code ~= 0 then
        command_error('fd', result)
        return
      end

      local items = {}
      for path in vim.gsplit(result.stdout or '', '\n', { plain = true, trimempty = true }) do
        local display_path = vim.fs.normalize(path)
        table.insert(items, {
          filename = absolute_path(cwd, path),
          lnum = 1,
          col = 1,
          user_data = display_path,
        })
      end
      set_quickfix('Files: ' .. query, items, 'No matching files.', file_quickfix_text)
    end)
  end)
end

local function prompt_for_query(prompt, callback)
  vim.ui.input({ prompt = prompt, scope = 'project' }, function(query)
    if query == nil then return end
    if vim.trim(query) == '' then
      vim.notify('Search query is empty.', vim.log.levels.INFO)
      return
    end
    callback(query)
  end)
end

local function visual_query()
  local mode = vim.fn.mode()
  local lines = vim.fn.getregion(vim.fn.getpos 'v', vim.fn.getpos '.', { type = mode })
  vim.cmd.normal { args = { vim.keycode '<Esc>' }, bang = true }

  if #lines ~= 1 then
    vim.notify('Select a single line to search.', vim.log.levels.INFO)
    return
  end

  local query = lines[1]
  if vim.trim(query) == '' then
    vim.notify('Search selection is empty.', vim.log.levels.INFO)
    return
  end
  return query
end

vim.keymap.set('n', '<leader>sg', function()
  prompt_for_query('Grep: ', function(query) grep_project(query, false) end)
end, { desc = 'Search project contents' })
vim.keymap.set('x', '<leader>sg', function()
  local query = visual_query()
  if query then grep_project(query, true) end
end, { desc = 'Search project for selection' })

vim.keymap.set(
  'n',
  '<leader>sf',
  function() prompt_for_query('Files: ', find_project_files) end,
  { desc = 'Search project file names' }
)
vim.keymap.set('x', '<leader>sf', function()
  local query = visual_query()
  if query then find_project_files(query) end
end, { desc = 'Search project file names for selection' })

vim.keymap.set('n', '<leader>qf', toggle_quickfix, { desc = 'Toggle quickfix' })
vim.keymap.set('n', '<leader>qd', function()
  vim.diagnostic.setqflist { open = false, title = 'Diagnostics' }
  if vim.fn.getqflist({ size = 0 }).size == 0 then
    vim.notify('No diagnostics.', vim.log.levels.INFO)
    return
  end
  open_quickfix()
end, { desc = 'Send diagnostics to quickfix' })

vim.api.nvim_create_autocmd('FileType', {
  group = quickfix_group,
  pattern = 'qf',
  callback = function(event)
    vim.keymap.set('n', 'q', '<cmd>close<CR>', {
      buffer = event.buf,
      desc = 'Close quickfix window',
      silent = true,
    })
  end,
  desc = 'Set quickfix buffer mappings',
})

vim.api.nvim_create_autocmd('BufWinEnter', {
  group = quickfix_group,
  callback = function(event)
    if vim.bo[event.buf].buftype ~= 'quickfix' then return end

    local winid = quickfix_window()
    if winid ~= 0 and vim.api.nvim_win_get_buf(winid) == event.buf then
      vim.api.nvim_win_set_height(winid, quickfix_height)
    end
  end,
  desc = 'Use the default quickfix window height',
})
