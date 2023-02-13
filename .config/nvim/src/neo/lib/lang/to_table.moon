is_table = require('neo/lib/lang/is_table')
compact = require('neo/lib/tables/compact')

---Convert to table
---@vararg any
---@return table result a table
to_table = (...) ->
  params = if is_table(...) then ... else to_table(...)
  compact(params)

return to_table
