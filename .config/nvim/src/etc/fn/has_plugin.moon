has_plugin = (name, callback, orElse)->
  require('etc/fn/imports')(name, callback, orElse) if packer_plugins[name] and packer_plugins[name].loaded

return has_plugin
