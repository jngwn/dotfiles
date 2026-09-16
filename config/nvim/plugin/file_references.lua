-- Copy File References {{{
local function get_file_reference_data()
  -- %:. is cwd-relative when possible and falls back to absolute when the file is outside cwd.
  local rel_path = vim.fn.expand '%:.'
  local abs_path = vim.fn.expand '%:p'

  local mode = vim.api.nvim_get_mode().mode
  local is_visual = mode:match '[vV\22]' ~= nil
  local start_line
  local end_line

  if is_visual then
    local v_start = vim.fn.getpos('v')[2]
    local v_end = vim.fn.getpos('.')[2]
    start_line = math.min(v_start, v_end)
    end_line = math.max(v_start, v_end)

    local esc = vim.api.nvim_replace_termcodes('<Esc>', true, false, true)
    vim.api.nvim_feedkeys(esc, 'n', true)
  else
    start_line = vim.fn.line '.'
    end_line = start_line
  end

  return {
    rel_path = rel_path,
    abs_path = abs_path,
    start_line = start_line,
    end_line = end_line,
  }
end

local function format_line_ref(path, start_line, end_line)
  if start_line == end_line then return string.format('%s:%d', path, start_line) end
  return string.format('%s:%d-%d', path, start_line, end_line)
end

local function create_copy_command(format_type)
  return function()
    local data = get_file_reference_data()
    local result = ''

    if format_type == 'relative_reference' then
      result = format_line_ref(data.rel_path, data.start_line, data.end_line)
    elseif format_type == 'relative_path' then
      result = data.rel_path
    elseif format_type == 'absolute_reference' then
      result = format_line_ref(data.abs_path, data.start_line, data.end_line)
    elseif format_type == 'absolute_path' then
      result = data.abs_path
    end

    vim.fn.setreg('+', result)
    -- Visual mappings queue <Esc> above; notify on the next event-loop turn so
    -- the mode-exit redraw cannot immediately erase the copied-range message.
    vim.schedule(function() vim.notify('Copied: ' .. result, vim.log.levels.INFO) end)
  end
end

local copy_mappings = {
  ['<leader>or'] = { type = 'relative_reference', desc = 'Copy Ref Relative' },
  ['<leader>oe'] = { type = 'relative_path', desc = 'Copy Path Relative' },
  ['<leader>of'] = { type = 'absolute_reference', desc = 'Copy Ref Absolute' },
  ['<leader>od'] = { type = 'absolute_path', desc = 'Copy Path Absolute' },
}

for key, opts in pairs(copy_mappings) do
  vim.keymap.set({ 'n', 'x' }, key, create_copy_command(opts.type), {
    silent = true,
    desc = opts.desc,
  })
end
-- }}}
