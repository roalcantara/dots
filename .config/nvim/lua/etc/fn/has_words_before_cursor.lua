local has_words_before_cursor
has_words_before_cursor = function()
  local line, col = unpack(vim.api.nvim_win_get_cursor(0))
  local lines = vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]
  return col ~= 0 and lines:sub(col, col):match('%s') == nil
end
return has_words_before_cursor
