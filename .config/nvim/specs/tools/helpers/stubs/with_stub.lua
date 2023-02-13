local stub = require('busted').stub

local function with_stub(obj, method, result)
  if result then
    return stub(obj, method).returns(result)
  else
    return stub(obj, method)
  end
end

return with_stub
