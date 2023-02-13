local is_table = require('neo/lib/lang/is_table')
local to_table = require('neo/lib/lang/to_table')
local extend
extend = function(to, ...)
  if is_table(to) then
    to = to
  else
    to = to_table(to)
  end
  local collection
  if is_table(...) then
    collection = ...
  else
    collection = to_table(...)
  end
  return vim.tbl_extend('force', to, collection)
end
return extend
