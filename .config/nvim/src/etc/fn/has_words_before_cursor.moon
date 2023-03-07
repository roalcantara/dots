---Check if there are words before the cursor
---@return boolean result true if there are words before the cursor, false otherwise
has_words_before_cursor = ()->
  -- if vim.api.nvim_buf_get_option(0, 'buftype') == 'prompt' then return false end
  line, col = unpack(vim.api.nvim_win_get_cursor(0))
  lines = vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]
  col ~= 0 and lines\sub(col, col)\match('%s') == nil

return has_words_before_cursor
