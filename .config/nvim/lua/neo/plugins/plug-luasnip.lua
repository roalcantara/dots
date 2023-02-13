return require('neo/lib/functions/imports')('luasnip', function(plugin)
  local types = require('luasnip.util.types')
  return plugin.config.set_config({
    history = true,
    updateevents = 'TextChanged,TextChangedI',
    enable_autosnippets = true,
    ext_opts = {
      [types.choiceNode] = {
        active = {
          virt_text = {
            {
              ' <- Current Choice',
              'NonTest'
            }
          }
        }
      }
    }
  })
end)
