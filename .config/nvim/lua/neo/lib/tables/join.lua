local is_table = require('neo/lib/lang/is_table')
local to_table = require('neo/lib/lang/to_table')
local join
join = function(collection, separator)
  if separator == nil then
    separator = ' '
  end
  if not (is_table(collection)) then
    collection = to_table(collection)
  end
  return vim.fn.join(collection, separator)
end
return join
