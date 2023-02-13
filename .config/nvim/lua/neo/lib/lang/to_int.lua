local is_nil = require('neo/lib/lang/is_nil')
local to_int
to_int = function(value)
  if is_nil(value) then
    return 0
  end
  local num = tonumber(value)
  if type(num) == 'number' then
    return num < 0 and math.ceil(num) or math.floor(num)
  end
end
return to_int
