local stub = require('busted').stub

local function Stub_Mixin(obj)
  obj.stubs = {
    on = function(attr, name)
      local stubbed = stub(obj[attr], name)

      return {
        get = function ()
          return stubbed
        end,
        then_return = function(...)
          stubbed = stubbed.returns(...)
          return stubbed
        end
      }
    end,
    each = function(stubs)
      for attrs, stb in ipairs(stubs) do
        if stb.returns then
          stub(obj[attrs], stb.on).returns(stb.returns)
        else
          stub(obj[attrs], stb.on)
        end
      end
    end
  }

  return obj
end

return Stub_Mixin
