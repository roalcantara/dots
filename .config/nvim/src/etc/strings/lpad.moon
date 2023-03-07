is_nil = require 'etc/lang/is_nil'
is_str = require 'etc/lang/is_str'
to_int = require 'etc/lang/to_int'

---Pads string on the left side if it's shorter than length. Padding characters are truncated if they exceed length.
---@param s string The string to pad.
---@param l integer The padding length.
---@param c string The string used as padding.
---@return string result Returns the padded string.
lpad = (s, l = 1, c = ' ') ->
  c = ' ' if is_nil(c)
  s = '' if is_nil(s)
  s = tostring(s) unless is_str(s)
  "#{string.rep(c, to_int(l - #s))}#{s}"

return lpad
