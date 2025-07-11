--- Highlights trailing whitespace in the current buffer
--- If invoked as a preview callback performs 'inccommand' preview
--- @param opts table Options for the preview
--- @param preview_ns number Preview namespace
--- @param preview_buf number Preview buffer
--- @return number Preview type
--- @see https://github.com/neovim/neovim/blob/master/runtime/lua/vim/lsp/inccommand.lua#L100
local function trim_trailing_whitespaces_preview(opts, preview_ns, preview_buf)
  vim.cmd('hi clear Whitespace')
  local line1 = opts.line1
  local line2 = opts.line2
  local buf = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(buf, line1 - 1, line2, false)
  local preview_buf_line = 0
  for i, line in ipairs(lines) do
    local start_idx, end_idx = string.find(line, '%s+$')
    if start_idx then
      -- Highlight the match
      vim.hl.range(
        buf,
        preview_ns,
        'Substitute',
        { line1 + i - 2, start_idx - 1 },
        { line1 + i - 2, end_idx }
      )
      -- Add lines and set highlights in the preview buffer
      -- if inccommand=split
      if preview_buf then
        local prefix = string.format('|%d| ', line1 + i - 1)
        vim.api.nvim_buf_set_lines(
          preview_buf,
          preview_buf_line,
          preview_buf_line,
          false,
          { prefix .. line }
        )
        vim.hl.range(
          preview_buf,
          preview_ns,
          'Substitute',
          { preview_buf_line, #prefix + start_idx - 1 },
          { preview_buf_line, #prefix + end_idx }
        )
        preview_buf_line = preview_buf_line + 1
      end
    end
  end
  -- Return the value of the preview type
  return 2
end

--- Trims all trailing whitespace in current buffer with incremental command preview
--- Its preview highlights the trailing whitespace in current buffer
--- @param opts table { line1 = number, line2 = number }
local function trim_trailing_whitespaces(opts)
  local line1 = opts.line1
  local line2 = opts.line2
  local buf = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(buf, line1 - 1, line2, false)
  local new_lines = {}
  for i, line in ipairs(lines) do
    new_lines[i] = string.gsub(line, '%s+$', '')
  end
  vim.api.nvim_buf_set_lines(buf, line1 - 1, line2, false, new_lines)
end

-- Create the user command
vim.api.nvim_create_user_command(
  'TrimTrailingWhitespace',
  trim_trailing_whitespaces,
  { nargs = '?', range = '%', addr = 'lines', preview = trim_trailing_whitespaces_preview }
)
