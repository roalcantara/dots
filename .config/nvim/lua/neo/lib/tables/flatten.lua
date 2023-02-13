local is_table = require('neo/lib/lang/is_table')
local to_table = require('neo/lib/lang/to_table')
local flatten
flatten = function(...)
  local collection
  if is_table(...) then
    collection = ...
  else
    collection = to_table(...)
  end
  return vim.tbl_flatten(collection)
end
return flatten
