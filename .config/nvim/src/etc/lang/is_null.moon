is_nil = require 'etc/lang/is_nil'
is_empty = require 'etc/lang/is_empty'

-- lodash inspired library for lua
-- https://git.io/JobW8
---@param value any
---@return boolean result true if value is nil, else false.
is_null = (value) ->
  is_nil(value) or is_empty(value)

return is_null
