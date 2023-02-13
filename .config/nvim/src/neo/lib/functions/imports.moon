imports = (name, callback, orElse) ->
  status, plugin = pcall(require, name)
  if status
    return callback(plugin) if (callback and type(callback) == 'function')
    return plugin
  return orElse() if (orElse and type(orElse) == 'function')
  return () -> return false

return imports
