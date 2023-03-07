is_headless = ()-> #vim.api.nvim_list_uis! == 0

return is_headless
