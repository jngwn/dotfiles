local ok, err = pcall(function()
  local indentscope = require 'mini.indentscope'

  indentscope.setup {
    draw = {
      delay = 0,
      animation = indentscope.gen_animation.none(),
      predicate = function(scope)
        return vim.bo.buftype == '' and vim.bo.filetype ~= 'oil' and not scope.body.is_incomplete
      end,
    },
    mappings = {
      object_scope = '',
      object_scope_with_border = '',
      goto_top = '',
      goto_bottom = '',
    },
    options = {
      border = 'both',
      indent_at_cursor = true,
      -- Use the body scope while the cursor is on an opening or closing line.
      try_as_border = true,
    },
    symbol = '┃',
  }
end)

if not ok then
  vim.notify_once(('Failed to configure mini.indentscope:\n%s'):format(err), vim.log.levels.WARN)
end
