-- LSP reference {{{
-- <leader> = \
--
-- Navigation
--   gd                 Definition
--   gri                Implementation
--   grr                References
--   grt                Type definition
--   gO                 Document outline
--
-- Actions and help
--   K                  Hover documentation
--   gra                Code action (Normal and Visual)
--   grn                Rename symbol
--   <leader>ls         Signature help
--
-- Diagnostics
--   [d / ]d            Previous / next diagnostic
--   [D / ]D            First / last diagnostic
--   [e / ]e            Previous / next error
--   [w / ]w            Previous / next warning
--   <leader>d          Open and focus diagnostic popup
--
-- Completion (Insert mode)
--   <leader><Space>    Open completion popup
--   Tab / Shift-Tab    Select next / previous item
--   Enter              Confirm selected item
--
-- Feature controls
--   <leader>cp                 Toggle completion popup
--   :LspDiagnostics [state]    Diagnostics
--   :LspFormatOnSave [state]   Format on save
--   `state`: on, off, or toggle
--
-- Server controls
--   :lsp enable [server_name]
--   :lsp disable [server_name]
--   :lsp restart [server_name]
-- }}}

-- Shared LSP behavior {{{
local features = {
  completion = true,
  diagnostics = true,
  format_on_save = true,
}

vim.opt.completeopt = { 'menuone', 'noselect', 'popup' }
vim.opt.pumborder = 'single'
vim.opt.pumblend = 0
vim.opt.winborder = 'single'

vim.diagnostic.config {
  severity_sort = true,
  update_in_insert = false,
  virtual_lines = false,
  virtual_text = false,
}
vim.diagnostic.enable(features.diagnostics)

local lsp_group = vim.api.nvim_create_augroup('builtin_lsp', { clear = true })

local function diagnostic_jump(direction, severity)
  return function()
    if not features.diagnostics then return end

    vim.diagnostic.jump {
      count = direction * vim.v.count1,
      severity = severity,
    }
  end
end

vim.keymap.set('n', '[e', diagnostic_jump(-1, vim.diagnostic.severity.ERROR), {
  desc = 'Previous diagnostic error',
})
vim.keymap.set('n', ']e', diagnostic_jump(1, vim.diagnostic.severity.ERROR), {
  desc = 'Next diagnostic error',
})
vim.keymap.set('n', '[w', diagnostic_jump(-1, vim.diagnostic.severity.WARN), {
  desc = 'Previous diagnostic warning',
})
vim.keymap.set('n', ']w', diagnostic_jump(1, vim.diagnostic.severity.WARN), {
  desc = 'Next diagnostic warning',
})

local function set_completion(enabled)
  features.completion = enabled

  for _, client in ipairs(vim.lsp.get_clients()) do
    for bufnr in pairs(client.attached_buffers) do
      if client:supports_method('textDocument/completion', bufnr) then
        vim.lsp.completion.enable(enabled, client.id, bufnr, { autotrigger = false })
      end
    end
  end
end

local function create_feature_command(name, feature, label, apply)
  vim.api.nvim_create_user_command(name, function(command)
    local requested = command.args
    if requested ~= '' and requested ~= 'on' and requested ~= 'off' and requested ~= 'toggle' then
      vim.notify(name .. ' expects on, off, or toggle.', vim.log.levels.ERROR)
      return
    end

    local enabled = requested == 'on'
      or ((requested == '' or requested == 'toggle') and not features[feature])
    features[feature] = enabled
    apply(enabled)
    vim.notify(('LSP %s %s.'):format(label, enabled and 'enabled' or 'disabled'))
  end, {
    nargs = '?',
    complete = function() return { 'on', 'off', 'toggle' } end,
    desc = 'Enable, disable, or toggle LSP ' .. label,
  })
end

create_feature_command(
  'LspDiagnostics',
  'diagnostics',
  'diagnostics',
  function(enabled) vim.diagnostic.enable(enabled) end
)
create_feature_command('LspFormatOnSave', 'format_on_save', 'format on save', function() end)
vim.keymap.set('n', '<leader>cp', function()
  local enabled = not features.completion
  set_completion(enabled)
  vim.notify(('LSP completion %s.'):format(enabled and 'enabled' or 'disabled'))
end, {
  desc = 'Toggle LSP completion popup',
})

local function set_lsp_keymaps(bufnr)
  vim.keymap.set('n', 'gd', vim.lsp.buf.definition, {
    buffer = bufnr,
    desc = 'LSP definition',
  })
  vim.keymap.set('n', '<leader>ls', vim.lsp.buf.signature_help, {
    buffer = bufnr,
    desc = 'LSP signature help',
  })
end

local function popup_key(popup, fallback)
  return function()
    if vim.fn.pumvisible() == 1 then return popup end
    return fallback
  end
end

vim.api.nvim_create_autocmd('LspAttach', {
  group = lsp_group,
  callback = function(event)
    local client = assert(vim.lsp.get_client_by_id(event.data.client_id))
    set_lsp_keymaps(event.buf)
    if not client:supports_method 'textDocument/completion' then return end

    vim.lsp.completion.enable(features.completion, client.id, event.buf, { autotrigger = false })
    vim.keymap.set('i', '<leader><Space>', function()
      if features.completion then vim.lsp.completion.get() end
    end, {
      buffer = event.buf,
      desc = 'LSP completion',
    })
    vim.keymap.set('i', '<Tab>', popup_key('<C-n>', '<Tab>'), {
      buffer = event.buf,
      desc = 'Select next completion item',
      expr = true,
    })
    vim.keymap.set('i', '<S-Tab>', popup_key('<C-p>', '<S-Tab>'), {
      buffer = event.buf,
      desc = 'Select previous completion item',
      expr = true,
    })
    vim.keymap.set('i', '<CR>', function()
      local completion = vim.fn.complete_info { 'selected' }
      if vim.fn.pumvisible() == 1 and completion.selected >= 0 then return '<C-y>' end
      return '<CR>'
    end, {
      buffer = event.buf,
      desc = 'Confirm selected completion item',
      expr = true,
    })
  end,
  desc = 'Enable manual builtin LSP completion',
})

vim.keymap.set('n', '<leader>d', function()
  if not features.diagnostics then return end

  local _, winid = vim.diagnostic.open_float {
    focusable = true,
    scope = 'cursor',
  }
  if winid and vim.api.nvim_win_is_valid(winid) then vim.api.nvim_set_current_win(winid) end
end, { desc = 'Open and focus diagnostic popup' })
-- }}}

-- Format on save {{{
local format_timeout_ms = 2000
local lsp_formatters = {
  c = 'clangd',
  cpp = 'clangd',
  python = 'ruff',
  rust = 'rust_analyzer',
}

local function format_lua(bufnr)
  if vim.fn.executable 'stylua' ~= 1 then
    vim.notify_once('StyLua is unavailable; Lua format on save is disabled.', vim.log.levels.WARN)
    return
  end

  local path = vim.api.nvim_buf_get_name(bufnr)
  if path == '' then return end

  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local input = table.concat(lines, '\n')
  if vim.bo[bufnr].eol then input = input .. '\n' end

  local result = vim
    .system({ 'stylua', '--stdin-filepath', path, '-' }, {
      stdin = input,
      text = true,
    })
    :wait(format_timeout_ms)
  if result.code == 124 then
    vim.notify(('StyLua timed out after %d ms.'):format(format_timeout_ms), vim.log.levels.ERROR)
    return
  end
  if result.code ~= 0 then
    local detail = vim.trim(result.stderr or '')
    vim.notify('StyLua failed' .. (detail == '' and '.' or ':\n' .. detail), vim.log.levels.ERROR)
    return
  end

  local formatted = vim.split(result.stdout or '', '\n', { plain = true })
  if formatted[#formatted] == '' then table.remove(formatted) end
  if vim.deep_equal(lines, formatted) then return end

  local view = vim.fn.winsaveview()
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, formatted)
  vim.fn.winrestview(view)
end

vim.api.nvim_create_autocmd('BufWritePre', {
  group = lsp_group,
  callback = function(event)
    if not features.format_on_save then return end

    local filetype = vim.bo[event.buf].filetype
    if filetype == 'lua' then
      format_lua(event.buf)
      return
    end

    local client_name = lsp_formatters[filetype]
    if not client_name then return end

    local clients = vim.lsp.get_clients {
      bufnr = event.buf,
      method = 'textDocument/formatting',
      name = client_name,
    }
    if #clients == 0 then return end

    vim.lsp.buf.format {
      async = false,
      bufnr = event.buf,
      name = client_name,
      timeout_ms = format_timeout_ms,
    }
  end,
  desc = 'Format supported source files before writing',
})
-- }}}

vim.lsp.enable { 'lua_ls', 'rust_analyzer', 'ty', 'ruff', 'clangd' }
