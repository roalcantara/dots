local has_plugin
has_plugin = function(name, callback, orElse)
  if packer_plugins[name] and packer_plugins[name].loaded then
    return require('etc/fn/imports')(name, callback, orElse)
  end
end
return has_plugin
