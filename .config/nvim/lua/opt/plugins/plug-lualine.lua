return _G.imports('lualine', function(plugin)
  return plugin.setup({
    options = {
      theme = 'auto',
      always_divide_middle = true,
      component_separators = {
        left = '',
        right = ''
      },
      disabled_filetypes = { },
      icons_enabled = true,
      padding = 1,
      section_separators = {
        left = '',
        right = ''
      },
      globalstatus = true
    },
    sections = {
      lualine_a = {
        'mode'
      },
      lualine_b = {
        'branch',
        'diff',
        'diagnostics'
      },
      lualine_c = {
        {
          'filename',
          file_status = true,
          path = 3,
          shorting_target = 40,
          symbols = {
            modified = '[+]',
            readonly = '[-]',
            unnamed = '[New]'
          }
        }
      },
      lualine_x = {
        'encoding',
        'fileformat',
        'filetype'
      },
      lualine_y = {
        'progress'
      },
      lualine_z = {
        'location'
      }
    },
    inactive_sections = {
      lualine_a = { },
      lualine_b = { },
      lualine_c = {
        'filename'
      },
      lualine_x = {
        'location'
      },
      lualine_y = { },
      lualine_z = { }
    },
    tabline = { },
    extensions = {
      'quickfix',
      'fzf',
      'quickfix',
      'symbols-outline'
    }
  })
end)
