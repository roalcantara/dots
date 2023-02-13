is_nil = require 'neo/lib/lang/is_nil'

starts_with = (str, starting) ->
  return false if is_nil(str) or is_nil(starting)
  string.sub(str, 1, #starting) == starting

return starts_with
