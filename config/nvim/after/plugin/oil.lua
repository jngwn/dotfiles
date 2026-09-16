-- oil.nvim {{{
local ok, err = pcall(function()
  local oil = require 'oil'
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
end)

if not ok then
  vim.notify_once(('Failed to configure Oil:\n%s'):format(err), vim.log.levels.WARN)
end
-- }}}
