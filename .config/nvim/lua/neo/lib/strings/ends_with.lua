local is_nil = require('neo/lib/lang/is_nil')
local ends_with
ends_with = function(str, ending)
  if is_nil(str) or is_nil(ending) then
    return false
  end
  return string.sub(str, -#ending) == ending
end
return ends_with
