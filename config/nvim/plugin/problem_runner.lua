-- Workflow for solving self-contained programming problems in a single source file.
-- Project builds, tests, dependency management, and debugging remain terminal-owned.
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
  cpp = {
    name = 'C++',
    extensions = { 'cpp', 'cc', 'cxx' },
    compile = {
      'clang++',
      '-std=c++23',
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
  rust = {
    name = 'Rust',
    extensions = { 'rs' },
    compile = {
      'rustc',
      '--edition=2024',
      '-C',
      'debuginfo=2',
      '-C',
      'opt-level=0',
      '{source}',
      '-o',
      '{executable}',
    },
    run = { '{executable}' },
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

  if not supported then
    if vim.b[bufnr].problem_runner_keymaps_enabled then
      for _, mapping in ipairs(problem_runner_keymaps) do
        pcall(vim.keymap.del, 'n', mapping.lhs, { buffer = bufnr })
      end
      vim.b[bufnr].problem_runner_keymaps_enabled = nil
    end
    return
  end

  for _, mapping in ipairs(problem_runner_keymaps) do
    vim.keymap.set('n', mapping.lhs, mapping.callback, {
      buffer = bufnr,
      desc = mapping.desc,
    })
  end
  vim.b[bufnr].problem_runner_keymaps_enabled = true
end

local problem_runner_keymap_group =
  vim.api.nvim_create_augroup('problem_runner_keymaps', { clear = true })
vim.api.nvim_create_autocmd({ 'BufEnter', 'BufFilePost' }, {
  group = problem_runner_keymap_group,
  callback = function(args) configure_problem_runner_keymaps(args.buf) end,
  desc = 'Enable problem-runner keymaps only for supported source files',
})
configure_problem_runner_keymaps(vim.api.nvim_get_current_buf())
