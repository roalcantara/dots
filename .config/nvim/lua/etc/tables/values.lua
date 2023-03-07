local values
values = function(...)
  local params
  if require('etc/lang/is_table')(...) then
    params = ...
  else
    params = require('etc/lang/to_table')(...)
  end
  local t = { }
  for _index_0 = 1, #params do
    local slug = params[_index_0]
    t[#t + 1] = slug
  end
  return t
end
return values
