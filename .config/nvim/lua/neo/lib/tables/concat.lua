local is_table = require('neo/lib/lang/is_table')
local to_table = require('neo/lib/lang/to_table')
local concat
concat = function(to, ...)
  if not (is_table(to)) then
    to = to_table(to)
  end
  local t
  if is_table(...) then
    t = ...
  else
    t = to_table(...)
  end
  for k, v in pairs(to) do
    t[k] = v
  end
  return t
end
return concat
