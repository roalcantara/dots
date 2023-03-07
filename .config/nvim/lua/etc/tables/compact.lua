local is_nil = require('etc/lang/is_nil')
local is_table = require('etc/lang/is_table')
local push = require('etc/tables/push')
local compact
compact = function(...)
  local args = ...
  local t = { }
  if is_nil(args) then
    return t
  end
  if not is_table(args) then
    args = {
      args
    }
  end
  for _, v in pairs(...) do
    if not (is_nil(v)) then
      push(t, v)
    end
  end
  return t
end
return compact
