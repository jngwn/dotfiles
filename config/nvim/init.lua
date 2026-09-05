-- ~/.config/nvim/init.lua
-- Personal Neovim configuration.
-- Scope:
-- - Quickly edit and review individual local scripts, configuration, and source files from the terminal.
-- - Solve job-interview programming problems in supported standalone source files.
-- - Use Oil as the default file manager for nearby directories and explicit file operations.
-- - Support agentic coding by reviewing agent changes and exchanging precise file/line references.
-- - Project builds, tests, dependencies, debugging, and broad automation remain project or terminal owned.
-- This config prioritizes simplicity, core Neovim APIs, and long-term maintainability.
-- Plugins are used only when they provide clear, irreplaceable value.
-- Keep this file as the single source of truth for Neovim; do not split into modules unless the workflow grows enough to justify it.
-- Preserve the existing {{{ / }}} fold structure.
-- Preserve intentionally commented-out Lua code; it records maintained options and rollback references.
-- Prefer minimal, explicit changes over broad refactors.
-- Keymaps and workflows are intentionally opinionated.
-- Do not add or configure Treesitter; prefer Neovim's default syntax unless explicitly requested.
-- Keep LSP limited to clangd for C/C++, Ruff and ty for Python, and Lua
-- Language Server with automatic completion.
-- ---------------------------------------------------------
vim.g.mapleader = '\\'
vim.g.maplocalleader = '\\'
if vim.env.SSH_TTY or vim.env.SSH_CONNECTION then vim.g.clipboard = 'osc52' end
vim.opt.termguicolors = true

-- Disable built-in plugins {{{
-- ---------------------------------------------------------
vim.g.loaded_spellfile_plugin = 1
vim.g.loaded_gzip = 1
-- vim.g.loaded_man = 1
-- vim.g.loaded_matchit = 1
vim.g.loaded_matchparen = 1
vim.g.loaded_nvim_net_plugin = 1
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
-- vim.g.termfeatures = 1
-- vim.g.termfeatures.osc52 = 1
vim.g.loaded_remote_plugins = 1
-- vim.g.loaded_shada_plugin = 1
vim.g.loaded_tarPlugin = 1
vim.g.loaded_tutor_mode_plugin = 1
vim.g.loaded_zipPlugin = 1

-- Disable legacy remote providers; this config uses built-in Lua APIs and minimal Lua plugins.
vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_node_provider = 0
-- }}}

-- Neovim 0.12+ builtin package manager {{{
-- ---------------------------------------------------------
-- Maintenance: run ":lua vim.pack.update()" or ":lua vim.pack.update({ '<PLUGIN_NAME>' })".
-- Run ":checkhealth" after updates or when maintained integrations fail; disabled legacy providers above are intentional.

-- Plugin List {{{
-- ---------------------------------------------------------
-- vim.fn.stdpath('data') .. '/site/pack/core/opt/'
-- Keep the plugin list small; prefer built-in features for routine workflows.
-- Debugging stays terminal/IDE-first; do not add nvim-dap without a repeated Neovim debugging workflow.
-- If plugin entries are deliberately commented out, keep them; they document considered options.
local plugins = {
  { src = 'https://github.com/stevearc/oil.nvim' },
  { src = 'https://github.com/lewis6991/gitsigns.nvim' },
  { src = 'https://github.com/nvim-mini/mini.pairs' },
  { src = 'https://github.com/folke/flash.nvim' },
  { src = 'https://github.com/lukas-reineke/indent-blankline.nvim' },
}
-- }}}

vim.pack.add(plugins)
-- Neovim 0.12+ builtin package manager }}}

-- oil.nvim {{{
-- ---------------------------------------------------------
do
  local ok_oil, oil = pcall(require, 'oil')
  if ok_oil then
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

      float = {
        padding = 2,
        max_width = 100,
        max_height = 0.8,
        border = 'single',
        win_options = {
          winblend = 10,
        },
      },
    }

    vim.keymap.set('n', '-', '<cmd>Oil<cr>', {
      desc = 'Open parent directory',
    })

    vim.keymap.set('n', '<leader>-', oil.toggle_float, {
      desc = 'Open Oil (Floating)',
    })

    local function oil_target_dir(is_current_file)
      local target_dir = vim.fn.getcwd()
      if is_current_file then
        local current_file = vim.fn.expand '%:p'
        if current_file ~= '' and vim.fn.filereadable(current_file) == 1 then
          target_dir = vim.fn.expand '%:p:h'
        end
      end

      return target_dir
    end

    local function toggle_oil(is_current_file)
      if vim.bo.filetype == 'oil' then
        oil.close()
      else
        oil.open(oil_target_dir(is_current_file))
      end
    end

    vim.keymap.set(
      'n',
      '<leader>ef',
      function() toggle_oil(false) end,
      { desc = 'Toggle Oil (CWD)' }
    )
    vim.keymap.set(
      'n',
      '<leader>ec',
      function() toggle_oil(true) end,
      { desc = 'Toggle Oil (Current File)' }
    )
  end
end
-- }}}

-- flash.nvim {{{
-- ---------------------------------------------------------
-- Use Flash's upstream key layout while leaving f/t character motions unchanged.
do
  local ok_flash, flash = pcall(require, 'flash')
  if ok_flash then
    flash.setup {
      jump = {
        autojump = true,
        nohlsearch = true,
      },
      label = {
        uppercase = false,
      },
      modes = {
        char = {
          enabled = false,
        },
        search = {
          enabled = true,
        },
      },
    }

    vim.keymap.set({ 'n', 'x', 'o' }, 's', function() flash.jump() end, {
      desc = 'Flash jump',
    })
    vim.keymap.set({ 'n', 'x', 'o' }, 'S', function() flash.treesitter() end, {
      desc = 'Flash Treesitter',
    })
    vim.keymap.set('o', 'r', function() flash.remote() end, {
      desc = 'Remote Flash',
    })
    vim.keymap.set({ 'o', 'x' }, 'R', function() flash.treesitter_search() end, {
      desc = 'Treesitter Search',
    })
    vim.keymap.set('c', '<C-s>', function() flash.toggle() end, {
      desc = 'Toggle Flash search',
    })
  end
end
-- }}}

-- indent-blankline.nvim {{{
-- ---------------------------------------------------------
-- Scope guides require Treesitter, so alternate progressively darker Paper ink
-- colors by indent depth instead.
do
  local ok_ibl, ibl = pcall(require, 'ibl')
  if ok_ibl then
    local hooks = require 'ibl.hooks'
    hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
      vim.api.nvim_set_hl(0, 'IblInkDisabled', { fg = '#aaaaaa', nocombine = true })
      vim.api.nvim_set_hl(0, 'IblInkBorder', { fg = '#777777', nocombine = true })
      vim.api.nvim_set_hl(0, 'IblInkTertiary', { fg = '#555555', nocombine = true })
    end)

    ibl.setup {
      indent = {
        char = '┊',
        tab_char = '│',
        highlight = {
          'IblInkDisabled',
          'IblInkBorder',
          'IblInkTertiary',
        },
      },
      scope = {
        enabled = false,
      },
    }
  end
end
-- }}}

-- Options {{{
-- ---------------------------------------------------------
vim.g.editorconfig = true

vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.softtabstop = 2
vim.opt.tabstop = 2
vim.opt.textwidth = 0

vim.opt.ignorecase = true
vim.opt.joinspaces = false
vim.opt.smartcase = true
vim.opt.smarttab = true
vim.opt.wrapscan = true

vim.opt.cmdheight = 1 -- (0 <-> 1)
vim.opt.colorcolumn = '+1'
vim.opt.cursorcolumn = false
vim.opt.cursorline = true
vim.opt.cursorlineopt = 'number'
vim.opt.laststatus = 2 -- Global Statusline (2 <-> 3)
vim.opt.list = true
vim.opt.listchars = { tab = '→ ', trail = '·', extends = '»', precedes = '«', nbsp = '░' }
vim.opt.fillchars = {
  vert = '│',
  eob = ' ',
  fold = '-',
  foldopen = '▾',
  foldsep = ' ',
  foldclose = '▸',
  diff = '╱',
  stl = ' ',
  stlnc = ' ',
}
vim.opt.number = true
vim.opt.relativenumber = false
vim.opt.shortmess:append 'c'
vim.opt.showcmd = false
vim.opt.showmode = true
vim.opt.signcolumn = 'number'
vim.opt.statuscolumn = ''

vim.opt.display = 'lastline'
vim.opt.inccommand = 'split'
vim.opt.linebreak = true
vim.opt.scrolloff = 8
vim.opt.showbreak = '+++ '
vim.opt.sidescrolloff = 8
vim.opt.smoothscroll = true
vim.opt.splitbelow = true
vim.opt.splitkeep = 'screen'
vim.opt.splitright = true
vim.opt.virtualedit = 'block'
vim.opt.wrap = false

-- Preserve unwrapped source-code scanning while making prose documents readable.
local markdown_wrap_group = vim.api.nvim_create_augroup('markdown_wrap', { clear = true })
vim.api.nvim_create_autocmd({ 'BufWinEnter', 'FileType' }, {
  group = markdown_wrap_group,
  callback = function(args)
    local winid = vim.fn.bufwinid(args.buf)
    if winid == -1 then return end
    vim.wo[winid].wrap = vim.bo[args.buf].filetype == 'markdown'
  end,
})

vim.opt.autochdir = false -- Keep relative paths anchored to the explicit working directory.
vim.opt.autoread = true
vim.opt.clipboard = 'unnamedplus'
vim.opt.fileencodings = 'utf-8,euckr,cp949,latin1'
vim.opt.isfname:remove '='
vim.opt.langmenu = 'none'
vim.opt.lazyredraw = false
vim.opt.modeline = false
vim.opt.mouse = 'a'
vim.opt.synmaxcol = 250
vim.opt.updatetime = 100
vim.api.nvim_create_autocmd({ 'FocusGained', 'BufEnter', 'CursorHold' }, {
  command = 'checktime', -- For stable autoread
})

vim.opt.wildignorecase = true
vim.opt.wildmenu = true
vim.opt.wildmode = 'list:longest,full'
vim.opt.foldmarker = '{{{,}}}'
vim.opt.foldmethod = 'marker'
vim.opt.foldopen:remove 'block'
vim.opt.formatoptions = 'tcroqnlj'
vim.opt.showmatch = true

vim.opt.belloff = 'all'
vim.opt.diffopt = {
  'internal',
  'filler',
  'closeoff',
  'indent-heuristic',
  'inline:char',
  'linematch:60',
  'algorithm:histogram',
  'vertical',
}
vim.opt.nrformats = 'alpha,octal,hex,bin,unsigned'
-- }}}

-- Language servers {{{
-- ---------------------------------------------------------
vim.lsp.config('clangd', {
  cmd = { 'clangd', '--fallback-style=LLVM' },
  filetypes = { 'c', 'cpp' },
  root_markers = {
    'compile_commands.json',
    'compile_flags.txt',
    '.clangd',
    '.git',
  },
})

-- Ruff owns linting and formatting; ty owns type-aware language features.
vim.lsp.config('ruff', {
  cmd = { 'ruff', 'server' },
  filetypes = { 'python' },
  root_markers = {
    { 'pyproject.toml', 'ruff.toml', '.ruff.toml', 'uv.lock' },
    '.git',
  },
})

vim.lsp.config('ty', {
  cmd = { 'ty', 'server' },
  filetypes = { 'python' },
  root_markers = {
    { 'pyproject.toml', 'ty.toml', 'uv.lock' },
    '.git',
  },
})

vim.lsp.config('lua_ls', {
  cmd = { 'lua-language-server' },
  filetypes = { 'lua' },
  root_markers = {
    '.luarc.json',
    '.luarc.jsonc',
    '.git',
  },
  settings = {
    Lua = {
      diagnostics = {
        globals = { 'vim' },
      },
      telemetry = {
        enable = false,
      },
      workspace = {
        checkThirdParty = false,
        library = vim.api.nvim_get_runtime_file('', true),
      },
    },
  },
})

vim.lsp.enable { 'clangd', 'ruff', 'ty', 'lua_ls' }
-- }}}

-- LSP completion {{{
-- ---------------------------------------------------------
-- Use semantic completion only. Trigger while typing identifiers or after
-- server-defined syntax characters, but never on whitespace.
vim.opt.completeopt = {
  'menuone',
  'noinsert',
}
vim.opt.winborder = 'single'
vim.opt.pumborder = 'single'
vim.opt.pumheight = 12
vim.opt.pummaxwidth = 80
vim.opt.autocomplete = true
vim.opt.complete = { 'o' }

local function toggle_completion_popup()
  local enabled = not vim.o.autocomplete
  vim.opt.autocomplete = enabled

  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) then
      vim.api.nvim_set_option_value('autocomplete', enabled, { buf = bufnr })
    end
  end

  vim.notify(
    'Automatic completion popup: ' .. (enabled and 'enabled' or 'disabled'),
    vim.log.levels.INFO
  )
end

local function enable_lsp_completion(client, bufnr)
  if not client:supports_method 'textDocument/completion' then return false end

  local completion_provider = client.server_capabilities.completionProvider
  if not completion_provider then return false end

  -- Native LSP completion otherwise uses only server-defined punctuation such
  -- as '.', '>', or ':'. Add identifier characters for IDE-like suggestions
  -- while leaving spaces and unrelated punctuation alone.
  local trigger_characters = {}
  for _, character in ipairs(completion_provider.triggerCharacters or {}) do
    trigger_characters[character] = true
  end
  for byte = string.byte '0', string.byte '9' do
    trigger_characters[string.char(byte)] = true
  end
  for byte = string.byte 'A', string.byte 'Z' do
    trigger_characters[string.char(byte)] = true
  end
  trigger_characters._ = true
  for byte = string.byte 'a', string.byte 'z' do
    trigger_characters[string.char(byte)] = true
  end
  completion_provider.triggerCharacters = vim.tbl_keys(trigger_characters)

  vim.bo[bufnr].omnifunc = 'v:lua.vim.lsp.omnifunc'
  vim.lsp.completion.enable(true, client.id, bufnr, { autotrigger = true })
  return true
end

vim.keymap.set('n', '<leader>cp', toggle_completion_popup, {
  desc = 'Toggle automatic completion popup',
})

vim.keymap.set('i', '<Down>', function()
  if vim.fn.pumvisible() == 1 then return '<C-n>' end
  return '<Down>'
end, { expr = true, desc = 'Select next completion item' })
vim.keymap.set('i', '<Up>', function()
  if vim.fn.pumvisible() == 1 then return '<C-p>' end
  return '<Up>'
end, { expr = true, desc = 'Select previous completion item' })

local function cursor_is_in_indent()
  local column = vim.api.nvim_win_get_cursor(0)[2]
  return vim.api.nvim_get_current_line():sub(1, column):match '^%s*$' ~= nil
end

vim.keymap.set('i', '<Tab>', function()
  if vim.fn.pumvisible() == 1 then
    if cursor_is_in_indent() then return '<C-e><Tab>' end
    local selected = vim.fn.complete_info({ 'selected' }).selected
    return selected >= 0 and '<C-y>' or '<C-n><C-y>'
  end
  if vim.snippet.active { direction = 1 } then
    vim.snippet.jump(1)
    return ''
  end
  return '<Tab>'
end, { expr = true, desc = 'Next completion item' })
vim.keymap.set('i', '<S-Tab>', function()
  if vim.fn.pumvisible() == 1 then return '<C-p>' end
  if vim.snippet.active { direction = -1 } then
    vim.snippet.jump(-1)
    return ''
  end
  return '<S-Tab>'
end, { expr = true, desc = 'Previous completion item' })
local function termcodes(keys) return vim.api.nvim_replace_termcodes(keys, true, false, true) end

vim.keymap.set('i', '<CR>', function()
  if vim.fn.pumvisible() == 1 then
    local selected = vim.fn.complete_info({ 'selected' }).selected
    if selected >= 0 then return termcodes '<C-y>' end
    return termcodes '<C-e>' .. (_G.MiniPairs and MiniPairs.cr() or termcodes '<CR>')
  end
  return _G.MiniPairs and MiniPairs.cr() or termcodes '<CR>'
end, {
  expr = true,
  replace_keycodes = false,
  desc = 'Confirm completion or expand pair',
})
-- }}}

-- mini.pairs {{{
-- ---------------------------------------------------------
-- The completion <CR> mapping delegates to MiniPairs.cr() when no suggestion
-- is selected, preserving IDE-style newline expansion inside empty pairs.
do
  local ok_pairs, mini_pairs = pcall(require, 'mini.pairs')
  if ok_pairs then mini_pairs.setup() end
end
-- }}}

-- LSP interaction {{{
-- ---------------------------------------------------------
-- Keep session diagnostics visible without persistent history or automatic
-- popup interruptions.
vim.diagnostic.config {
  float = {
    border = 'single',
    source = 'if_many',
  },
  jump = {
    float = true,
  },
  severity_sort = true,
  signs = true,
  underline = true,
  virtual_text = false,
}

local function show_diagnostics_in_quickfix()
  if #vim.diagnostic.get() == 0 then
    vim.notify('No diagnostics are available.', vim.log.levels.INFO)
    return
  end
  vim.diagnostic.setqflist { open = true, title = 'Diagnostics' }
end

vim.keymap.set('n', '<leader>d', vim.diagnostic.open_float, {
  desc = 'Show diagnostics',
})
vim.keymap.set('n', '<leader>qd', show_diagnostics_in_quickfix, {
  desc = 'List diagnostics in quickfix',
})

local lsp_keymap_group = vim.api.nvim_create_augroup('UserLspKeymaps', { clear = true })
local lsp_document_highlight_group =
  vim.api.nvim_create_augroup('UserLspDocumentHighlight', { clear = true })
-- Keep Neovim's built-in LSP maps where available; add only missing workflows.

local function toggle_lsp_display(feature, label, bufnr)
  local enabled = not feature.is_enabled { bufnr = bufnr }
  feature.enable(enabled, { bufnr = bufnr })
  vim.notify(label .. ': ' .. (enabled and 'enabled' or 'disabled'), vim.log.levels.INFO)
end

local function list_workspace_folders()
  local folders = vim.lsp.buf.list_workspace_folders()
  local message = 'No workspace folders.'
  if #folders > 0 then message = table.concat(folders, '\n') end
  vim.notify(message, vim.log.levels.INFO)
end

local function enable_document_highlight(bufnr)
  if vim.b[bufnr].lsp_document_highlight_enabled then return end

  vim.b[bufnr].lsp_document_highlight_enabled = true
  vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
    group = lsp_document_highlight_group,
    buffer = bufnr,
    callback = vim.lsp.buf.document_highlight,
    desc = 'Highlight references at the cursor',
  })
  vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI', 'BufLeave' }, {
    group = lsp_document_highlight_group,
    buffer = bufnr,
    callback = vim.lsp.buf.clear_references,
    desc = 'Clear LSP reference highlights',
  })
end

vim.api.nvim_create_autocmd('LspAttach', {
  group = lsp_keymap_group,
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if not client then return end

    local bufnr = args.buf
    local function map(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, {
        buffer = bufnr,
        desc = desc,
        silent = true,
      })
    end

    map('n', 'gd', vim.lsp.buf.definition, 'Go to definition')
    map('n', 'gD', vim.lsp.buf.declaration, 'Go to declaration')
    if client:supports_method 'textDocument/prepareTypeHierarchy' then
      map('n', 'grs', function() vim.lsp.buf.typehierarchy 'supertypes' end, 'List supertypes')
      map('n', 'grb', function() vim.lsp.buf.typehierarchy 'subtypes' end, 'List subtypes')
    end
    if client:supports_method 'workspace/symbol' then
      map('n', '<leader>ws', vim.lsp.buf.workspace_symbol, 'Search workspace symbols')
    end
    if client:supports_method 'workspace/diagnostic' then
      map('n', '<leader>qD', vim.lsp.buf.workspace_diagnostics, 'List workspace diagnostics')
    end
    if client:supports_method 'textDocument/prepareCallHierarchy' then
      map('n', '<leader>ci', vim.lsp.buf.incoming_calls, 'List incoming calls')
      map('n', '<leader>co', vim.lsp.buf.outgoing_calls, 'List outgoing calls')
    end

    if client:supports_method 'textDocument/documentHighlight' then
      enable_document_highlight(bufnr)
    end
    if client:supports_method 'textDocument/inlayHint' then
      vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
      map(
        'n',
        '<leader>th',
        function() toggle_lsp_display(vim.lsp.inlay_hint, 'Inlay hints', bufnr) end,
        'Toggle inlay hints'
      )
    end
    if client:supports_method 'textDocument/codeLens' then
      vim.lsp.codelens.enable(true, { bufnr = bufnr })
      map(
        'n',
        '<leader>tl',
        function() toggle_lsp_display(vim.lsp.codelens, 'Code lens', bufnr) end,
        'Toggle code lens'
      )
    end
    if client:supports_method 'textDocument/linkedEditingRange' then
      vim.lsp.linked_editing_range.enable(true, { bufnr = bufnr })
    end
    if client:supports_method 'textDocument/inlineCompletion' then
      vim.lsp.inline_completion.enable(true, { bufnr = bufnr })
      vim.keymap.set('i', '<leader>ic', vim.lsp.inline_completion.get, {
        buffer = bufnr,
        desc = 'Accept inline completion',
      })
    end
    if client:supports_method 'textDocument/semanticTokens/full' then
      vim.lsp.semantic_tokens.enable(true, { bufnr = bufnr })
      map(
        'n',
        '<leader>ts',
        function() toggle_lsp_display(vim.lsp.semantic_tokens, 'Semantic tokens', bufnr) end,
        'Toggle semantic tokens'
      )
    end

    map('n', '<leader>wa', vim.lsp.buf.add_workspace_folder, 'Add workspace folder')
    map('n', '<leader>wr', vim.lsp.buf.remove_workspace_folder, 'Remove workspace folder')
    map('n', '<leader>wl', list_workspace_folders, 'List workspace folders')

    if enable_lsp_completion(client, bufnr) then
      map('i', '<leader><Space>', vim.lsp.completion.get, 'Request language-server completion')
    end
  end,
})
-- }}}

-- Project search {{{
-- ---------------------------------------------------------
-- Keep repository-wide text search in the built-in quickfix workflow. Semantic
-- navigation stays with LSP; this covers exact text, tests, and comments.
vim.opt.grepprg = 'rg --vimgrep --smart-case'
vim.opt.grepformat = '%f:%l:%c:%m'

local project_files_quickfix_context = { kind = 'project_files' }

local function is_project_files_quickfix(context)
  return type(context) == 'table' and context.kind == project_files_quickfix_context.kind
end

local function dotfiles_quickfix_text(info)
  local list = info.quickfix == 1 and vim.fn.getqflist { context = 1, items = 1 }
    or vim.fn.getloclist(info.winid, { context = 1, items = 1 })
  local lines = {}

  for index = info.start_idx, info.end_idx do
    local item = list.items[index]
    local filename = item.filename or ''
    if filename == '' and item.bufnr > 0 then filename = vim.api.nvim_buf_get_name(item.bufnr) end

    if is_project_files_quickfix(list.context) then
      table.insert(lines, vim.fn.fnamemodify(filename, ':.'))
    elseif item.valid == 1 and filename ~= '' then
      table.insert(
        lines,
        string.format('%s|%d col %d| %s', filename, item.lnum, item.col, item.text or '')
      )
    else
      table.insert(lines, item.text or '')
    end
  end

  return lines
end
rawset(_G, 'dotfiles_quickfix_text', dotfiles_quickfix_text)
vim.opt.quickfixtextfunc = 'v:lua.dotfiles_quickfix_text'

local function toggle_quickfix()
  for _, win in ipairs(vim.fn.getwininfo()) do
    if win.quickfix == 1 then
      vim.cmd.cclose()
      return
    end
  end

  if #vim.fn.getqflist() == 0 then
    vim.notify('Quickfix list is empty.', vim.log.levels.INFO)
    return
  end
  vim.cmd.copen()
end

local function search_project_text()
  vim.ui.input({ prompt = 'Search project: ' }, function(query)
    if not query or query == '' then return end

    vim.cmd('silent grep! ' .. vim.fn.shellescape(query))
    if #vim.fn.getqflist() == 0 then
      vim.notify('No project matches: ' .. query, vim.log.levels.INFO)
      return
    end

    vim.cmd.copen()
  end)
end

local function search_project_files()
  vim.ui.input({ prompt = 'Find project file: ' }, function(query)
    if not query or query == '' then return end

    -- Include hidden project metadata but never inspect Git's internal state.
    -- Match paths with the same smart-case rule as text search.
    local files = vim.fn.systemlist { 'rg', '--files', '--hidden', '-g', '!.git' }
    if vim.v.shell_error ~= 0 then
      vim.notify('Could not list project files with ripgrep.', vim.log.levels.ERROR)
      return
    end

    local ignorecase = query == query:lower()
    local needle = ignorecase and query:lower() or query
    local items = {}
    for _, filename in ipairs(files) do
      local candidate = ignorecase and filename:lower() or filename
      if candidate:find(needle, 1, true) then
        table.insert(items, { filename = filename, lnum = 1, col = 1 })
      end
    end

    if #items == 0 then
      vim.notify('No project files match: ' .. query, vim.log.levels.INFO)
      return
    end

    vim.fn.setqflist({}, 'r', {
      context = project_files_quickfix_context,
      items = items,
      title = 'Files: ' .. query,
    })
    vim.cmd.copen()
  end)
end

vim.keymap.set('n', '<leader>sg', search_project_text, {
  desc = 'Search project text',
})
vim.keymap.set('n', '<leader>sf', search_project_files, {
  desc = 'Find project file',
})
vim.keymap.set('n', '<leader>qf', toggle_quickfix, {
  desc = 'Toggle quickfix',
})

local quickfix_keymap_group = vim.api.nvim_create_augroup('quickfix_keymap', { clear = true })
vim.api.nvim_create_autocmd('FileType', {
  group = quickfix_keymap_group,
  pattern = 'qf',
  callback = function(args)
    vim.keymap.set('n', '<CR>', function()
      local list = vim.fn.getqflist { context = 1 }
      if is_project_files_quickfix(list.context) then
        vim.schedule(function() vim.cmd.cclose() end)
      end
      return '<CR>'
    end, {
      buffer = args.buf,
      desc = 'Open quickfix entry',
      expr = true,
      silent = true,
    })
    vim.keymap.set('n', 'q', '<cmd>close<cr>', {
      buffer = args.buf,
      desc = 'Close quickfix',
      silent = true,
    })
  end,
})
-- }}}

-- Git changes {{{
-- ---------------------------------------------------------
-- Keep Git visibility local and quiet: show hunks and expose deliberate
-- actions, but do not show persistent blame text or mutate the index on save.
do
  local ok_gitsigns, gitsigns = pcall(require, 'gitsigns')
  if ok_gitsigns then
    gitsigns.setup {
      current_line_blame = false,
      on_attach = function(bufnr)
        local function map(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, {
            buffer = bufnr,
            desc = desc,
            silent = true,
          })
        end

        map('n', ']c', function()
          if vim.wo.diff then
            vim.cmd.normal { ']c', bang = true }
          else
            gitsigns.nav_hunk 'next'
          end
        end, 'Next Git hunk')
        map('n', '[c', function()
          if vim.wo.diff then
            vim.cmd.normal { '[c', bang = true }
          else
            gitsigns.nav_hunk 'prev'
          end
        end, 'Previous Git hunk')
        map('n', '<leader>hp', gitsigns.preview_hunk, 'Preview Git hunk')
        map('n', '<leader>hb', function() gitsigns.blame_line { full = true } end, 'Show Git blame')
        map('n', '<leader>hs', gitsigns.stage_hunk, 'Stage Git hunk')
        map('n', '<leader>hr', gitsigns.reset_hunk, 'Reset Git hunk')
      end,
    }
  end
end
-- }}}

-- History {{{
-- ---------------------------------------------------------
local state_dir = vim.fn.stdpath 'state'
local history_dir = state_dir .. '/history/'
local sub_dirs = { 'undo', 'backup', 'swap', 'view' }

for _, dir in ipairs(sub_dirs) do
  local path = history_dir .. dir
  if vim.fn.isdirectory(path) == 0 then vim.fn.mkdir(path, 'p', '0700') end
end

vim.opt.shadafile = history_dir .. 'main.shada'
vim.opt.undodir = history_dir .. 'undo'
vim.opt.backupdir = history_dir .. 'backup'
vim.opt.directory = history_dir .. 'swap'
vim.opt.viewdir = history_dir .. 'view'

vim.opt.shada = [[!,'100,<50,s10,h]]
vim.opt.undofile = true
vim.opt.backup = false
vim.opt.writebackup = false
vim.opt.swapfile = false
-- Views restore cursor position only.
vim.opt.viewoptions = {
  'cursor',
}
-- Manual project session: ":mksession! .session.vim", restore with ":source .session.vim" or "nvim -S .session.vim".
vim.opt.sessionoptions = {
  'buffers',
  'curdir',
  'folds',
  'help',
  'tabpages',
  'winsize',
}

local view_group = vim.api.nvim_create_augroup('UserView', { clear = true })
local function should_persist_view(bufnr)
  if vim.bo[bufnr].buftype ~= '' then return false end
  if vim.api.nvim_buf_get_name(bufnr) == '' then return false end

  return true
end

vim.api.nvim_create_autocmd('BufWinLeave', {
  group = view_group,
  pattern = '*',
  callback = function(args)
    if should_persist_view(args.buf) then pcall(vim.cmd.mkview) end
  end,
})

vim.api.nvim_create_autocmd('BufWinEnter', {
  group = view_group,
  pattern = '*',
  callback = function(args)
    if should_persist_view(args.buf) then pcall(vim.cmd.loadview) end
  end,
})
-- }}}

-- ColorScheme {{{
-- ---------------------------------------------------------
vim.opt.background = 'light'
local function remove_all_italics()
  -- This keeps theme choice flexible while preserving a non-italic baseline across colorschemes.
  local highlights = vim.api.nvim_get_hl(0, {})

  for group_name, settings in pairs(highlights) do
    if settings.italic then
      local new_settings = vim.tbl_extend('force', settings, { italic = false })
      vim.api.nvim_set_hl(0, group_name, new_settings)
    end
  end
end

local function apply_flash_highlights()
  vim.api.nvim_set_hl(0, 'FlashBackdrop', { fg = '#aaaaaa' })
  vim.api.nvim_set_hl(0, 'FlashMatch', { fg = '#000000', bg = '#b7c9dc' })
  vim.api.nvim_set_hl(0, 'FlashCurrent', { fg = '#000000', bg = '#ffd400', bold = true })
  vim.api.nvim_set_hl(0, 'FlashLabel', { fg = '#ffffff', bg = '#9f3a30', bold = true })
  vim.api.nvim_set_hl(0, 'FlashPromptIcon', { fg = '#9f3a30', bold = true })
end

-- Intentionally kept as a disabled alternative in case the no-bold preference comes back.
-- local function remove_all_bold()
--   local highlights = vim.api.nvim_get_hl(0, {})
--
--   for group_name, settings in pairs(highlights) do
--     if settings.bold then
--       local new_settings = vim.tbl_extend('force', settings, { bold = false })
--       vim.api.nvim_set_hl(0, group_name, new_settings)
--     end
--   end
-- end

local theme_augroup = vim.api.nvim_create_augroup('ThemeCustomization', { clear = true })
vim.api.nvim_create_autocmd('ColorScheme', {
  group = theme_augroup,
  pattern = '*',
  callback = function()
    apply_flash_highlights()
    remove_all_italics()
    -- remove_all_bold()
  end,
  desc = 'Remove italics globally',
})

local loaded, load_error = pcall(vim.cmd.colorscheme, 'paper-custom')
if not loaded then
  vim.notify(
    'Failed to load paper-custom; using Neovim default.\n' .. tostring(load_error),
    vim.log.levels.WARN
  )
  vim.cmd.colorscheme 'default'
end
-- }}}

-- Statusline {{{
-- ---------------------------------------------------------
local my_config = rawget(_G, 'MyConfig')
if type(my_config) ~= 'table' then my_config = {} end
rawset(_G, 'MyConfig', my_config)
rawset(my_config, 'custom_statusline', function()
  local path = vim.wo.diff and '%<%-20.50F' or '%f'
  return ' ' .. path .. ' %m%r %= %< %l/%L, %3c '
end)
vim.opt.statusline = '%!v:lua.MyConfig.custom_statusline()'
-- }}}

-- key-mapping {{{
-- ---------------------------------------------------------
-- Global keymaps should stay biased toward repeated editing/motion workflows, not feature sprawl.
vim.keymap.set('i', 'jk', '<ESC>')
vim.keymap.set({ 'n', 'v' }, ',', ':')
vim.keymap.set('n', '<S-u>', '<C-r>')
vim.keymap.set('n', 'Q', '<NOP>')

vim.keymap.set('n', 'j', 'gj')
vim.keymap.set('n', 'k', 'gk')
vim.keymap.set('n', '0', 'g0')
vim.keymap.set('n', '^', 'g^')
vim.keymap.set('n', '$', 'g$')

vim.keymap.set('v', '<', '<gv')
vim.keymap.set('v', '>', '>gv')

vim.keymap.set('n', 'n', 'nzz')
vim.keymap.set('n', 'N', 'Nzz')
vim.keymap.set('n', '*', '*zz')
vim.keymap.set('n', '#', '#zz')

-- Intentionally keep this commented mapping for future rollback/reference.
-- vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>', { silent = true })
vim.keymap.set('n', '<leader>v', '<C-v>')
vim.keymap.set('i', '{<CR>', '{<CR>}<Esc>O')
vim.keymap.set('n', '<leader>bb', '<C-o>', { desc = 'Jump Back' })
vim.keymap.set('n', '<leader>gg', '<C-i>', { desc = 'Jump Forward' })
vim.keymap.set('n', '<leader>ss', '<C-^>', { desc = 'Switch Alternate Buffer' })

-- Flash owns s/S for jump modes, so exclude them from the black-hole edits.
local blackhole_keys = { 'c', 'C', 'x', 'X' }
for _, key in ipairs(blackhole_keys) do
  vim.keymap.set({ 'n', 'v' }, key, '"_' .. key)
end

-- Visual P replaces the selection without overwriting the unnamed register.
-- Map p to that behavior so repeated paste keeps the copied text stable.
vim.keymap.set('x', 'p', 'P')

vim.keymap.set('n', '[b', '<cmd>bprevious<CR>', { silent = true })
vim.keymap.set('n', ']b', '<cmd>bnext<CR>', { silent = true })
vim.keymap.set('n', '[B', '<cmd>bfirst<CR>', { silent = true })
vim.keymap.set('n', ']B', '<cmd>blast<CR>', { silent = true })
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

-- Etc. {{{
-- Trim trailing whitespace {{{
local function trim_trailing_whitespace()
  local save_view = vim.fn.winsaveview()
  vim.cmd [[silent! keeppatterns %s/\s\+$//e]]
  vim.fn.winrestview(save_view)
end

local whitespace_exclude_filetypes = {
  diff = true,
  gitcommit = true,
  markdown = true,
}

local whitespace_exclude_buftypes = {
  help = true,
  nofile = true,
  prompt = true,
  terminal = true,
}

local function should_trim_whitespace(bufnr)
  local ft = vim.bo[bufnr].filetype
  local bt = vim.bo[bufnr].buftype

  if whitespace_exclude_filetypes[ft] or whitespace_exclude_buftypes[bt] then return false end
  if not vim.bo[bufnr].modifiable or vim.bo[bufnr].readonly then return false end

  return true
end

vim.api.nvim_create_user_command('TrimWhitespace', trim_trailing_whitespace, {
  desc = 'Remove trailing whitespace from the current buffer',
})

local whitespace_group = vim.api.nvim_create_augroup('TrimWhitespaceGroup', { clear = true })
vim.api.nvim_create_autocmd('BufWritePre', {
  group = whitespace_group,
  pattern = '*',
  callback = function(args)
    if should_trim_whitespace(args.buf) then trim_trailing_whitespace() end
  end,
  desc = 'Automatically trim trailing whitespace on save',
})
-- }}}

-- Trim carriage return {{{
local is_wsl = vim.fn.has 'wsl' == 1

local function trim_carriage_return()
  local save_view = vim.fn.winsaveview()
  vim.cmd [[silent! keeppatterns %s/\r//e]]
  vim.fn.winrestview(save_view)
end

vim.api.nvim_create_user_command('TrimCarriageReturn', trim_carriage_return, {
  desc = 'Remove carriage return (\r) characters from the current buffer',
})

if is_wsl then
  local trim_group = vim.api.nvim_create_augroup('WslTrimGroup', { clear = true })
  vim.api.nvim_create_autocmd('BufWritePre', {
    group = trim_group,
    pattern = '*',
    callback = trim_carriage_return,
    desc = 'Automatically trim \r on save in WSL',
  })
end
-- }}}

-- Hangul input source {{{
local input_source_reset_in_flight = false

local function reset_input_source()
  if vim.env.SSH_TTY or vim.env.SSH_CONNECTION then return end
  if not vim.env.DISPLAY and not vim.env.WAYLAND_DISPLAY then return end
  if vim.fn.executable 'fcitx5-remote' ~= 1 then return end
  if input_source_reset_in_flight then return end

  -- Fcitx owns the session-wide input state under Sway. Deactivation is
  -- asynchronous so leaving insert mode never waits for desktop IPC.
  input_source_reset_in_flight = true
  local ok = pcall(vim.system, { 'fcitx5-remote', '-c' }, { text = true }, function()
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

vim.api.nvim_create_autocmd('InsertLeave', {
  callback = reset_input_source,
  desc = 'Reset Hangul input source after insert mode editing',
})
-- }}}

-- Copy File References {{{
-- These copy helpers are mainly for passing precise file/line references to CLI AI coding tools.
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
    noremap = true,
    silent = true,
    desc = opts.desc,
  })
end
-- }}}

-- Problem-solving runner {{{
-- Keep this intentionally limited to one source file. Project builds and
-- dependency graphs remain project-owned.
local problem_input_default_enabled = true
-- Add languages as templates. {source} and {executable} are shell-escaped
-- when commands are built.
local problem_languages = {
  c = {
    name = 'C',
    extensions = { 'c' },
    compile = {
      'cc',
      '-std=c17',
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
    extensions = { 'cc', 'cpp', 'cxx' },
    compile = {
      'c++',
      -- Use C++17 for broadly compatible standalone solutions.
      '-std=c++17',
      '-Wall',
      '-Wextra',
      '-Wpedantic',
      '-O2',
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
    -- Source-file mode leaves no class artifacts beside the source file.
    run = { 'java', '{source}' },
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
  local values = { source = source_path }
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

local problem_runner_window

local function open_problem_runner_output()
  local current_tabpage = vim.api.nvim_get_current_tabpage()
  local reuse_output = problem_runner_window
    and vim.api.nvim_win_is_valid(problem_runner_window)
    and vim.api.nvim_win_get_tabpage(problem_runner_window) == current_tabpage

  if reuse_output then
    vim.api.nvim_set_current_win(problem_runner_window)
    vim.cmd 'resize 14'
    local output_buffer = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_win_set_buf(problem_runner_window, output_buffer)
  else
    vim.cmd 'botright 14new'
    problem_runner_window = vim.api.nvim_get_current_win()
    local output_buffer = vim.api.nvim_get_current_buf()
    vim.bo[output_buffer].buflisted = false
  end

  -- A scratch buffer avoids inheriting the source filetype after a split.
  local output_buffer = vim.api.nvim_get_current_buf()
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

-- }}}

-- Workflow reference {{{
-- ---------------------------------------------------------
-- Leader: \
--
-- Navigation model
--   Unknown nearby structure    Oil
--   Current working set         alternate buffer and buffer list
--   Visible text target         Flash jump and search labels
--   Code meaning                LSP definition, reference, and hover actions
--   Exact project text          <leader>sg quickfix search
--
-- Editing and navigation
--   jk                    i       Leave insert mode
--   ,                     n, v    Enter command-line mode
--   <S-u>                 n       Redo
--   Q                     n       Disabled
--   j / k                 n       Move by display line
--   0 / ^ / $             n       Move within the display line
--   < / >                 v       Indent and keep the selection
--   n / N / * / #         n       Search and center the match
--   s                     n, x, o Jump to a visible target with Flash
--   S                     n, x, o Jump by syntax tree with Flash
--   r                     o       Apply an operator at a remote Flash target
--   R                     x, o    Search syntax-tree targets with Flash
--   /, ?                  n, x, o Search with Flash labels
--   <C-s>                 c       Toggle Flash labels for the active search
--   <leader>v             n       Enter blockwise visual mode
--   {<CR>                 i       Insert a closing brace on a new line
--   c / C / x / X         n, v    Edit through the black-hole register
--   p                     x       Replace without changing the unnamed register
--   y                     n, x    Copy text
--   <leader>a             n       Select the entire buffer
--   <Esc>                 n       Clear search highlighting and reset Hangul input
--   <Esc>                 v       Leave visual mode and reset Hangul input
--
-- Jumps, buffers, tabs, and windows
--   <leader>bb / gg       n       Jump backward / forward
--   <leader>ss            n       Switch to the alternate buffer
--   [b / ]b               n       Previous / next buffer
--   [B / ]B               n       First / last buffer
--   [t / ]t               n       Previous / next tab
--   <leader>w             n       Enter the window command prefix
--   <leader>1..4          n       Move to the left / down / up / right window
--   <leader>5..8          n       Shrink width / height, grow height / width
--   <leader>qq            n       Quit all windows
--
-- Completion
--   <leader>cp            n       Toggle automatic completion popup
--   <leader><Space>       i       Request LSP completion explicitly
--   <Up> / <Down>         i       Select the previous / next completion item
--   <Tab> / <S-Tab>       i       Confirm completion or move snippet stops
--                                <Tab> indents leading whitespace instead
--   <CR>                  i       Confirm the selected item or expand an empty pair

-- Configured navigation
--   gd / gD                n       Go to definition / declaration
--
-- Neovim LSP defaults
--   gra                    n, x    Code action
--   gri / grt              n       Go to implementation / type definition
--   grn / grr              n       Rename symbol / list references
--   grx                    n       Run the code lens at the cursor
--   gO                     n       List symbols in the current file
--   K                      n       Show symbol information
--   <C-s>                  i       Show signature help
--   an / in                x       Expand / shrink LSP selection without Treesitter
--   gx                     n       Open a document link at the cursor
--   gq                     n, x    Format through the attached language server
--
-- Additional LSP workflows
--   grs / grb              n       List supertypes / subtypes
--   <leader>ic             i       Accept inline completion when available
--   <leader>ws             n       Search workspace symbols
--   <leader>wa / wr / wl   n       Add / remove / list workspace folders
--   <leader>ci / <leader>co n     List incoming / outgoing calls
--   <leader>d              n       Show diagnostics at the cursor
--   [d / ]d                n       Previous / next diagnostic with popup
--   [D / ]D                n       First / last diagnostic with popup
--   <leader>qd             n       List known diagnostics in quickfix
--   <leader>qD             n       List workspace diagnostics
--   <leader>th / tl / ts   n       Toggle inlay hints / code lenses / semantic tokens
--   Reference highlights, inlay hints, code lenses, linked and inline editing,
--   semantic tokens, and document colors activate when the server supports them.

-- Project search
--   <leader>sg             n       Search project text with ripgrep and open quickfix
--   <leader>sf             n       Find a project file by smart-case partial path and open quickfix
--   <CR>                   qf      Open a project-file result and close quickfix
--   <leader>qf             n       Toggle the current quickfix list
--   q                      qf      Close the quickfix window

-- Git changes
--   [c / ]c                n       Previous / next changed hunk
--   <leader>hp             n       Preview the current hunk
--   <leader>hb             n       Show full blame for the current line
--   <leader>hs / <leader>hr n     Stage / reset the current hunk
--
-- Files
--   Oil is for nearby structure and explicit file operations, not primary
--   project navigation. Edit directory entries and write the buffer to apply
--   changes; deletions use the desktop trash.
--   -                     n       Open the parent directory in Oil
--   q                     oil     Close Oil
--   <leader>-             n       Toggle floating Oil
--   <leader>ef / ec       n       Toggle Oil at cwd / current file directory
--
-- Single-file problem solving
--   The runner saves the source first and uses <source-name>.in beside it as
--   standard input when present. It otherwise runs without redirected input.
--   Compiled sources overwrite <source-name>.out beside the source. C uses
--   a -g -O0 build for lldb.
--   Results replace the prior problem-runner terminal in the current tab.
--   <leader>er             n       Compile/run the current source in a terminal split
--   <leader>ei             n       Open <source-name>.in in a lower split
--   <leader>et             n       Toggle input-file redirection for the current source
--   :ProblemRun                     Run the current single-file source
--   :ProblemInputToggle             Toggle input-file redirection for the current source
--
-- Copy file references
--   <leader>or / oe       n, x    Copy relative reference with lines / path only
--   <leader>of / od       n, x    Copy absolute reference with lines / path only
--
-- Commands and maintenance
--   :TrimWhitespace               Remove trailing whitespace from the buffer
--   :TrimCarriageReturn           Remove carriage-return characters from the buffer
--   :lua vim.pack.update()        Update managed plugins
--   :checkhealth                  Check Neovim, Oil, and enabled LSP clients
--   :mksession! .session.vim      Save an explicit project session
--   nvim -S .session.vim          Restore an explicit project session from the shell
-- }}}
