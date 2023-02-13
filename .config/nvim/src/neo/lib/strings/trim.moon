---Removes leading and trailing whitespace or specified characters from string.
---@param str string @The string to trim.
---@return string result Returns the trimmed string.
trim = (str = ' ') ->
  return '' if str == nil
  str = string.gsub(str, "^%s*(.-)%s*$", "%1")

return trim
