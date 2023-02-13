local is_table = require('neo/lib/lang/is_table')
local compact = require('neo/lib/tables/compact')
local to_table
to_table = function(...)
  local params
  if is_table(...) then
    params = ...
  else
    params = to_table(...)
  end
  return compact(params)
end
return to_table
