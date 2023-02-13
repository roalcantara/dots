return require('neo/lib/functions/imports')('dressing', function(plugin)
  return plugin.setup({
    input = {
      enabled = true,
      default_prompt = 'Input:',
      prompt_align = 'left',
      insert_only = true,
      anchor = 'SW',
      border = 'rounded',
      relative = 'cursor',
      prefer_width = 0.4,
      width = nil,
      max_width = {
        140,
        0.9
      },
      min_width = {
        20,
        0.2
      },
      override = function(conf)
        return conf
      end,
      get_config = nil,
      win_options = {
        winblend = 10,
        winhighlight = ''
      }
    },
    select = {
      enabled = true,
      backend = {
        'telescope',
        'fzf_lua',
        'fzf',
        'builtin',
        'nui'
      },
      trim_prompt = true,
      telescope = nil,
      fzf = {
        window = {
          width = 0.5,
          height = 0.4
        }
      },
      fzf_lua = {
        winopts = {
          width = 0.5,
          height = 0.4
        }
      },
      nui = {
        position = '50%',
        size = nil,
        relative = 'editor',
        border = {
          style = 'rounded'
        },
        buf_options = {
          swapfile = false,
          filetype = 'DressingSelect'
        },
        win_options = {
          winblend = 10
        },
        max_width = 80,
        max_height = 40,
        min_width = 40,
        min_height = 10
      },
      builtin = {
        anchor = 'NW',
        border = 'rounded',
        relative = 'editor',
        width = nil,
        max_width = {
          140,
          0.8
        },
        min_width = {
          40,
          0.2
        },
        height = nil,
        max_height = 0.9,
        min_height = {
          10,
          0.2
        },
        override = function(conf)
          return conf
        end,
        win_options = {
          winblend = 10,
          winhighlight = ''
        }
      },
      format_item_override = { },
      get_config = nil
    }
  })
end)
