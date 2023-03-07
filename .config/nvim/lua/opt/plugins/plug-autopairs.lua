return _G.imports('nvim-autopairs', function(plugin)
  return plugin.setup({
    check_ts = true
  })
end)
