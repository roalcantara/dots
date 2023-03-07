local is_table = require('etc/lang/is_table')
local to_table = require('etc/lang/to_table')
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
