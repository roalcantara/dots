is_type = require 'neo/lib/lang/is_type'

---Check if value is a map
---@param value any
---@return boolean result true if value is map, otherwise false
is_map = (value) ->
  is_type('map', value)

return is_map
