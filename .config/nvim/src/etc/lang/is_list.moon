is_type = require 'etc/lang/is_type'

---Check if value is a list
---@param value any
---@return boolean result true if value is list, otherwise false
is_list = (value) ->
  is_type('list', value)

return is_list
