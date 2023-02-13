local to_args = require('neo/lib/lang/to_args')
local to_table = require('neo/lib/lang/to_table')
local to_func
to_func = function(...)
  return to_args(to_table(...))
end
return to_func
