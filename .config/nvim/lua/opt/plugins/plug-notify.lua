return _G.imports('notify', function(plugin)
  return plugin.setup({
    stages = 'fade_in_slide_out',
    timeout = 5000,
    background_colour = '#24283b',
    icons = {
      ERROR = '',
      WARN = '',
      INFO = '',
      DEBUG = '',
      TRACE = '✎'
    }
  })
end)
