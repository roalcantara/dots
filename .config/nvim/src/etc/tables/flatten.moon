is_table = require 'etc/lang/is_table'
to_table = require 'etc/lang/to_table'

---Flatterns a table
---@param array table
---@return table result a new table
flatten = (...) ->
  collection = if is_table(...) then ... else to_table(...)
  vim.tbl_flatten(collection)

return flatten
