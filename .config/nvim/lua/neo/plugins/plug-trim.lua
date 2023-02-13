return require('neo/lib/functions/imports')('trim', function(plugin)
  return plugin.setup({
    disable = { },
    trim_trailing = true,
    trim_last_line = true,
    trim_first_line = true,
    patterns = {
      [[%s/\(\n\n\)\n\+/\1/]]
    }
  })
end)
