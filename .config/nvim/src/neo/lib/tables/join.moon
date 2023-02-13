is_table = require 'neo/lib/lang/is_table'
to_table = require 'neo/lib/lang/to_table'

---Joins all arguments separated by separator
---@param collection table
---@param separator string | nil default ' '
---@return string result a concatenated string separator
join = (collection, separator = ' ') ->
  collection = to_table(collection) unless is_table(collection)
  vim.fn.join(collection, separator)

return join
