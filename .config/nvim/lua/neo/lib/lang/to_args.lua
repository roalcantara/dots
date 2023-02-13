local is_table = require('neo/lib/lang/is_table')
local to_table = require('neo/lib/lang/to_table')
local to_args
to_args = function(value)
  if not (is_table(value)) then
    value = to_table(value)
  end
  return unpack(value)
end
return to_args
