local is_table = require('etc/lang/is_table')
local to_table = require('etc/lang/to_table')
local merge
merge = function(tb, ...)
  local t = { }
  if not (is_table(tb)) then
    tb = to_table(tb)
  end
  for k, v in pairs(tb) do
    t[k] = v
  end
  local values
  if is_table(...) then
    values = ...
  else
    values = to_table(...)
  end
  for k, v in pairs(values) do
    t[k] = v
  end
  return t
end
return merge
