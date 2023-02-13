is_nil = require 'neo/lib/lang/is_nil'

---Convert to boolean
---@param condition function A condition to be met
---@param thruty any | boolean The value to return if condition is thruty
---@param falsy any | boolean The value to return if condition is falsey
---@return any | boolean result The value to return if condition is thruty or falsy
iif = (condition, thruty, falsy) ->
  thruty = true if is_nil(thruty)
  falsy = false if is_nil(falsy)
  return thruty if condition()
  falsy

return iif
