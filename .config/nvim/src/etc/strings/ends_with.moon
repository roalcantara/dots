is_nil = require 'etc/lang/is_nil'

ends_with = (str, ending) ->
  return false if is_nil(str) or is_nil(ending)
  string.sub(str, -#ending) == ending

return ends_with
