--- Checks weather a given value matches the given pattern.
---@param value string
---@param pattern any
---@return boolean
matches = (value, pattern) ->
  string.match(value, pattern)

return matches
