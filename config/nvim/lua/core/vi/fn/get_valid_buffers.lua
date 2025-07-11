--- Get valid buffers
--- @param ft_autoclose string[]
--- @return table[] valid_buffers
return function(ft_autoclose)
  return vim.tbl_filter(function(buf)
    if not vim.api.nvim_buf_is_loaded(buf) then return false end

    local filetype = vim.api.nvim_get_option_value("filetype", { buf = buf })
    local buftype = vim.api.nvim_get_option_value("buftype", { buf = buf })
    local listed = vim.api.nvim_get_option_value("buflisted", { buf = buf })

    return listed
      and buftype == ""
      and not vim.tbl_contains(ft_autoclose, filetype)
  end, vim.api.nvim_list_bufs())
end
