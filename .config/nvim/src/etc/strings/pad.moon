is_nil = require 'etc/lang/is_nil'
is_str = require 'etc/lang/is_str'
to_int = require 'etc/lang/to_int'
lpad = require 'etc/strings/lpad'
rpad = require 'etc/strings/rpad'

---Pads string on the left and right sides if it's shorter than length.
---Padding characters are truncated if they can't be evenly divided by length.
---@param s string The string to pad.
---@param l integer The padding length.
---@param c string The string used as padding.
---@return string result Returns the padded string.
pad = (s, l = 1, c = ' ') ->
  c = ' ' if is_nil(c)
  s = '' if is_nil(s)
  s = tostring(s) unless is_str(s)
  len = to_int((l / 2) + #s)
  res = rpad(s, len, c)
  lpad(res, l, c)

return pad
