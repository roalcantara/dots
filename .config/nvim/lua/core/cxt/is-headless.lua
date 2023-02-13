local is_headless
is_headless = function()
  return #vim.api.nvim_list_uis() == 0
end
return is_headless
