return _G.imports('dashboard', function(plugin)
  local to = require('etc/fn/path')
  local footer
  footer = function()
    local plugins = #vim.tbl_keys(packer_plugins)
    local v = vim.version()
    return {
      string.format(' Neovim v%d.%d.%d   %d plugins loaded', v.major, v.minor, v.patch, plugins)
    }
  end
  return plugin.setup({
    theme = 'doom',
    config = {
      header = {
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
      center = {
        {
          icon = ' ',
          icon_hl = 'DashboardIcon',
          desc = 'New File',
          desc_hl = 'DashboardDesc',
          key = 'SPC f n',
          key_hl = 'DashboardKey',
          action = 'DashboardNewFile'
        },
        {
          icon = ' ',
          icon_hl = 'DashboardIcon',
          desc = 'History',
          desc_hl = 'DashboardDesc',
          key = 'SPC f r',
          key_hl = 'DashboardKey',
          action = 'History'
        },
        {
          icon = ' ',
          icon_hl = 'DashboardIcon',
          desc = 'Project Files',
          desc_hl = 'DashboardDesc',
          key = 'SPC f p',
          key_hl = 'DashboardKey',
          action = 'GFiles'
        },
        {
          icon = ' ',
          icon_hl = 'DashboardIcon',
          desc = 'Find File',
          desc_hl = 'DashboardDesc',
          key = 'SPC f f',
          key_hl = 'DashboardKey',
          action = 'Files'
        },
        {
          icon = ' ',
          icon_hl = 'DashboardIcon',
          desc = 'Find word',
          desc_hl = 'DashboardDesc',
          key = 'SPC f w',
          key_hl = 'DashboardKey',
          action = 'Grep'
        },
        {
          icon = ' ',
          icon_hl = 'DashboardIcon',
          desc = 'TODO',
          desc_hl = 'DashboardDesc',
          key = 'SPC . t',
          key_hl = 'DashboardKey',
          action = ":e " .. tostring(to.config('TODO.md'))
        },
        {
          icon = ' ',
          icon_hl = 'DashboardIcon',
          desc = 'Mappings',
          desc_hl = 'DashboardDesc',
          key = 'SPC f m',
          key_hl = 'DashboardKey',
          action = 'Maps'
        },
        {
          icon = ' ',
          icon_hl = 'DashboardIcon',
          desc = 'Commands',
          desc_hl = 'DashboardDesc',
          key = 'SPC f c',
          key_hl = 'DashboardKey',
          action = 'Commands'
        },
        {
          icon = ' ',
          icon_hl = 'DashboardIcon',
          desc = 'Quit',
          desc_hl = 'DashboardDesc',
          key = 'SPC f q',
          key_hl = 'DashboardKey',
          action = ':q'
        }
      },
      disable_move = false,
      footer = footer()
    },
    hide = {
      statusline = true,
      tabline = true,
      winbar = true
    },
    preview = {
      file_path = '',
      file_height = 12,
      file_width = 80
    }
  })
end)
