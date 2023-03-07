local is_str = require('etc/lang/is_str')
local is_table = require('etc/lang/is_table')
local iterate_collection = require('etc/tables/iterate_collection')
local lt = require('etc/lang/lt')
local iter
iter = function(value)
  if is_str(value) then
    local i = 0
    return function()
      if lt(i, #value) then
        i = i + 1
        local c = value.sub(i, i)
        return i, c
      end
    end
  end
  if is_table(value) then
    return iterate_collection(value)
  end
  return function() end
end
