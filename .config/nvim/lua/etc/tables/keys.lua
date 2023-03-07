local is_table = require('etc/lang/is_table')
local to_table = require('etc/lang/to_table')
local is_str = require('etc/lang/is_str')
local gt = require('etc/lang/gt')
local lt = require('etc/lang/lt')
local keys
keys = function(object, asc)
  if asc == nil then
    asc = nil
  end
  if is_str(object) then
    local tmp = { }
    for i = 1, #object do
      table.insert(tmp, i)
    end
    object = tmp
  elseif not is_table(object) then
    object = to_table(object)
  end
  local values = { }
  for k, _ in pairs(object) do
    table.insert(values, k)
  end
  if not (asc) then
    return table.sort(values, gt)
  end
  if asc then
    return table.sort(values, lt)
  end
  return values
end
return keys
