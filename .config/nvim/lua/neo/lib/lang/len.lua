local is_null = require('neo/lib/lang/is_null')
local len
len = function(self, object)
  if is_null(object) then
    return 0
  end
  return vim.fn.len(object)
end
return len
