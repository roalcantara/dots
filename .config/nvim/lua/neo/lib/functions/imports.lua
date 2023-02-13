local imports
imports = function(name, callback, orElse)
  local status, plugin = pcall(require, name)
  if status then
    if (callback and type(callback) == 'function') then
      return callback(plugin)
    end
    return plugin
  end
  if (orElse and type(orElse) == 'function') then
    return orElse()
  end
  return function()
    return false
  end
end
return imports
