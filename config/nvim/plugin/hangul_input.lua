local input_source_reset_in_flight = false
local hangul_input_group = vim.api.nvim_create_augroup('hangul_input', { clear = true })

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

vim.keymap.set('v', '<Esc>', function()
  reset_input_source()
  return '<Esc>'
end, { expr = true, silent = true, desc = 'Reset input source and escape' })

vim.keymap.set('i', 'ㅓㅏ', '<Esc>', { desc = 'Escape insert mode with Hangul input' })

vim.api.nvim_create_autocmd('InsertLeave', {
  group = hangul_input_group,
  callback = reset_input_source,
  desc = 'Reset Hangul input source after insert mode editing',
})
