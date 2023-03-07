-- A file explorer tree for neovim written in lua
-- https://github.com/kyazdani42/nvim-tree.lua
_G.imports 'nvim-tree', (plugin) ->
  -- list of groups can be found at `:help nvim_tree_highlight`
  vim.cmd[[highlight NvimTreeFolderIcon guibg=blue]]

  tree_cb = require'nvim-tree.config'.nvim_tree_callback

  -- https://github.com/kyazdani42/nvim-tree.lua/blob/master/doc/nvim-tree-lua.txt
  plugin.setup{
    create_in_closed_folder: false, -- when creating files, 1, sets the path of a file if cursor is on a closed folder to the parent folder, 0, and inside.
    respect_buf_cwd: true, -- changes cwd of nvim-tree to that of new buffer's when opening nvim-tree
    auto_reload_on_write: true,
    disable_netrw: true, -- disables netrw completely
    hijack_cursor: false, -- hijack the cursor in the tree to put it at the start of the filename
    hijack_netrw: true, -- hijack netrw window on startup
    hijack_unnamed_buffer_when_opening: false,
    ignore_buffer_on_setup: false,
    open_on_setup: false, -- open the tree when running this setup function
    open_on_setup_file: false,
    open_on_tab: false, -- opens the tree when changing/opening a new tab if the tree wasn't previously opened
    sort_by: 'name', -- sort by name, size, mtime, atime, ctime, or none
    update_cwd: false, -- updates the root directory of the tree on `DirChanged` (when you run `:cd` usually)
    view: {
      width: 30,
      hide_root_folder: false, -- Hide the root path of the current folder on top of the tree
      side: 'left',
      preserve_window_proportions: false,
      number: false,
      relativenumber: false,
      signcolumn: 'yes',
      adaptive_size: false,
      centralize_selection: false,
      mappings: {
        custom_only: false,
        list: {
          {key: {'<CR>', 'o'}, cb: tree_cb('edit')},
          {key: {'<C-]>'}, cb: tree_cb('cd')},
          {key: '<C-v>', cb: tree_cb('vsplit')},
          {key: '<C-x>', cb: tree_cb('split')},
          {key: '<C-t>', cb: tree_cb('tabnew')},
          {key: '<', cb: tree_cb('prev_sibling')},
          {key: '>', cb: tree_cb('next_sibling')},
          {key: 'P', cb: tree_cb('parent_node')},
          {key: '<BS>', cb: tree_cb('close_node')},
          {key: '<Tab>', cb: tree_cb('preview')},
          {key: 'K', cb: tree_cb('first_sibling')},
          {key: 'J', cb: tree_cb('last_sibling')},
          {key: 'I', cb: tree_cb('toggle_ignored')},
          {key: 'H', cb: tree_cb('toggle_dotfiles')},
          {key: 'R', cb: tree_cb('refresh')},
          {key: 'a', cb: tree_cb('create')},
          {key: 'd', cb: tree_cb('remove')},
          {key: 'D', cb: tree_cb('trash')},
          {key: 'r', cb: tree_cb('rename')},
          {key: '<C-r>', cb: tree_cb('full_rename')},
          {key: 'x', cb: tree_cb('cut')},
          {key: 'c', cb: tree_cb('copy')},
          {key: 'p', cb: tree_cb('paste')},
          {key: 'y', cb: tree_cb('copy_name')},
          {key: 'Y', cb: tree_cb('copy_path')},
          {key: 'gy', cb: tree_cb('copy_absolute_path')},
          {key: '[c', cb: tree_cb('prev_git_item')},
          {key: ']c', cb: tree_cb('next_git_item')},
          {key: '-', cb: tree_cb('dir_up')},
          {key: 's', cb: tree_cb('system_open')},
          {key: 'q', cb: tree_cb('close')},
          {key: 'g?', cb: tree_cb('toggle_help')}
        }
      }
    },
    renderer: {
      full_name: false,
      indent_width: 2,
      highlight_git: true, -- 1 enables file highlight for git attributes (can be used without icons)
      highlight_opened_files: 'icon', -- 1 enables folder and file icon highlight for opened files/directories
      root_folder_modifier: ':~', -- This is the default. See :help filename-modifiers for more options
      add_trailing: true, -- 1 append a trailing slash to folder names
      group_empty: true, -- 1 compact folders that only contain a single folder into one node
      indent_markers: {
        enable: false,
        inline_arrows: true,
        icons: {corner: '└', edge: '│', item: '│', bottom: '─', none: ' '}
      },
      icons: {
        webdev_colors: true,
        git_placement: 'before',
        padding: ' ', -- used for rendering the space between the icon and the filename It could break rendering if you set an empty string depending on font
        symlink_arrow: ' ~> ', -- Used as a separator between symlinks' source and target
        show: {
          file: true,
          folder: true, -- 1, it will only display if nvim-web-devicons is installed and on your runtimepath.
          folder_arrow: true, -- if folder is 1 and folder_arrows 1, shows small arrows next to the folder icons.
          git: true -- 0, do not show the icons for one of 'git' 'folder' and 'files' but this will not work when you set indent_markers (because of UI conflict)
        },
        glyphs: { -- shows icon by default if no icon is provided
          default: '',
          symlink: '',
          bookmark: '',
          folder: {
            arrow_closed: '',
            arrow_open: '',
            default: '',
            open: '',
            empty: '',
            empty_open: '',
            symlink: '',
            symlink_open: ''
          },
          git: {
            unstaged: '✗',
            staged: '✓',
            unmerged: '',
            renamed: '➜',
            untracked: '★',
            deleted: '',
            ignored: '◌'
          }
        }
      },
      special_files: { -- List of filenames that gets highlighted with NvimTreeSpecialFile
        'README.md',
        'readme.md',
        'Makefile',
        'MAKEFILE'
      },
      symlink_destination: true -- 1 shows the symlink destination as a tooltip on the filename
    },
    hijack_directories: {enable: true, auto_open: true},
    update_focused_file: { -- update the focused file on `BufEnter`, un-collapses the folders recursively until it finds the file
      enable: false, -- enables the feature
      update_cwd: false, -- update the root directory of the tree to the one of the folder containing the file if the file is not under the current root directory only relevant when `update_focused_file.enable` is true
      ignore_list: {} -- list of buffer names / filetypes that will not update the cwd if the file isn't found under the current root directory only relevant when `update_focused_file.update_cwd` is true and `update_focused_file.enable` is true
    },
    ignore_ft_on_setup: {}, -- will not open on setup if the filetype is in this list
    system_open: {cmd: '', args: {}},
    diagnostics: {
      enable: false,
      show_on_dirs: false,
      debounce_delay: 50,
      icons: {hint: '', info: '', warning: '', error: ''}
    },
    filters: {dotfiles: false, custom: {'.git', 'node_modules', '.cache'}, exclude: {}},
    git: {enable: true, ignore: true, show_on_dirs: true, timeout: 400},
    actions: {
      use_system_clipboard: true,
      change_dir: {enable: true, global: false, restrict_above_cwd: false},
      open_file: {
        quit_on_open: true,
        resize_window: false,
        window_picker: {
          enable: true,
          chars: 'ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890',
          exclude: {
            filetype: { -- indicates to the win picker that the buffer's win should't be selectable
              'notify',
              'packer',
              'qf',
              'diff',
              'fugitive',
              'fugitiveblame'
            },
            buftype: {'nofile', 'terminal', 'help'}
          }
        }
      },
      remove_file: {close_window: true}
    },
    trash: {cmd: 'trash', require_confirm: true},
    live_filter: {prefix: '[FILTER]: ', always_show_folders: true},
    log: {
      enable: false,
      truncate: false,
      types: {
        all: false,
        config: false,
        copy_paste: false,
        dev: false,
        diagnostics: false,
        git: false,
        profile: false,
        watcher: false
      }
    }
  }
