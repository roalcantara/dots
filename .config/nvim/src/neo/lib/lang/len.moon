is_null = require 'neo/lib/lang/is_null'

---Return the length of the object
---@return integer
len = (object) =>
  return 0 if is_null(object)
  vim.fn.len(object)

return len
