local matches
matches = function(value, pattern)
  return string.match(value, pattern)
end
return matches
