-- [h / ]h            Previous / next hunk
-- <leader>gs         Stage hunk or visual selection
-- <leader>gr         Reset hunk or visual selection
-- <leader>gS         Stage buffer
-- <leader>gp         Preview hunk
-- <leader>gb         Blame current line
-- <leader>gB         Toggle current-line blame
-- <leader>gd         Diff current file
-- ih                 Select hunk (operator-pending and Visual mode)
-- :Gitsigns toggle_signs
-- :Gitsigns toggle_current_line_blame
-- :Gitsigns toggle_word_diff
-- :Gitsigns detach / :Gitsigns attach

local ok, err = pcall(function()
  local gitsigns = require 'gitsigns'

  gitsigns.setup {
    current_line_blame = false,
    on_attach = function(bufnr)
      local function map(mode, lhs, rhs, desc)
        vim.keymap.set(mode, lhs, rhs, {
          buffer = bufnr,
          silent = true,
          desc = desc,
        })
      end

      map('n', '[h', function() gitsigns.nav_hunk 'prev' end, 'Previous Git hunk')
      map('n', ']h', function() gitsigns.nav_hunk 'next' end, 'Next Git hunk')

      map('n', '<leader>gs', gitsigns.stage_hunk, 'Git stage hunk')
      map(
        'x',
        '<leader>gs',
        function() gitsigns.stage_hunk { vim.fn.line '.', vim.fn.line 'v' } end,
        'Git stage selected hunk'
      )
      map('n', '<leader>gr', gitsigns.reset_hunk, 'Git reset hunk')
      map(
        'x',
        '<leader>gr',
        function() gitsigns.reset_hunk { vim.fn.line '.', vim.fn.line 'v' } end,
        'Git reset selected hunk'
      )
      map('n', '<leader>gS', gitsigns.stage_buffer, 'Git stage buffer')
      map('n', '<leader>gp', gitsigns.preview_hunk, 'Git preview hunk')
      map('n', '<leader>gb', function() gitsigns.blame_line { full = true } end, 'Git blame line')
      map('n', '<leader>gB', gitsigns.toggle_current_line_blame, 'Toggle Git line blame')
      map('n', '<leader>gd', gitsigns.diffthis, 'Git diff current file')
      map({ 'o', 'x' }, 'ih', gitsigns.select_hunk, 'Git hunk')
    end,
  }
end)

if not ok then
  vim.notify_once(('Failed to configure Gitsigns:\n%s'):format(err), vim.log.levels.WARN)
end
