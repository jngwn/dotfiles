vim.g.mapleader = '\\'

-- Clipboard {{{
local use_terminal_clipboard = vim.fn.has 'wsl' == 1
  or vim.env.SSH_TTY ~= nil
  or vim.env.SSH_CONNECTION ~= nil
if use_terminal_clipboard then
  -- OSC 52 reads are not portable, so keep ordinary paste editor-local.
  local copy_to_terminal = require('vim.ui.clipboard.osc52').copy '+'
  vim.api.nvim_create_autocmd('TextYankPost', {
    callback = function()
      if vim.v.event.operator == 'y' and vim.v.event.regname == '' then
        copy_to_terminal(vim.v.event.regcontents)
      end
    end,
  })
else
  vim.opt.clipboard = 'unnamedplus'
end
-- }}}

-- Plugins {{{
vim.pack.add {
  { src = 'https://github.com/stevearc/oil.nvim' },
}
-- }}}

-- oil.nvim {{{
do
  local ok, oil = pcall(require, 'oil')
  if not ok then
    vim.notify(('Failed to load oil:\n%s'):format(oil), vim.log.levels.WARN)
  else
    oil.setup {
      default_file_explorer = true,
      delete_to_trash = true,

      columns = {},

      view_options = {
        show_hidden = true,
      },

      keymaps = {
        q = 'actions.close',
      },
    }

    local function toggle_oil(path)
      if vim.bo.filetype == 'oil' then
        oil.close()
      elseif path then
        oil.open(path)
      else
        vim.cmd 'Oil'
      end
    end

    vim.keymap.set('n', '<leader>ef', function() toggle_oil() end, {
      desc = 'Toggle Oil (parent directory)',
    })

    vim.keymap.set(
      'n',
      '<leader>ec',
      function() toggle_oil(vim.fn.getcwd()) end,
      { desc = 'Toggle Oil (CWD)' }
    )
  end
end
-- }}}

-- Options {{{
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.softtabstop = 2
vim.opt.tabstop = 2

vim.opt.ignorecase = true
vim.opt.smartcase = true

vim.opt.colorcolumn = '+1'
vim.opt.cursorline = true
vim.opt.cursorlineopt = 'number'
vim.opt.list = true
vim.opt.listchars = { tab = '→ ', trail = '·', extends = '»', precedes = '«', nbsp = '░' }
vim.opt.fillchars = {
  eob = ' ',
  fold = '-',
  diff = '╱',
}
vim.opt.number = true
vim.opt.showcmd = true
vim.opt.statusline = " %{%&diff ? '%<%-20.50F' : '%f'%} %m%r %= %< %l/%L, %3c "

vim.opt.linebreak = true
vim.opt.scrolloff = 8
vim.opt.showbreak = '+++ '
vim.opt.sidescrolloff = 8
vim.opt.smoothscroll = true
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.virtualedit = 'block'
vim.opt.wrap = false

vim.opt.autochdir = false -- Keep relative paths anchored to the explicit working directory.
vim.opt.autoread = true
vim.opt.updatetime = 100
vim.opt.undofile = true
vim.opt.backup = false
vim.opt.writebackup = false
vim.opt.swapfile = false
vim.opt.fileencodings = 'utf-8,euckr,cp949,latin1'
vim.opt.isfname:remove '='
vim.opt.modeline = false
vim.api.nvim_create_autocmd({ 'FocusGained', 'BufEnter', 'CursorHold' }, {
  command = 'checktime', -- Detect files changed by external tools.
})

vim.opt.wildignorecase = true
vim.opt.wildmode = 'list:longest,full'
vim.opt.foldmethod = 'marker'
vim.opt.foldopen:remove 'block'
vim.opt.showmatch = true

vim.opt.diffopt:append 'vertical'

vim.opt.termguicolors = true
vim.opt.background = 'light'
if not pcall(vim.cmd.colorscheme, 'paper-custom') then vim.cmd.colorscheme 'default' end
-- }}}

-- key-mapping {{{
vim.keymap.set('i', 'jk', '<ESC>')
vim.keymap.set({ 'n', 'v' }, ',', ':')
vim.keymap.set('n', '<S-u>', '<C-r>')
vim.keymap.set('n', 'Q', '<NOP>')
vim.keymap.set('n', 'gQ', '<NOP>')

vim.keymap.set('n', 'j', 'gj')
vim.keymap.set('n', 'k', 'gk')
vim.keymap.set('n', '0', 'g0')
vim.keymap.set('n', '^', 'g^')
vim.keymap.set('n', '$', 'g$')

vim.keymap.set('v', '<', '<gv')
vim.keymap.set('v', '>', '>gv')

vim.keymap.set('n', '<leader>v', '<C-v>')
vim.keymap.set('i', '{<CR>', '{<CR>}<Esc>O')
vim.keymap.set('n', '<leader>bb', '<C-o>', { desc = 'Jump Back' })
vim.keymap.set('n', '<leader>gg', '<C-i>', { desc = 'Jump Forward' })
vim.keymap.set('n', '<leader>ss', '<C-^>', { desc = 'Switch Alternate Buffer' })

local blackhole_keys = { 'c', 'C', 's', 'S', 'x', 'X' }
for _, key in ipairs(blackhole_keys) do
  vim.keymap.set({ 'n', 'v' }, key, '"_' .. key)
end

-- Visual P replaces the selection without overwriting the unnamed register.
-- Map p to that behavior so repeated paste keeps the copied text stable.
vim.keymap.set('x', 'p', 'P')

vim.keymap.set('n', '[b', '<cmd>bprevious<CR>', { silent = true })
vim.keymap.set('n', ']b', '<cmd>bnext<CR>', { silent = true })
vim.keymap.set('n', '[t', '<cmd>tabprevious<CR>', { silent = true })
vim.keymap.set('n', ']t', '<cmd>tabnext<CR>', { silent = true })

vim.keymap.set('n', '<leader>w', '<C-w>')
vim.keymap.set('n', '<leader>1', '<C-w>h')
vim.keymap.set('n', '<leader>2', '<C-w>j')
vim.keymap.set('n', '<leader>3', '<C-w>k')
vim.keymap.set('n', '<leader>4', '<C-w>l')
vim.keymap.set('n', '<leader>5', '<cmd>vertical resize -10<CR>', { silent = true })
vim.keymap.set('n', '<leader>6', '<cmd>resize -10<CR>', { silent = true })
vim.keymap.set('n', '<leader>7', '<cmd>resize +10<CR>', { silent = true })
vim.keymap.set('n', '<leader>8', '<cmd>vertical resize +10<CR>', { silent = true })

vim.keymap.set('n', '<leader>qq', '<cmd>qa<CR>', { silent = true })
vim.keymap.set('n', '<leader>a', 'ggVG')
-- }}}

-- Text cleanup {{{
local function trim_trailing_whitespace()
  local save_view = vim.fn.winsaveview()
  vim.cmd [[silent! keeppatterns %s/\s\+$//e]]
  vim.fn.winrestview(save_view)
end

vim.api.nvim_create_user_command('TrimWhitespace', trim_trailing_whitespace, {
  desc = 'Remove trailing whitespace from the current buffer',
})

local function trim_carriage_return()
  local save_view = vim.fn.winsaveview()
  vim.cmd [[silent! keeppatterns %s/\r//e]]
  vim.fn.winrestview(save_view)
end

vim.api.nvim_create_user_command('TrimCarriageReturn', trim_carriage_return, {
  desc = 'Remove carriage return (\r) characters from the current buffer',
})

vim.keymap.set('n', '<leader>ct', function()
  trim_carriage_return()
  trim_trailing_whitespace()
end, { desc = 'Clean text whitespace' })
-- }}}

-- Hangul input source {{{
local input_source_reset_in_flight = false

local function input_source_reset_command()
  if vim.fn.executable 'fcitx5-remote' == 1 then return { 'fcitx5-remote', '-c' } end
  if vim.fn.executable 'ibus' == 1 then return { 'ibus', 'engine', 'xkb:us::eng' } end
end

local function reset_input_source()
  if vim.env.SSH_TTY or vim.env.SSH_CONNECTION then return end
  if not vim.env.DISPLAY and not vim.env.WAYLAND_DISPLAY then return end
  if input_source_reset_in_flight then return end

  local command = input_source_reset_command()
  if not command then return end

  -- The desktop input method owns session-wide state. Reset asynchronously so
  -- leaving insert mode never waits for Fcitx or IBus IPC.
  input_source_reset_in_flight = true
  local ok = pcall(vim.system, command, { text = true }, function()
    vim.schedule(function() input_source_reset_in_flight = false end)
  end)

  if not ok then input_source_reset_in_flight = false end
end

vim.keymap.set('n', '<Esc>', function()
  reset_input_source()
  vim.cmd.nohlsearch()
end, { silent = true, desc = 'Clear search and reset input source' })

vim.keymap.set('v', '<Esc>', function()
  reset_input_source()
  return '<Esc>'
end, { expr = true, silent = true, desc = 'Reset input source and escape' })

vim.keymap.set('i', 'ㅓㅏ', '<Esc>', { desc = 'Escape insert mode with Hangul input' })

vim.api.nvim_create_autocmd('InsertLeave', {
  callback = reset_input_source,
  desc = 'Reset Hangul input source after insert mode editing',
})
-- }}}

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

-- Problem-solving runner {{{
local problem_input_default_enabled = true
-- Placeholder values are shell-escaped when commands are built.
local problem_languages = {
  c = {
    name = 'C',
    extensions = { 'c' },
    compile = {
      'clang',
      '-std=c99',
      '-Wall',
      '-Wextra',
      '-Wpedantic',
      '-g',
      '-O0',
      '{source}',
      '-o',
      '{executable}',
    },
    run = { '{executable}' },
  },
  python = {
    name = 'Python',
    extensions = { 'py' },
    run = { 'python3', '{source}' },
  },
  java = {
    name = 'Java',
    extensions = { 'java' },
    compile = { 'javac', '{source}' },
    run = { 'java', '{class_name}' },
  },
}

local problem_language_by_extension = {}
local problem_language_names = {}
for _, language in pairs(problem_languages) do
  table.insert(problem_language_names, language.name)
  for _, extension in ipairs(language.extensions) do
    problem_language_by_extension[extension] = language
  end
end
table.sort(problem_language_names)

local function current_problem_source()
  local bufnr = vim.api.nvim_get_current_buf()
  local source_path = vim.api.nvim_buf_get_name(bufnr)
  if source_path == '' then
    vim.notify('Save the source file before running it.', vim.log.levels.WARN)
    return nil
  end

  local extension = vim.fn.fnamemodify(source_path, ':e'):lower()
  local language = problem_language_by_extension[extension]
  if not language then
    vim.notify(
      'Problem runner supports ' .. table.concat(problem_language_names, ', ') .. ' source files.',
      vim.log.levels.WARN
    )
    return nil
  end

  if vim.bo[bufnr].modified then vim.cmd 'write' end
  return bufnr, vim.fn.fnamemodify(source_path, ':p'), language
end

local function problem_input_path(source_path) return vim.fn.fnamemodify(source_path, ':r') .. '.in' end

local function problem_input_enabled(bufnr)
  local enabled = vim.b[bufnr].problem_input_enabled
  if enabled == nil then return problem_input_default_enabled end
  return enabled
end

local function open_problem_input()
  local _, source_path = current_problem_source()
  if not source_path then return end

  local input_path = problem_input_path(source_path)
  if vim.fn.filereadable(input_path) ~= 1 then
    if vim.uv.fs_stat(input_path) then
      vim.notify('Input file is not readable: ' .. input_path, vim.log.levels.ERROR)
      return
    end
    if vim.fn.writefile({}, input_path) ~= 0 then
      vim.notify('Could not create input file: ' .. input_path, vim.log.levels.ERROR)
      return
    end
  end
  vim.cmd('rightbelow split ' .. vim.fn.fnameescape(input_path))
  vim.bo.filetype = 'text'
end

local function toggle_problem_input()
  local bufnr = vim.api.nvim_get_current_buf()
  local enabled = not problem_input_enabled(bufnr)
  vim.b[bufnr].problem_input_enabled = enabled
  vim.notify(
    'Problem runner input redirection: ' .. (enabled and 'enabled' or 'disabled'),
    vim.log.levels.INFO
  )
end

local function render_problem_command(command_template, values)
  local command = {}
  for _, argument in ipairs(command_template) do
    local placeholder = argument:match '^%{(.+)%}$'
    local value = (placeholder and values[placeholder]) or argument
    table.insert(command, vim.fn.shellescape(value))
  end
  return table.concat(command, ' ')
end

local function build_problem_command(source_path, language, input_path)
  local values = {
    source = source_path,
    class_name = vim.fn.fnamemodify(source_path, ':t:r'),
  }
  if language.compile then
    local executable_path = vim.fn.fnamemodify(source_path, ':r') .. '.out'
    values.executable = executable_path
  end

  local run_command = render_problem_command(language.run, values)
  if input_path then
    local escaped_input = vim.fn.shellescape(input_path)
    run_command = run_command .. ' < ' .. escaped_input
  end
  if not language.compile then return run_command end

  return render_problem_command(language.compile, values) .. ' && ' .. run_command
end

local function open_problem_runner_output()
  local current_tabpage = vim.api.nvim_get_current_tabpage()
  local problem_runner_window = vim.t.problem_runner_window
  local reuse_output = problem_runner_window
    and vim.api.nvim_win_is_valid(problem_runner_window)
    and vim.api.nvim_win_get_tabpage(problem_runner_window) == current_tabpage
  local output_buffer

  if reuse_output then
    vim.api.nvim_set_current_win(problem_runner_window)
    vim.cmd 'resize 14'
    output_buffer = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_win_set_buf(problem_runner_window, output_buffer)
  else
    vim.cmd 'botright 14new'
    problem_runner_window = vim.api.nvim_get_current_win()
    vim.t.problem_runner_window = problem_runner_window
    output_buffer = vim.api.nvim_get_current_buf()
    vim.bo[output_buffer].buflisted = false
  end

  -- A scratch buffer avoids inheriting the source filetype after a split.
  vim.bo[output_buffer].bufhidden = 'wipe'
  vim.bo[output_buffer].swapfile = false
  vim.bo[output_buffer].filetype = 'terminal'
end

local function run_problem_source()
  local bufnr, source_path, language = current_problem_source()
  if not source_path then return end

  local input_path
  if problem_input_enabled(bufnr) then
    local candidate_input_path = problem_input_path(source_path)
    if vim.fn.filereadable(candidate_input_path) == 1 then input_path = candidate_input_path end
  end

  local command = build_problem_command(source_path, language, input_path)
  open_problem_runner_output()
  vim.fn.jobstart({ 'sh', '-c', command }, {
    cwd = vim.fn.fnamemodify(source_path, ':h'),
    term = true,
  })
  vim.cmd 'startinsert'
end

vim.api.nvim_create_user_command('ProblemInputToggle', toggle_problem_input, {
  desc = 'Toggle input-file redirection for the current problem source',
})
vim.api.nvim_create_user_command('ProblemRun', run_problem_source, {
  desc = 'Compile or run the current single-file problem source',
})

local problem_runner_keymaps = {
  { lhs = '<leader>er', callback = run_problem_source, desc = 'Problem run' },
  { lhs = '<leader>ei', callback = open_problem_input, desc = 'Problem input split' },
  { lhs = '<leader>et', callback = toggle_problem_input, desc = 'Problem toggle input' },
}

local function configure_problem_runner_keymaps(bufnr)
  local extension = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ':e'):lower()
  local supported = problem_language_by_extension[extension] ~= nil

  for _, mapping in ipairs(problem_runner_keymaps) do
    if supported then
      vim.keymap.set('n', mapping.lhs, mapping.callback, {
        buffer = bufnr,
        desc = mapping.desc,
      })
    else
      vim.keymap.set('n', mapping.lhs, '<Nop>', {
        buffer = bufnr,
        silent = true,
        desc = 'Problem runner unavailable for this file type',
      })
    end
  end
end

local problem_runner_keymap_group =
  vim.api.nvim_create_augroup('problem_runner_keymaps', { clear = true })
vim.api.nvim_create_autocmd({ 'BufEnter', 'BufFilePost' }, {
  group = problem_runner_keymap_group,
  callback = function(args) configure_problem_runner_keymaps(args.buf) end,
  desc = 'Enable problem-runner keymaps only for supported source files',
})
configure_problem_runner_keymaps(vim.api.nvim_get_current_buf())
-- }}}
