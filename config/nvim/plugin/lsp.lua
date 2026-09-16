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
--   :LspCopyDiagnostics
--                      Copy diagnostics on the current line
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
--   :LspFormatOnSave[!] [state]
--                              Format on save (! = current buffer)
--   :LspInlayHints [state]     Inlay hints
--   `state`: on, off, or toggle
--
-- Server controls
--   :lsp enable [server_name]
--   :lsp disable [server_name]
--   :lsp restart [server_name]
--   Lua: lua_ls                       Rust: rust_analyzer
--   Python: ty, ruff                  C/C++: clangd
--   JavaScript/TypeScript: ts_native, biome
--   Web: html, cssls, jsonls, tailwindcss, emmet_language_server
-- }}}

-- Shared LSP behavior {{{
local features = {
  completion = true,
  diagnostics = true,
  format_on_save = true,
  inlay_hints = false,
}

vim.opt.completeopt = { 'menuone', 'noselect', 'popup' }
vim.opt.pumborder = 'single'
vim.opt.pumblend = 0
vim.opt.winborder = 'single'
vim.opt.signcolumn = 'yes'

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
create_feature_command(
  'LspInlayHints',
  'inlay_hints',
  'inlay hints',
  function(enabled) vim.lsp.inlay_hint.enable(enabled) end
)

local function format_on_save_enabled(bufnr)
  local enabled = vim.b[bufnr].lsp_format_on_save
  if enabled == nil then return features.format_on_save end
  return enabled
end

vim.api.nvim_create_user_command('LspFormatOnSave', function(command)
  local requested = command.args
  if requested ~= '' and requested ~= 'on' and requested ~= 'off' and requested ~= 'toggle' then
    vim.notify('LspFormatOnSave expects on, off, or toggle.', vim.log.levels.ERROR)
    return
  end

  local bufnr = vim.api.nvim_get_current_buf()
  local current = command.bang and format_on_save_enabled(bufnr) or features.format_on_save
  local enabled = requested == 'on' or ((requested == '' or requested == 'toggle') and not current)
  local scope
  if command.bang then
    vim.b[bufnr].lsp_format_on_save = enabled
    scope = ' for the current buffer'
  else
    features.format_on_save = enabled
    scope = ''
  end
  vim.notify(('LSP format on save %s%s.'):format(enabled and 'enabled' or 'disabled', scope))
end, {
  bang = true,
  nargs = '?',
  complete = function() return { 'on', 'off', 'toggle' } end,
  desc = 'Enable, disable, or toggle LSP format on save globally or for the current buffer',
})

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
    if client:supports_method('textDocument/inlayHint', event.buf) then
      vim.lsp.inlay_hint.enable(features.inlay_hints, { bufnr = event.buf })
    end
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

vim.api.nvim_create_user_command('LspCopyDiagnostics', function()
  local line = vim.api.nvim_win_get_cursor(0)[1] - 1
  local diagnostics = vim.diagnostic.get(0, { lnum = line })
  if #diagnostics == 0 then
    vim.notify('No diagnostics on the current line.', vim.log.levels.INFO)
    return
  end

  table.sort(diagnostics, function(left, right)
    if left.col == right.col then
      return (left.severity or math.huge) < (right.severity or math.huge)
    end
    return left.col < right.col
  end)
  local messages = vim.tbl_map(function(diagnostic) return diagnostic.message end, diagnostics)
  vim.fn.setreg('+', table.concat(messages, '\n'))
  vim.notify('Copied diagnostics on the current line.', vim.log.levels.INFO)
end, {
  desc = 'Copy diagnostics on the current line to the system clipboard',
})
-- }}}

-- Format on save {{{
local format_timeout_ms = 2000
local lsp_formatters = {
  c = 'clangd',
  cpp = 'clangd',
  python = 'ruff',
  rust = 'rust_analyzer',
}
local biome_filetypes = {
  css = true,
  html = true,
  javascript = true,
  javascriptreact = true,
  json = true,
  jsonc = true,
  typescript = true,
  typescriptreact = true,
}
local biome_config_files = { 'biome.json', 'biome.jsonc' }

local function replace_with_formatted_output(bufnr, tool, command)
  local path = vim.api.nvim_buf_get_name(bufnr)
  if path == '' then return end

  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local input = table.concat(lines, '\n')
  if vim.bo[bufnr].eol then input = input .. '\n' end

  local result = vim.system(command, { stdin = input, text = true }):wait(format_timeout_ms)
  if result.code == 124 then
    vim.notify(('%s timed out after %d ms.'):format(tool, format_timeout_ms), vim.log.levels.ERROR)
    return
  end
  if result.code ~= 0 then
    local detail = vim.trim(result.stderr or '')
    vim.notify(tool .. ' failed' .. (detail == '' and '.' or ':\n' .. detail), vim.log.levels.ERROR)
    return
  end

  local formatted = vim.split(result.stdout or '', '\n', { plain = true })
  if formatted[#formatted] == '' then table.remove(formatted) end
  if vim.deep_equal(lines, formatted) then return end

  local view = vim.fn.winsaveview()
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, formatted)
  vim.fn.winrestview(view)
end

local function format_lua(bufnr)
  if vim.fn.executable 'stylua' ~= 1 then
    vim.notify_once('StyLua is unavailable; Lua format on save is disabled.', vim.log.levels.WARN)
    return
  end

  local path = vim.api.nvim_buf_get_name(bufnr)
  if path == '' then return end
  replace_with_formatted_output(bufnr, 'StyLua', { 'stylua', '--stdin-filepath', path, '-' })
end

local function format_biome(bufnr)
  local path = vim.api.nvim_buf_get_name(bufnr)
  if path == '' then return end

  if vim.fn.executable 'biome' ~= 1 then
    vim.notify_once(
      'Biome is unavailable; frontend format on save is disabled.',
      vim.log.levels.WARN
    )
    return
  end

  local command = { 'biome', 'format', '--stdin-file-path=' .. path }
  local project_config = vim.fs.find(biome_config_files, {
    path = vim.fs.dirname(path),
    upward = true,
    type = 'file',
    limit = 1,
  })[1]
  if not project_config then
    local filetype = vim.bo[bufnr].filetype
    if filetype == 'html' then
      table.insert(command, '--html-formatter-enabled=true')
    elseif filetype == 'css' then
      table.insert(command, '--css-formatter-enabled=true')
      table.insert(command, '--css-parse-tailwind-directives=true')
    end
  end

  replace_with_formatted_output(bufnr, 'Biome', command)
end

vim.api.nvim_create_autocmd('BufWritePre', {
  group = lsp_group,
  callback = function(event)
    if not format_on_save_enabled(event.buf) then return end

    local filetype = vim.bo[event.buf].filetype
    if filetype == 'lua' then
      format_lua(event.buf)
      return
    end
    if biome_filetypes[filetype] then
      format_biome(event.buf)
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

vim.lsp.enable {
  'lua_ls',
  'rust_analyzer',
  'ty',
  'ruff',
  'clangd',
  'ts_native',
  'biome',
  'html',
  'cssls',
  'jsonls',
  'tailwindcss',
  'emmet_language_server',
}
