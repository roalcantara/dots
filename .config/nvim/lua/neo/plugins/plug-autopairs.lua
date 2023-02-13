return require('neo/lib/functions/imports')('nvim-autopairs', function(plugin)
  return plugin.setup({
    check_ts = true
  })
end)
