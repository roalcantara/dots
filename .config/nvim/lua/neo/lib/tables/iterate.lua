local is_null = require('neo/lib/lang/is_null')
local iterate
iterate = function(predicate, selfArg, ...)
  predicate = predicate or function(...)
    return ...
  end
  if is_null(selfArg) then
    return predicate(...)
  else
    return predicate(selfArg, ...)
  end
end
return iterate
