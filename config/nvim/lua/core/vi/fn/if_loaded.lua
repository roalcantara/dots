local function if_loaded(name, fallback, opts)
  local is_loaded, plugin = pcall(require, name)
  if is_loaded and plugin then
    return fallback(plugin, opts)
  end
end

return if_loaded
