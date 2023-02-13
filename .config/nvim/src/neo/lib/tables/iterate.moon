is_null = require 'neo/lib/lang/is_null'

---Creates a function that invokes func with the arguments of the created function.
-- If func is a property name, the created function returns the property value for a given element.
-- If func is an array or object, the created function returns true for elements that contain the equivalent
-- source properties, otherwise it returns false.
---@param predicate any The value to convert to a callback.
---@param selfArg any The self binding of predicate.
---@return boolean result Returns the callback.
iterate = (predicate, selfArg, ...) ->
  predicate = predicate or (...) -> ...
  return if is_null(selfArg)
    predicate(...)
  else
    predicate(selfArg, ...)

return iterate
