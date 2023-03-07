local is_nil = require('etc/lang/is_nil')
local is_empty = require('etc/lang/is_empty')
local is_null
is_null = function(value)
  return is_nil(value) or is_empty(value)
end
return is_null
