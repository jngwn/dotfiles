vim.g.mapleader = '\\'

local init_group = vim.api.nvim_create_augroup('core_init', { clear = true })

-- Clipboard {{{
local use_terminal_clipboard = vim.fn.has 'wsl' == 1
  or vim.env.SSH_TTY ~= nil
  or vim.env.SSH_CONNECTION ~= nil
if use_terminal_clipboard then
  -- OSC 52 reads are not portable, so keep ordinary paste editor-local.
  local copy_to_terminal = require('vim.ui.clipboard.osc52').copy '+'
  vim.api.nvim_create_autocmd('TextYankPost', {
    group = init_group,
    callback = function()
      if vim.v.event.operator == 'y' and vim.v.event.regname == '' then
        copy_to_terminal(vim.v.event.regcontents)
      end
    end,
    desc = 'Copy unnamed yanks through OSC 52',
  })
else
  vim.opt.clipboard = 'unnamedplus'
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
  group = init_group,
  callback = function()
    if vim.fn.getcmdwintype() == '' then vim.cmd.checktime() end
  end,
  desc = 'Detect files changed by external tools',
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
vim.keymap.set('i', 'jk', '<ESC>', { desc = 'Exit insert mode' })
vim.keymap.set({ 'n', 'v' }, ',', ':', { desc = 'Enter command-line mode' })
vim.keymap.set('n', '<S-u>', '<C-r>', { desc = 'Redo' })
vim.keymap.set('n', 'Q', '<NOP>', { desc = 'Disable Q' })
vim.keymap.set('n', 'gQ', '<NOP>', { desc = 'Disable Ex mode' })

vim.keymap.set('n', 'j', 'gj', { desc = 'Move down by display line' })
vim.keymap.set('n', 'k', 'gk', { desc = 'Move up by display line' })
vim.keymap.set('n', '0', 'g0', { desc = 'Move to display line start' })
vim.keymap.set('n', '^', 'g^', { desc = 'Move to first display line character' })
vim.keymap.set('n', '$', 'g$', { desc = 'Move to display line end' })

vim.keymap.set('v', '<', '<gv', { desc = 'Indent left and keep selection' })
vim.keymap.set('v', '>', '>gv', { desc = 'Indent right and keep selection' })

vim.keymap.set('n', '<leader>v', '<C-v>', { desc = 'Enter blockwise visual mode' })
vim.keymap.set('i', '{<CR>', '{<CR>}<Esc>O', { desc = 'Expand braces' })
vim.keymap.set('i', '{;<CR>', '{<CR>};<Esc>O', { desc = 'Expand braces with trailing semicolon' })
vim.keymap.set('n', '<leader>bb', '<C-o>', { desc = 'Jump Back' })
vim.keymap.set('n', '<leader>gg', '<C-i>', { desc = 'Jump Forward' })
vim.keymap.set('n', '<leader>ss', '<C-^>', { desc = 'Switch Alternate Buffer' })

local blackhole_keys = { 'c', 'C', 's', 'S', 'x', 'X' }
for _, key in ipairs(blackhole_keys) do
  vim.keymap.set({ 'n', 'v' }, key, '"_' .. key, {
    desc = 'Use black-hole register for ' .. key,
  })
end

-- Visual P replaces the selection without overwriting the unnamed register.
-- Map p to that behavior so repeated paste keeps the copied text stable.
vim.keymap.set('x', 'p', 'P', { desc = 'Paste without replacing register' })

vim.keymap.set('n', '[b', '<cmd>bprevious<CR>', { silent = true, desc = 'Previous buffer' })
vim.keymap.set('n', ']b', '<cmd>bnext<CR>', { silent = true, desc = 'Next buffer' })
vim.keymap.set('n', '[t', '<cmd>tabprevious<CR>', { silent = true, desc = 'Previous tab' })
vim.keymap.set('n', ']t', '<cmd>tabnext<CR>', { silent = true, desc = 'Next tab' })

vim.keymap.set('n', '<leader>w', '<C-w>', { desc = 'Window command prefix' })
vim.keymap.set('n', '<leader>1', '<C-w>h', { desc = 'Focus left window' })
vim.keymap.set('n', '<leader>2', '<C-w>j', { desc = 'Focus lower window' })
vim.keymap.set('n', '<leader>3', '<C-w>k', { desc = 'Focus upper window' })
vim.keymap.set('n', '<leader>4', '<C-w>l', { desc = 'Focus right window' })
vim.keymap.set('n', '<leader>5', '<cmd>vertical resize -10<CR>', {
  silent = true,
  desc = 'Narrow window',
})
vim.keymap.set('n', '<leader>6', '<cmd>resize -10<CR>', {
  silent = true,
  desc = 'Shorten window',
})
vim.keymap.set('n', '<leader>7', '<cmd>resize +10<CR>', {
  silent = true,
  desc = 'Heighten window',
})
vim.keymap.set('n', '<leader>8', '<cmd>vertical resize +10<CR>', {
  silent = true,
  desc = 'Widen window',
})

vim.keymap.set('n', '<leader>qq', '<cmd>qa<CR>', { silent = true, desc = 'Quit all' })
vim.keymap.set('n', '<leader>a', 'ggVG', { desc = 'Select entire buffer' })
vim.keymap.set('n', '<Esc>', function() vim.cmd.nohlsearch() end, {
  silent = true,
  desc = 'Clear search highlight',
})
-- }}}
