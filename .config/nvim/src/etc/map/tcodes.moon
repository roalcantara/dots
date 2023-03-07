---Replace term codes
---@param key string
---@param from_part boolean
---@param do_lt boolean
---@param special boolean
---@return table
tcodes = (key, from_part, do_lt, special)->
  vim.api.nvim_replace_termcodes(key, from_part, do_lt, special)

return tcodes
