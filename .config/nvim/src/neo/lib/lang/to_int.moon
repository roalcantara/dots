is_nil = require('neo/lib/lang/is_nil')

to_int = (value) ->
  return 0 if is_nil(value)
  num = tonumber(value)
  ---@diagnostic disable-next-line: param-type-mismatch
  num < 0 and math.ceil(num) or math.floor(num) if type(num) == 'number'

return to_int
