local is_nil = require('etc/lang/is_nil')
local starts_with
starts_with = function(str, starting)
  if is_nil(str) or is_nil(starting) then
    return false
  end
  return string.sub(str, 1, #starting) == starting
end
return starts_with
