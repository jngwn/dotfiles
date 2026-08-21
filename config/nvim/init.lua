-- ~/.config/nvim/init.lua
-- Personal Neovim configuration.
-- This config prioritizes simplicity, core Neovim APIs, and long-term maintainability.
-- Plugins are used only when they provide clear, irreplaceable value.
-- Keep this file as the single source of truth for Neovim; do not split into modules unless the workflow grows enough to justify it.
-- Preserve the existing {{{ / }}} fold structure.
-- Prefer minimal, explicit changes over broad refactors.
-- Keymaps and workflows are intentionally opinionated.
-- Do not add or configure Treesitter; prefer Neovim's default syntax and LSP features unless explicitly requested.
-- ---------------------------------------------------------
vim.g.mapleader = '\\'
vim.g.maplocalleader = '\\'
if vim.env.SSH_TTY or vim.env.SSH_CONNECTION then vim.g.clipboard = 'osc52' end
vim.opt.termguicolors = true

-- Feature defaults
local completion_popup_enabled = true
local lsp_completion_typing_enabled = true
local format_on_save_enabled = true

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
-- ~/.local/share/nvim/site/pack/core/opt/
-- Keep the plugin list small; prefer built-in features for routine workflows.
-- Debugging stays terminal/IDE-first; do not add nvim-dap without a repeated Neovim debugging workflow.
-- If plugin entries are deliberately commented out, keep them; they document considered options.
local plugins = {
  { src = 'https://github.com/neovim/nvim-lspconfig' },
  { src = 'https://github.com/stevearc/oil.nvim' },
}
-- }}}

vim.pack.add(plugins)
-- Neovim 0.12+ builtin package manager }}}

-- LSP core {{{
-- ---------------------------------------------------------
vim.lsp.log.set_level 'off'
-- Keep logs off by default; this config treats LSP debugging as an explicit manual action.

local servers = {
  'clangd',
  'lua_ls',
  'ruff',
  'ty',
}

vim.lsp.config('lua_ls', {
  settings = {
    Lua = {
      runtime = { version = 'LuaJIT' },
      diagnostics = { globals = { 'vim' } },
      workspace = {
        library = {
          vim.env.VIMRUNTIME,
        },
        checkThirdParty = false,
      },
      format = { enable = false },
      telemetry = { enable = false },
    },
  },
})

vim.lsp.config('clangd', {
  cmd = {
    'clangd',
    '--background-index',
    '--header-insertion=never',
  },
})

vim.lsp.config('ruff', {
  on_attach = function(client)
    -- ty owns semantic Python hover; Ruff remains responsible for linting,
    -- code actions, import organization, and formatting.
    client.server_capabilities.hoverProvider = false
  end,
})

vim.lsp.enable(servers)
-- }}}

-- LSP completion {{{
-- ---------------------------------------------------------
local function buffer_autocomplete_enabled(bufnr)
  local enabled = false
  vim.api.nvim_buf_call(bufnr, function() enabled = vim.opt_local.autocomplete:get() end)
  return enabled
end

local function enable_lsp_completion(client, bufnr)
  if not client:supports_method 'textDocument/completion' then return end

  -- Built-in completion connects LSP candidates to Nvim's native popup menu.
  -- Keep it deliberately smaller than nvim-cmp/blink.cmp: LSP handles semantic
  -- candidates, while 'complete' below still provides lightweight keyword fallback.
  vim.lsp.completion.enable(completion_popup_enabled, client.id, bufnr, {
    autotrigger = completion_popup_enabled and buffer_autocomplete_enabled(bufnr),
  })
end

local function toggle_completion_popup()
  completion_popup_enabled = not completion_popup_enabled
  vim.opt.autocomplete = completion_popup_enabled

  -- Existing LSP clients keep their completion provider, but changing the
  -- autotrigger setting makes the popup toggle apply immediately to buffers
  -- that were already attached before this command was invoked.
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) then
      vim.api.nvim_buf_call(
        bufnr,
        function() vim.opt_local.autocomplete = completion_popup_enabled end
      )
      for _, client in ipairs(vim.lsp.get_clients { bufnr = bufnr }) do
        enable_lsp_completion(client, bufnr)
      end
    end
  end

  local state = completion_popup_enabled and 'enabled' or 'disabled'
  vim.notify('Automatic completion popup: ' .. state, vim.log.levels.INFO)
end

local function trigger_lsp_completion()
  local bufnr = vim.api.nvim_get_current_buf()
  if not completion_popup_enabled then
    -- Keep the popup toggle strict while preserving this explicit, one-shot
    -- request path. Its automatic trigger stays off after this explicit request.
    for _, client in ipairs(vim.lsp.get_clients { bufnr = bufnr }) do
      if client:supports_method 'textDocument/completion' then
        vim.lsp.completion.enable(true, client.id, bufnr, { autotrigger = false })
      end
    end
  end
  vim.lsp.completion.get()
end

local function toggle_lsp_completion_typing()
  lsp_completion_typing_enabled = not lsp_completion_typing_enabled
  local state = lsp_completion_typing_enabled and 'enabled' or 'disabled'
  vim.notify('LSP completion while typing identifiers: ' .. state, vim.log.levels.INFO)
end

local lsp_completion_request_generation = {}
local lsp_completion_typing_group =
  vim.api.nvim_create_augroup('lsp_completion_typing', { clear = true })
vim.api.nvim_create_autocmd('InsertCharPre', {
  group = lsp_completion_typing_group,
  callback = function(args)
    local bufnr = args.buf
    local generation = (lsp_completion_request_generation[bufnr] or 0) + 1
    lsp_completion_request_generation[bufnr] = generation

    if
      not completion_popup_enabled
      or not lsp_completion_typing_enabled
      or not buffer_autocomplete_enabled(args.buf)
    then
      return
    end

    local byte = string.byte(vim.v.char)
    if #vim.v.char ~= 1 or not byte or byte < 32 or byte > 126 then return end
    local is_identifier_character = byte >= 48 and byte <= 57
      or byte >= 65 and byte <= 90
      or byte >= 97 and byte <= 122
      or vim.v.char == '_'
    if not is_identifier_character and vim.v.char ~= '#' then return end

    -- InsertCharPre runs before the character reaches the buffer. Debounce the
    -- ordinary invoked request so servers see the updated document and rapid
    -- typing does not create stale requests or reopen the menu on delimiters.
    vim.defer_fn(function()
      if not completion_popup_enabled or not lsp_completion_typing_enabled then return end
      if lsp_completion_request_generation[bufnr] ~= generation then return end
      if not vim.api.nvim_buf_is_valid(bufnr) or vim.api.nvim_get_current_buf() ~= bufnr then
        return
      end

      local mode = vim.api.nvim_get_mode().mode
      if mode == 'i' or mode == 'ic' then vim.lsp.completion.get() end
    end, vim.o.autocompletedelay)
  end,
})

vim.api.nvim_create_user_command('LspCompletionTypingToggle', toggle_lsp_completion_typing, {
  desc = 'Toggle LSP completion while typing identifiers',
})
vim.api.nvim_create_user_command('CompletionPopupToggle', toggle_completion_popup, {
  desc = 'Toggle automatic native and LSP completion popups',
})
-- }}}

-- LSP attach / mappings {{{
-- ---------------------------------------------------------
-- Treat this as the single entry point for buffer-local LSP UX.
vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if not client then return end

    enable_lsp_completion(client, args.buf)

    local function map(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, {
        buffer = args.buf,
        desc = desc,
      })
    end

    -- Keep builtin 0.12 motions where possible; add only the missing workflow-specific maps here.
    -- NOTE: Uses Neovim built-in LSP keymaps instead of custom mappings
    -- ----------------------------------------------------
    -- References:        grr
    -- Implementation:    gri
    -- Type Definition:   grt
    -- Code Action:       gra
    -- Rename:            grn
    -- Codelens Run:      grx
    -- Document Symbols:  gO
    -- Signature Help:    <C-s> (insert mode)
    map('n', 'gd', vim.lsp.buf.definition, 'Goto Definition')
    map('n', 'gD', vim.lsp.buf.declaration, 'Goto Declaration')
    map('n', 'gai', vim.lsp.buf.incoming_calls, 'Calls Incoming')
    map('n', 'gao', vim.lsp.buf.outgoing_calls, 'Calls Outgoing')
    map('n', '<leader>sS', vim.lsp.buf.workspace_symbol, 'LSP Symbols (Workspace)')

    map('n', 'K', vim.lsp.buf.hover, 'Hover Documentation')

    map(
      'n',
      '<leader>cf',
      function() vim.lsp.buf.format { bufnr = args.buf, async = true } end,
      'Format Code'
    )

    if client:supports_method 'textDocument/inlayHint' then
      map(
        'n',
        '<leader>h',
        function() vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = args.buf }) end,
        'Toggle Inlay Hints'
      )
    end

    if client.name == 'clangd' then
      map('n', '<leader>cs', '<cmd>ClangdSwitchSourceHeader<cr>', 'Switch Source/Header')
    end

    if client:supports_method 'textDocument/documentHighlight' then
      local group =
        vim.api.nvim_create_augroup('lsp_document_highlight_' .. args.buf, { clear = true })

      vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
        group = group,
        buffer = args.buf,
        callback = vim.lsp.buf.document_highlight,
      })

      vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
        group = group,
        buffer = args.buf,
        callback = vim.lsp.buf.clear_references,
      })
    end
  end,
})
-- }}}

-- Format on save {{{
-- ---------------------------------------------------------
local format_on_save_group = vim.api.nvim_create_augroup('format_on_save', { clear = true })
vim.api.nvim_create_autocmd('BufWritePre', {
  group = format_on_save_group,
  callback = function(args)
    if not format_on_save_enabled then return end

    -- Neovim applies willSaveWaitUntil edits as part of the save request.
    if
      #vim.lsp.get_clients {
        bufnr = args.buf,
        method = 'textDocument/willSaveWaitUntil',
      } > 0
    then
      return
    end

    if #vim.lsp.get_clients { bufnr = args.buf, method = 'textDocument/formatting' } == 0 then
      return
    end

    vim.lsp.buf.format {
      bufnr = args.buf,
      async = false,
      timeout_ms = 2000,
    }
  end,
})
-- }}}

-- Diagnostics {{{
-- ---------------------------------------------------------
-- Keep diagnostics quiet during editing and use floats or quickfix when details
-- are needed. Explicit settings prevent Neovim defaults from changing this UX.
vim.diagnostic.config {
  severity_sort = true,
  signs = true,
  underline = true,
  update_in_insert = false,
  virtual_text = false,
  float = {
    border = 'single',
    source = true,
  },
}

vim.keymap.set('n', ']e', function()
  local ok = pcall(vim.diagnostic.jump, {
    count = 1,
    severity = vim.diagnostic.severity.ERROR,
    float = false,
  })
  if ok then vim.api.nvim_feedkeys('zz', 'n', false) end
end, { desc = 'Go to next error diagnostic and center' })

vim.keymap.set('n', '[e', function()
  local ok = pcall(vim.diagnostic.jump, {
    count = -1,
    severity = vim.diagnostic.severity.ERROR,
    float = false,
  })
  if ok then vim.api.nvim_feedkeys('zz', 'n', false) end
end, { desc = 'Go to previous error diagnostic and center' })

vim.keymap.set('n', ']w', function()
  local ok = pcall(vim.diagnostic.jump, {
    count = 1,
    severity = vim.diagnostic.severity.WARN,
    float = false,
  })
  if ok then vim.api.nvim_feedkeys('zz', 'n', false) end
end, { desc = 'Go to next warning diagnostic and center' })

vim.keymap.set('n', '[w', function()
  local ok = pcall(vim.diagnostic.jump, {
    count = -1,
    severity = vim.diagnostic.severity.WARN,
    float = false,
  })
  if ok then vim.api.nvim_feedkeys('zz', 'n', false) end
end, { desc = 'Go to previous warning diagnostic and center' })

vim.keymap.set('n', '<leader>d', vim.diagnostic.open_float, { desc = 'Open diagnostic float' })

vim.keymap.set('n', '<leader>ld', vim.diagnostic.setqflist, {
  desc = 'Populate quickfix list with diagnostics',
})

vim.keymap.set(
  'n',
  '[d',
  function() vim.diagnostic.jump { count = -1, float = true } end,
  { desc = 'Prev Diagnostic' }
)

vim.keymap.set(
  'n',
  ']d',
  function() vim.diagnostic.jump { count = 1, float = true } end,
  { desc = 'Next Diagnostic' }
)
-- }}}

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

-- Native completion defaults also apply without an attached language server.
vim.opt.completeopt = {
  'menuone',
  'noinsert',
  'popup',
}
vim.opt.pumborder = 'none'
vim.opt.pumheight = 12
vim.opt.pummaxwidth = 80
vim.opt.autocomplete = completion_popup_enabled
vim.opt.autocompletedelay = 80

-- Keep native keyword completion available beside LSP completion. The small
-- priority weights make local/current-context words useful without dominating
-- language-server candidates.
vim.opt.complete = {
  '.^5',
  'w^5',
  'b^5',
  'u^5',
}
-- }}}

-- History {{{
-- ---------------------------------------------------------
local state_dir = vim.fn.stdpath 'state' -- ~/.local/state/nvim
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
_G.MyConfig = _G.MyConfig or {}
_G.MyConfig.custom_statusline = function()
  local path = vim.wo.diff and '%<%-20.50F' or '%f'
  return ' ' .. path .. ' %m%r %= %< %l/%L, %3c '
end
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

local blackhole_keys = { 'c', 'C', 'x', 'X', 's', 'S' }
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
vim.keymap.set('n', '[q', '<cmd>cprev<cr>', { silent = true })
vim.keymap.set('n', ']q', '<cmd>cnext<cr>', { silent = true })
vim.keymap.set('n', '[Q', '<cmd>cfirst<cr>', { silent = true })
vim.keymap.set('n', ']Q', '<cmd>clast<cr>', { silent = true })

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

-- Autocomplete
vim.keymap.set('n', '<leader>cp', toggle_completion_popup, {
  desc = 'Toggle automatic completion popup',
})
vim.keymap.set('i', '<leader><Space>', trigger_lsp_completion, { desc = 'Trigger LSP completion' })

vim.keymap.set('i', '<Down>', function()
  if vim.fn.pumvisible() == 1 then return '<C-n>' end
  return '<Down>'
end, { expr = true, desc = 'Select next completion item' })
vim.keymap.set('i', '<Up>', function()
  if vim.fn.pumvisible() == 1 then return '<C-p>' end
  return '<Up>'
end, { expr = true, desc = 'Select previous completion item' })
vim.keymap.set('i', '<Tab>', function()
  if vim.fn.pumvisible() == 1 then
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
vim.keymap.set('i', '<CR>', function()
  if vim.fn.pumvisible() == 1 then
    local selected = vim.fn.complete_info({ 'selected' }).selected
    if selected >= 0 then return '<C-y>' end
  end
  return '<CR>'
end, { expr = true, desc = 'Confirm selected completion item' })
-- }}}

-- Etc. {{{
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

-- Toggle quickfix {{{
-- Quickfix is the shared result UI for diagnostics, grep, and path search.
local function is_quickfix_window_open()
  for _, winid in ipairs(vim.api.nvim_list_wins()) do
    local wininfo = vim.fn.getwininfo(winid)[1]
    if wininfo and wininfo.quickfix == 1 and wininfo.loclist == 0 then return true end
  end

  return false
end

local function quickfix_has_items()
  local ok, qflist = pcall(vim.fn.getqflist, { size = 0 })
  return ok and (qflist.size or 0) > 0
end

local function open_quickfix() vim.cmd 'botright copen 20' end

local function toggle_quickfix()
  if is_quickfix_window_open() then
    local ok, err = pcall(vim.cmd.cclose)
    if not ok then
      vim.notify('Could not close quickfix: ' .. tostring(err), vim.log.levels.ERROR)
    end
    return
  end

  if not quickfix_has_items() then
    vim.notify('Quickfix list is empty.', vim.log.levels.WARN)
    return
  end

  local ok, err = pcall(open_quickfix)
  if not ok then
    vim.notify('Could not open quickfix: ' .. tostring(err), vim.log.levels.ERROR)
    return
  end
end

vim.keymap.set('n', '<leader>co', function()
  local ok, err = pcall(open_quickfix)
  if not ok then vim.notify('Could not open quickfix: ' .. tostring(err), vim.log.levels.ERROR) end
end, { desc = 'Open quickfix list' })

vim.keymap.set('n', '<leader>qf', toggle_quickfix, {
  desc = 'Toggle quickfix list',
})

vim.api.nvim_create_autocmd('FileType', {
  pattern = 'qf',
  callback = function(args)
    vim.keymap.set('n', '<CR>', function()
      local index = vim.fn.line '.'
      vim.cmd('cc ' .. index)
      vim.cmd 'cclose'
    end, {
      buffer = args.buf,
      desc = 'Open quickfix item and close list',
    })
  end,
})
-- }}}

-- Project grep {{{
-- Use CLI search tools directly and parse their output into quickfix entries.
-- Search patterns are tool-native: rg/grep patterns are regular expressions.
local project_search_exclude_dirs = {
  '.git',
  'node_modules',
  'dist',
  'build',
  '.next',
  '.cache',
  '.turbo',
  '.vite',
  'coverage',
  'target',
  '__pycache__',
  '.venv',
  '.mypy_cache',
  '.pytest_cache',
  '.ruff_cache',
}

local active_project_search
local project_search_id = 0

local function run_project_search(args, callback)
  project_search_id = project_search_id + 1
  local search_id = project_search_id

  if active_project_search then
    pcall(active_project_search.kill, active_project_search, 15)
    active_project_search = nil
  end

  local function on_exit(result)
    vim.schedule(function()
      if search_id ~= project_search_id then return end
      active_project_search = nil
      callback(
        result.code,
        vim.split(result.stdout or '', '\n', { plain = true, trimempty = true }),
        result.stderr or ''
      )
    end)
  end

  local ok, process = pcall(vim.system, args, { text = true }, on_exit)
  if not ok then
    vim.notify('Could not start project search: ' .. tostring(process), vim.log.levels.ERROR)
    return
  end

  active_project_search = process
end

local function build_grep_command(query, case_sensitive)
  if vim.fn.executable 'rg' == 1 then
    local args = {
      'rg',
      '--vimgrep',
      '--hidden',
    }
    table.insert(args, case_sensitive and '--case-sensitive' or '--smart-case')

    for _, dir in ipairs(project_search_exclude_dirs) do
      table.insert(args, '--glob')
      table.insert(args, '!' .. dir .. '/**')
    end

    table.insert(args, '--')
    table.insert(args, query)
    table.insert(args, '.')

    return args, 'rg'
  end

  if vim.fn.executable 'grep' == 1 then
    local args = {
      'grep',
      '--recursive',
      '--line-number',
      '--with-filename',
      '--binary-files=without-match',
    }
    if not case_sensitive then table.insert(args, '--ignore-case') end

    for _, dir in ipairs(project_search_exclude_dirs) do
      table.insert(args, '--exclude-dir=' .. dir)
    end

    table.insert(args, '--')
    table.insert(args, query)
    table.insert(args, '.')

    return args, 'grep'
  end

  return nil, nil
end

local function parse_grep_results(lines, tool)
  local items = {}

  for _, line in ipairs(lines) do
    local filename, lnum, col, text

    if tool == 'rg' then
      filename, lnum, col, text = line:match '^(.-):(%d+):(%d+):(.*)$'
    else
      filename, lnum, text = line:match '^(.-):(%d+):(.*)$'
      col = 1
    end

    if filename and lnum and text then
      table.insert(items, {
        filename = filename,
        lnum = tonumber(lnum),
        col = tonumber(col) or 1,
        text = text,
      })
    end
  end

  return items
end

local function project_grep(case_sensitive)
  local query = vim.fn.input(case_sensitive and 'Grep case-sensitive: ' or 'Grep: ')
  if query == '' then return end

  local args, tool = build_grep_command(query, case_sensitive)
  if not args then
    vim.notify('rg or grep is required for project search.', vim.log.levels.ERROR)
    return
  end

  run_project_search(args, function(code, output, stderr)
    if code ~= 0 and code ~= 1 then
      local message = tool .. ' failed with exit code ' .. tostring(code)
      local detail = vim.trim(stderr or '')
      if detail ~= '' then message = message .. ': ' .. detail end
      vim.notify(message, vim.log.levels.ERROR)
      return
    end

    local items = parse_grep_results(output, tool)
    vim.fn.setqflist({}, 'r', {
      title = tool .. (case_sensitive and ' case-sensitive: ' or ': ') .. query,
      items = items,
    })

    if #items == 0 then
      vim.notify('No matches: ' .. query, vim.log.levels.INFO)
      return
    end

    open_quickfix()
    vim.cmd 'normal! gg'
  end)
end

vim.keymap.set('n', '<leader>fg', function() project_grep(false) end, {
  desc = 'Grep project',
})
vim.keymap.set('n', '<leader>fG', function() project_grep(true) end, {
  desc = 'Grep project case-sensitive',
})
-- }}}

-- Project find {{{
-- Path search intentionally includes files and directories so directories can open through Oil.
local function escape_find_name_pattern(text)
  local escaped = text:gsub('\\', '\\\\')
  escaped = escaped:gsub('%*', '\\*')
  escaped = escaped:gsub('%?', '\\?')
  escaped = escaped:gsub('%[', '\\[')
  escaped = escaped:gsub('%]', '\\]')
  return escaped
end

local function build_find_command(query, case_sensitive)
  if vim.fn.executable 'fd' == 1 then
    local args = {
      'fd',
      '--color=never',
      '--hidden',
    }
    table.insert(args, case_sensitive and '--case-sensitive' or '--ignore-case')

    for _, dir in ipairs(project_search_exclude_dirs) do
      table.insert(args, '--exclude')
      table.insert(args, dir)
    end

    table.insert(args, query)
    table.insert(args, '.')

    return args, 'fd'
  end

  if vim.fn.executable 'find' ~= 1 then return nil, nil end

  local args = {
    'find',
    '.',
    '-ignore_readdir_race',
    '-mindepth',
    '1',
  }

  for _, dir in ipairs(project_search_exclude_dirs) do
    table.insert(args, '-path')
    table.insert(args, '*/' .. dir)
    table.insert(args, '-prune')
    table.insert(args, '-o')
  end

  table.insert(args, case_sensitive and '-name' or '-iname')
  -- The fallback keeps prompt input literal without recreating fd's regex and ignore engines.
  table.insert(args, '*' .. escape_find_name_pattern(query) .. '*')
  table.insert(args, '-print')

  return args, 'find'
end

local function parse_find_results(lines)
  local items = {}

  for _, line in ipairs(lines) do
    if line ~= '' then
      local display_path = line:gsub('^%./', '')
      table.insert(items, {
        filename = line,
        lnum = 1,
        col = 1,
        text = display_path,
      })
    end
  end

  return items
end

local function format_find_results(info)
  local qflist = vim.fn.getqflist { id = info.id, items = 1 }
  local lines = {}

  for index = info.start_idx, info.end_idx do
    local item = qflist.items[index]
    table.insert(lines, item and item.text or '')
  end

  return lines
end

local function project_find(case_sensitive)
  local query = vim.fn.input(case_sensitive and 'Find path case-sensitive: ' or 'Find path: ')
  if query == '' then return end

  local args, tool = build_find_command(query, case_sensitive)
  if not args then
    vim.notify('fd or find is required for path search.', vim.log.levels.ERROR)
    return
  end

  run_project_search(args, function(code, output, stderr)
    if code ~= 0 then
      local message = tool .. ' failed with exit code ' .. tostring(code)
      local detail = vim.trim(stderr or '')
      if detail ~= '' then message = message .. ': ' .. detail end
      vim.notify(message, vim.log.levels.ERROR)
      return
    end

    local items = parse_find_results(output)
    vim.fn.setqflist({}, 'r', {
      title = tool .. (case_sensitive and ' case-sensitive: ' or ': ') .. query,
      items = items,
      quickfixtextfunc = format_find_results,
    })

    if #items == 0 then
      vim.notify('No paths found: ' .. query, vim.log.levels.INFO)
      return
    end

    open_quickfix()
    vim.cmd 'normal! gg'
  end)
end

vim.keymap.set('n', '<leader>ff', function() project_find(false) end, {
  desc = 'Find paths',
})
vim.keymap.set('n', '<leader>fF', function() project_find(true) end, {
  desc = 'Find paths case-sensitive',
})
-- }}}

-- Problem-solving runner {{{
-- Keep this intentionally limited to one source file. Project builds, dependency
-- graphs, and debugger sessions belong to each project's own commands instead.
local problem_input_default_enabled = true
-- Add a language by declaring its extensions and command templates here. The
-- runner owns input handling, terminal presentation, and temporary executable
-- cleanup, so a new language does not need another execution branch below.
-- {source} and {executable} are shell-escaped only when the command is built.
local problem_languages = {
  c = {
    name = 'C',
    extensions = { 'c' },
    compile = {
      'gcc',
      '-std=c17',
      '-Wall',
      '-Wextra',
      '-Wpedantic',
      '-O2',
      '{source}',
      '-o',
      '{executable}',
    },
    run = { '{executable}' },
    temporary_executable = true,
  },
  cpp = {
    name = 'C++',
    extensions = { 'cc', 'cpp', 'cxx' },
    compile = {
      'g++',
      '-std=c++20',
      '-Wall',
      '-Wextra',
      '-Wpedantic',
      '-O2',
      '{source}',
      '-o',
      '{executable}',
    },
    run = { '{executable}' },
    temporary_executable = true,
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
    table.insert(command, vim.fn.shellescape((placeholder and values[placeholder]) or argument))
  end
  return table.concat(command, ' ')
end

local function build_problem_command(source_path, language, input_path)
  local values = { source = source_path }

  if language.compile then
    values.executable = vim.fn.tempname()
    local compile_command = render_problem_command(language.compile, values)
    local run_command = render_problem_command(language.run, values)
    local cleanup_command = ''
    if language.temporary_executable then
      cleanup_command = 'trap '
        .. vim.fn.shellescape('rm -f ' .. vim.fn.shellescape(values.executable))
        .. ' EXIT; '
    end
    if input_path then run_command = run_command .. ' < ' .. vim.fn.shellescape(input_path) end
    return cleanup_command .. compile_command .. ' && ' .. run_command
  end

  local run_command = render_problem_command(language.run, values)
  if input_path then run_command = run_command .. ' < ' .. vim.fn.shellescape(input_path) end
  return run_command
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

  -- A scratch buffer avoids inheriting the source filetype after a split. In
  -- particular, clangd must never receive a term:// URI as a C++ document.
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
  vim.fn.termopen({ 'sh', '-c', command }, {
    cwd = vim.fn.fnamemodify(source_path, ':h'),
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
-- }}}

-- Workflow reference {{{
-- ---------------------------------------------------------
-- Leader: \
--
-- Navigation model
--   Known symbol/reference      LSP navigation
--   Known text/content          <leader>fg, then quickfix
--   Known file/directory name   <leader>ff, then quickfix
--   Unknown nearby structure    Oil
--   Current working set         alternate buffer and buffer list
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
--   <leader>v             n       Enter blockwise visual mode
--   {<CR>                 i       Insert a closing brace on a new line
--   c / C / x / X / s / S n, v    Edit through the black-hole register
--   p                     x       Replace without changing the unnamed register
--   <leader>a             n       Select the entire buffer
--   <Esc>                 n       Clear search highlighting and reset Hangul input
--   <Esc>                 v       Leave visual mode and reset Hangul input
--
-- Jumps, buffers, tabs, and windows
--   <leader>bb / gg       n       Jump backward / forward
--   <leader>ss            n       Switch to the alternate buffer
--   :buffers                      List the current working set
--   :b <name><Tab>                Switch to a buffer by partial name
--   [b / ]b               n       Previous / next buffer
--   [B / ]B               n       First / last buffer
--   [t / ]t               n       Previous / next tab
--   <leader>w             n       Enter the window command prefix
--   <leader>1..4          n       Move to the left / down / up / right window
--   <leader>5..8          n       Shrink width / height, grow height / width
--   <leader>qq            n       Quit all windows
--
-- Completion
--   <leader>cp             n       Toggle automatic native and LSP completion popups
--   <leader><Space>       i       Trigger LSP completion
--   <Up> / <Down>         i       Select the previous / next completion item
--   <Tab> / <S-Tab>       i       Confirm completion or move between snippet stops
--   <CR>                  i       Confirm the selected item or insert a newline
--
-- Custom LSP mappings (buffer-local after LspAttach)
--   gd / gD               n       Go to definition / declaration
--   gai / gao             n       Show incoming / outgoing calls
--   K                     n       Show hover documentation
--   <leader>sS            n       Search workspace symbols
--   <leader>cf            n       Format the current buffer
--   <leader>h             n       Toggle inlay hints when supported
--   <leader>cs            n       Switch source/header for clangd
--
-- Neovim built-in LSP mappings
--   gra                   n, v    Show code actions
--   gri / grt             n       Go to implementation / type definition
--   grn / grr             n       Rename symbol / show references
--   grx                   n       Run codelens
--   gO                    n       Show document symbols
--   <C-s>                 i       Show signature help
--   an / in               v       Expand / contract the LSP selection range
--   gx                    n       Open the LSP document link under the cursor
--
-- Diagnostics and quickfix
--   [d / ]d               n       Previous / next diagnostic with details
--   [e / ]e               n       Previous / next error and center it
--   [w / ]w               n       Previous / next warning and center it
--   <leader>d             n       Show diagnostics under the cursor
--   <leader>ld            n       Send diagnostics to quickfix
--   [q / ]q               n       Previous / next quickfix item
--   [Q / ]Q               n       First / last quickfix item
--   <leader>co            n       Open quickfix
--   <leader>qf            n       Toggle quickfix
--   <CR>                  qf      Open the selected item and close quickfix
--
-- Files and project search
--   Project grep and path search use the current working directory. Start Nvim
--   at the project root or use :cd before project-wide searches.
--   Oil is for nearby structure and explicit file operations, not primary
--   project navigation. Edit directory entries and write the buffer to apply
--   changes; deletions use the desktop trash.
--   -                     n       Open the parent directory in Oil
--   q                     oil     Close Oil
--   <leader>-             n       Toggle floating Oil
--   <leader>ef / ec       n       Toggle Oil at cwd / current file directory
--   <leader>fg / fG       n       Grep project with smart case / case sensitivity
--   <leader>ff / fF       n       Find paths ignoring case / case-sensitively
--
-- Single-file problem solving
--   The runner saves the source first and uses <source-name>.in beside it as
--   standard input when present. It otherwise runs without redirected input.
--   Results replace the prior problem-runner terminal in the current tab.
--   <leader>er             n       Compile/run C, C++, Python, or Java in a terminal split
--   <leader>ei             n       Open <source-name>.in in a lower split
--   <leader>et             n       Toggle input-file redirection for the current source
--   These three maps are explicit no-ops for unsupported file extensions.
--   :ProblemRun                     Run the current single-file source
--   :ProblemInputToggle             Toggle input-file redirection for the current source
--
-- Copy file references
--   <leader>or / oe       n, x    Copy relative reference with lines / path only
--   <leader>of / od       n, x    Copy absolute reference with lines / path only
--
-- Commands and maintenance
--   :CompletionPopupToggle         Toggle automatic native and LSP completion popups
--   :LspCompletionTypingToggle    Toggle automatic LSP completion requests
--   :TrimWhitespace               Remove trailing whitespace from the buffer
--   :TrimCarriageReturn           Remove carriage-return characters from the buffer
--   :lua vim.pack.update()        Update managed plugins
--   :checkhealth                  Check Neovim and maintained integrations
--   :mksession! .session.vim      Save an explicit project session
--   nvim -S .session.vim          Restore an explicit project session from the shell
-- }}}
