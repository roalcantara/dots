--- Trim a string
---@param value string The string to trim
---@return string The trimmed string
return function(value)
  if not value or type(value) == "nil" then
    return ""
  end
  return string.match(value, '^()%s*$') and '' or string.match(value, '^%s*(.*%S)')
end
