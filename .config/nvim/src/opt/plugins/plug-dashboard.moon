-- vm dashboard
-- https://github.com/glepnir/dashboard-nvim
_G.imports 'dashboard', (plugin) ->
  to = require 'etc/fn/path'

  footer = () ->
    plugins = #vim.tbl_keys(packer_plugins)
    v = vim.version()
    {string.format(' Neovim v%d.%d.%d   %d plugins loaded', v.major, v.minor, v.patch, plugins)}

  -- -- Highlight Group
  -- DashboardHeader DashboardCenter DashboardCenterIcon DashboardShortCut DashboardFooter
  plugin.setup {
    theme: 'doom' --  theme is doom and hyper default is hyper
    config: {
      -- type is table def
      header: {
        '',
        '',
        '',
        '⡿⠋⠄⣀⣀⣤⣴⣶⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣦⣌⠻⣿⣿',
        '⣴⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣦⠹⣿',
        '⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣧⠹',
        '⣿⣿⡟⢹⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡛⢿⣿⣿⣿⣮⠛⣿⣿⣿⣿⣿⣿⡆',
        '⡟⢻⡇⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣣⠄⡀⢬⣭⣻⣷⡌⢿⣿⣿⣿⣿⣿',
        '⠃⣸⡀⠈⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣧⠈⣆⢹⣿⣿⣿⡈⢿⣿⣿⣿⣿',
        '⠄⢻⡇⠄⢛⣛⣻⣿⣿⣿⣿⣿⣿⣿⣿⡆⠹⣿⣆⠸⣆⠙⠛⠛⠃⠘⣿⣿⣿⣿',
        '⠄⠸⣡⠄⡈⣿⣿⣿⣿⣿⣿⣿⣿⠿⠟⠁⣠⣉⣤⣴⣿⣿⠿⠿⠿⡇⢸⣿⣿⣿',
        '⠄⡄⢿⣆⠰⡘⢿⣿⠿⢛⣉⣥⣴⣶⣿⣿⣿⣿⣻⠟⣉⣤⣶⣶⣾⣿⡄⣿⡿⢸',
        '⠄⢰⠸⣿⠄⢳⣠⣤⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣧⣼⣿⣿⣿⣿⣿⣿⡇⢻⡇⢸',
        '⢷⡈⢣⣡⣶⠿⠟⠛⠓⣚⣻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣇⢸⠇⠘',
        '⡀⣌⠄⠻⣧⣴⣾⣿⣿⣿⣿⣿⣿⣿⣿⡿⠟⠛⠛⠛⢿⣿⣿⣿⣿⣿⡟⠘⠄⠄',
        '⣷⡘⣷⡀⠘⣿⣿⣿⣿⣿⣿⣿⣿⡋⢀⣠⣤⣶⣶⣾⡆⣿⣿⣿⠟⠁⠄⠄⠄⠄',
        '⣿⣷⡘⣿⡀⢻⣿⣿⣿⣿⣿⣿⣿⣧⠸⣿⣿⣿⣿⣿⣷⡿⠟⠉⠄⠄⠄⠄⡄⢀',
        '⣿⣿⣷⡈⢷⡀⠙⠛⠻⠿⠿⠿⠿⠿⠷⠾⠿⠟⣛⣋⣥⣶⣄⠄⢀⣄⠹⣦⢹⣿',
        '',
        '',
        ''
      },
      center: {
        -- { icon: '', icon_hl: 'group', desc: 'description', desc_hl: 'group', key: 'shortcut key in dashboard buffer not keymap !!', key_hl: 'group', action: '' },
        -- notice if you don't link config every highlight group. you can ignore this key. dashboard will use default highlight group like DashboardKey/Icon/Desc instead
        { icon: ' ', icon_hl: 'DashboardIcon', desc: 'New File',      desc_hl: 'DashboardDesc', key: 'SPC f n', key_hl: 'DashboardKey', action: 'DashboardNewFile',          },
        { icon: ' ', icon_hl: 'DashboardIcon', desc: 'History',       desc_hl: 'DashboardDesc', key: 'SPC f r', key_hl: 'DashboardKey', action: 'History',                   },
        { icon: ' ', icon_hl: 'DashboardIcon', desc: 'Project Files', desc_hl: 'DashboardDesc', key: 'SPC f p', key_hl: 'DashboardKey', action: 'GFiles',                    },
        { icon: ' ', icon_hl: 'DashboardIcon', desc: 'Find File',     desc_hl: 'DashboardDesc', key: 'SPC f f', key_hl: 'DashboardKey', action: 'Files',                     },
        { icon: ' ', icon_hl: 'DashboardIcon', desc: 'Find word',     desc_hl: 'DashboardDesc', key: 'SPC f w', key_hl: 'DashboardKey', action: 'Grep',                      },
        { icon: ' ', icon_hl: 'DashboardIcon', desc: 'TODO',          desc_hl: 'DashboardDesc', key: 'SPC . t', key_hl: 'DashboardKey', action: ":e #{to.config('TODO.md')}",},
        { icon: ' ', icon_hl: 'DashboardIcon', desc: 'Mappings',      desc_hl: 'DashboardDesc', key: 'SPC f m', key_hl: 'DashboardKey', action: 'Maps',                      },
        { icon: ' ', icon_hl: 'DashboardIcon', desc: 'Commands',      desc_hl: 'DashboardDesc', key: 'SPC f c', key_hl: 'DashboardKey', action: 'Commands',                  },
        { icon: ' ', icon_hl: 'DashboardIcon', desc: 'Quit',          desc_hl: 'DashboardDesc', key: 'SPC f q', key_hl: 'DashboardKey', action: ':q',                        }
      },
      disable_move: false, -- boolean default is false disable move key
      footer: footer!, -- footer
    },    --  config used for theme
    hide: {
      statusline: true    -- hide statusline default is true
      tabline: true       -- hide the tabline
      winbar: true        -- hide winbar
    },
    preview: {
      -- command: 'bat', -- preview command
      file_path: '',     -- preview file path
      file_height: 12,   -- preview file height
      file_width: 80     -- preview file width
    }
  }
