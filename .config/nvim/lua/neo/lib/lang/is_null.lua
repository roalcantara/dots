local is_nil = require('neo/lib/lang/is_nil')
local is_empty = require('neo/lib/lang/is_empty')
local is_null
is_null = function(value)
  return is_nil(value) or is_empty(value)
end
return is_null
