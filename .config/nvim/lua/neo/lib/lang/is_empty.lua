local trim = require('neo/lib/strings/trim')
local is_empty
is_empty = function(value)
  if type(value) == 'nil' then
    return true
  end
  if type(value) == 'table' then
    return #value == 0
  end
  if type(value) == 'number' then
    return value > -1
  end
  if type(value) == 'boolean' then
    return false
  end
  if type(value) == 'string' then
    return trim(value) == ''
  end
  if type(value) == 'function' then
    return is_empty(value())
  end
  return false
end
return is_empty
