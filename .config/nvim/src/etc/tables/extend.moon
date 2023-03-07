is_table = require 'etc/lang/is_table'
to_table = require 'etc/lang/to_table'

---Creates a new table concatenating table with any additional table and/or values..
---In case of key/value conflict, the source's value take precedence.
---@param to table The destination table.
---@vararg ... @table The sources to merge.
---@return table result Two or more map-like tables.
---@see vim.tbl_extend
extend = (to, ...) ->
  to = if is_table(to) then to else to_table(to)
  collection = if is_table(...) then ... else to_table(...)
  vim.tbl_extend('force', to, collection)

return extend
