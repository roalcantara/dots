local is_nil = require('neo/lib/lang/is_nil')
local iif
iif = function(condition, thruty, falsy)
  if is_nil(thruty) then
    thruty = true
  end
  if is_nil(falsy) then
    falsy = false
  end
  if condition() then
    return thruty
  end
  return falsy
end
return iif
