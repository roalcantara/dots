local is_type = require('neo/lib/lang/is_type')
local is_list
is_list = function(value)
  return is_type('list', value)
end
return is_list
