local is_type = require('neo/lib/lang/is_type')
local is_map
is_map = function(value)
  return is_type('map', value)
end
return is_map
