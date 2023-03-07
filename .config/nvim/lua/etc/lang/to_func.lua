local to_args = require('etc/lang/to_args')
local to_table = require('etc/lang/to_table')
local to_func
to_func = function(...)
  return to_args(to_table(...))
end
return to_func
