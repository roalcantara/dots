local values
values = function(...)
  local params
  if require('neo/lib/lang/is_table')(...) then
    params = ...
  else
    params = require('neo/lib/lang/to_table')(...)
  end
  local t = { }
  for _index_0 = 1, #params do
    local slug = params[_index_0]
    t[#t + 1] = slug
  end
  return t
end
return values
