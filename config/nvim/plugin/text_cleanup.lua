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
