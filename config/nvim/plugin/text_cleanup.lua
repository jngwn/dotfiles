local clean_text_on_save = true

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

local function clean_text()
  trim_carriage_return()
  trim_trailing_whitespace()
end

vim.keymap.set('n', '<leader>ct', clean_text, { desc = 'Clean text whitespace' })

if clean_text_on_save then
  vim.api.nvim_create_autocmd('BufWritePre', {
    callback = clean_text,
    desc = 'Clean text before writing',
  })
end
