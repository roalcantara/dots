return require('neo/lib/functions/imports')('nvim-tree', function(plugin)
  vim.cmd([[highlight NvimTreeFolderIcon guibg=blue]])
  local tree_cb = require('nvim-tree.config').nvim_tree_callback
  return plugin.setup({
    create_in_closed_folder = false,
    respect_buf_cwd = true,
    auto_reload_on_write = true,
    disable_netrw = true,
    hijack_cursor = false,
    hijack_netrw = true,
    hijack_unnamed_buffer_when_opening = false,
    ignore_buffer_on_setup = false,
    open_on_setup = false,
    open_on_setup_file = false,
    open_on_tab = false,
    sort_by = 'name',
    update_cwd = false,
    view = {
      width = 30,
      hide_root_folder = false,
      side = 'left',
      preserve_window_proportions = false,
      number = false,
      relativenumber = false,
      signcolumn = 'yes',
      adaptive_size = false,
      centralize_selection = false,
      mappings = {
        custom_only = false,
        list = {
          {
            key = {
              '<CR>',
              'o'
            },
            cb = tree_cb('edit')
          },
          {
            key = {
              '<C-]>'
            },
            cb = tree_cb('cd')
          },
          {
            key = '<C-v>',
            cb = tree_cb('vsplit')
          },
          {
            key = '<C-x>',
            cb = tree_cb('split')
          },
          {
            key = '<C-t>',
            cb = tree_cb('tabnew')
          },
          {
            key = '<',
            cb = tree_cb('prev_sibling')
          },
          {
            key = '>',
            cb = tree_cb('next_sibling')
          },
          {
            key = 'P',
            cb = tree_cb('parent_node')
          },
          {
            key = '<BS>',
            cb = tree_cb('close_node')
          },
          {
            key = '<Tab>',
            cb = tree_cb('preview')
          },
          {
            key = 'K',
            cb = tree_cb('first_sibling')
          },
          {
            key = 'J',
            cb = tree_cb('last_sibling')
          },
          {
            key = 'I',
            cb = tree_cb('toggle_ignored')
          },
          {
            key = 'H',
            cb = tree_cb('toggle_dotfiles')
          },
          {
            key = 'R',
            cb = tree_cb('refresh')
          },
          {
            key = 'a',
            cb = tree_cb('create')
          },
          {
            key = 'd',
            cb = tree_cb('remove')
          },
          {
            key = 'D',
            cb = tree_cb('trash')
          },
          {
            key = 'r',
            cb = tree_cb('rename')
          },
          {
            key = '<C-r>',
            cb = tree_cb('full_rename')
          },
          {
            key = 'x',
            cb = tree_cb('cut')
          },
          {
            key = 'c',
            cb = tree_cb('copy')
          },
          {
            key = 'p',
            cb = tree_cb('paste')
          },
          {
            key = 'y',
            cb = tree_cb('copy_name')
          },
          {
            key = 'Y',
            cb = tree_cb('copy_path')
          },
          {
            key = 'gy',
            cb = tree_cb('copy_absolute_path')
          },
          {
            key = '[c',
            cb = tree_cb('prev_git_item')
          },
          {
            key = ']c',
            cb = tree_cb('next_git_item')
          },
          {
            key = '-',
            cb = tree_cb('dir_up')
          },
          {
            key = 's',
            cb = tree_cb('system_open')
          },
          {
            key = 'q',
            cb = tree_cb('close')
          },
          {
            key = 'g?',
            cb = tree_cb('toggle_help')
          }
        }
      }
    },
    renderer = {
      full_name = false,
      indent_width = 2,
      highlight_git = true,
      highlight_opened_files = 'icon',
      root_folder_modifier = ':~',
      add_trailing = true,
      group_empty = true,
      indent_markers = {
        enable = false,
        inline_arrows = true,
        icons = {
          corner = '└',
          edge = '│',
          item = '│',
          bottom = '─',
          none = ' '
        }
      },
      icons = {
        webdev_colors = true,
        git_placement = 'before',
        padding = ' ',
        symlink_arrow = ' ~> ',
        show = {
          file = true,
          folder = true,
          folder_arrow = true,
          git = true
        },
        glyphs = {
          default = '',
          symlink = '',
          bookmark = '',
          folder = {
            arrow_closed = '',
            arrow_open = '',
            default = '',
            open = '',
            empty = '',
            empty_open = '',
            symlink = '',
            symlink_open = ''
          },
          git = {
            unstaged = '✗',
            staged = '✓',
            unmerged = '',
            renamed = '➜',
            untracked = '★',
            deleted = '',
            ignored = '◌'
          }
        }
      },
      special_files = {
        'README.md',
        'readme.md',
        'Makefile',
        'MAKEFILE'
      },
      symlink_destination = true
    },
    hijack_directories = {
      enable = true,
      auto_open = true
    },
    update_focused_file = {
      enable = false,
      update_cwd = false,
      ignore_list = { }
    },
    ignore_ft_on_setup = { },
    system_open = {
      cmd = '',
      args = { }
    },
    diagnostics = {
      enable = false,
      show_on_dirs = false,
      debounce_delay = 50,
      icons = {
        hint = '',
        info = '',
        warning = '',
        error = ''
      }
    },
    filters = {
      dotfiles = false,
      custom = {
        '.git',
        'node_modules',
        '.cache'
      },
      exclude = { }
    },
    git = {
      enable = true,
      ignore = true,
      show_on_dirs = true,
      timeout = 400
    },
    actions = {
      use_system_clipboard = true,
      change_dir = {
        enable = true,
        global = false,
        restrict_above_cwd = false
      },
      open_file = {
        quit_on_open = true,
        resize_window = false,
        window_picker = {
          enable = true,
          chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890',
          exclude = {
            filetype = {
              'notify',
              'packer',
              'qf',
              'diff',
              'fugitive',
              'fugitiveblame'
            },
            buftype = {
              'nofile',
              'terminal',
              'help'
            }
          }
        }
      },
      remove_file = {
        close_window = true
      }
    },
    trash = {
      cmd = 'trash',
      require_confirm = true
    },
    live_filter = {
      prefix = '[FILTER]: ',
      always_show_folders = true
    },
    log = {
      enable = false,
      truncate = false,
      types = {
        all = false,
        config = false,
        copy_paste = false,
        dev = false,
        diagnostics = false,
        git = false,
        profile = false,
        watcher = false
      }
    }
  })
end)
