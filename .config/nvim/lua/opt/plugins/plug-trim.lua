return _G.imports('trim', function(plugin)
  return plugin.setup({
    ft_blocklist = { },
    trim_trailing = true,
    trim_last_line = true,
    trim_first_line = true,
    patterns = {
      [[%s/\(\n\n\)\n\+/\1/]]
    }
  })
end)
