to_args = require('etc/lang/to_args')
to_table = require('etc/lang/to_table')

---Convert to function
---@vararg any
---@return function result
to_func = (...) -> to_args(to_table(...))

return to_func
