local trim
trim = function(str)
  if str == nil then
    str = ' '
  end
  if str == nil then
    return ''
  end
  str = string.gsub(str, "^%s*(.-)%s*$", "%1")
end
return trim
