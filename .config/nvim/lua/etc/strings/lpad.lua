local is_nil = require('etc/lang/is_nil')
local is_str = require('etc/lang/is_str')
local to_int = require('etc/lang/to_int')
local lpad
lpad = function(s, l, c)
  if l == nil then
    l = 1
  end
  if c == nil then
    c = ' '
  end
  if is_nil(c) then
    c = ' '
  end
  if is_nil(s) then
    s = ''
  end
  if not (is_str(s)) then
    s = tostring(s)
  end
  return tostring(string.rep(c, to_int(l - #s))) .. tostring(s)
end
return lpad
