is_func = require 'neo/lib/lang/is_func'

--- Gets the property value at path of object. If the resolved value
--- is nil the defaultValue is used in its place.
---@param exp table|blob|dict|func The object to query.
---@param path string The path of the property to get.
---@param defaultValue any The value returned if the resolved value is nil.
---@return any Returns the resolved value.
---@example get({a={b={c={d=5}}}}, {'a', 'b', 'c', 'd'}) => 5
get = (exp, path, defaultValue = nil) ->
  return vim.fn.get(exp, path, defaultValue) unless is_func(exp)
  vim.fn.get(exp, path) if is_func(exp)

return get
