local keys = require('neo/lib/tables/keys')
local lt = require('neo/lib/lang/lt')
local iterate_collection
iterate_collection = function(table, asc)
  if asc == nil then
    asc = true
  end
  local values = keys(table, asc) or { }
  local i = 0
  return function()
    if lt(i, #values) then
      i = i + 1
      local key = values[i]
      return key, table[key]
    end
  end
end
return iterate_collection
