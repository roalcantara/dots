local with_stub = require('tools/helpers/stubs/with_stub')

local function on(obj, attr, name, results)
  return with_stub(obj[attr], name, results)
end

return on
