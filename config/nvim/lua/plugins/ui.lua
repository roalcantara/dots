local icons = require('core/ui/icons/icons_list')
local paths = require('core/vi/paths')
local statusline = require('core/ui/statusline')
local snacks_default_exclusions = require('core/ui/snacks/defaults').default_exclusions
local snacks_dashboard = require('core/ui/snacks/dashboard')

--- @diagnostic disable: codestyle-check
return {
  -- TokyoNight colorscheme
  -- https://github.com/folke/tokyonight.nvim
  {
    'folke/tokyonight.nvim',
    lazy = false, -- make sure we load this during startup if it is your main colorscheme
    priority = 1000,
    config = function()
      -- https://github.com/folke/tokyonight.nvim/blob/main/extras/lua/tokyonight_moon.lua
      local bg = '#1D212F'             -- '#202734'             -- editor.background
      local bg_dark = '#1e2531'        -- sideBar.background
      local bg_darker = '#202734'      -- panel.background
      local bg_highlight = '#272F3F'   -- editorHoverWidget.background
      local bg_visual = '#2c3648'      -- editor.selectionBackground (solid version)
      local bg_cursor_line = '#2a3445' -- editor.lineHighlightBackground (solid version)
      local fg = '#d8dde7'             -- editor.foreground
      local fg_dark = '#b9c2d3'        -- sideBar.foreground
      local fg_darker = '#536686'      -- tab.inactiveForeground
      local fg_gutter = '#3b4261'      -- editorLineNumber.activeForeground (brighter)
      local border = '#161c25'         -- editorGroup.border
      local panel_bg = '#1E2532'       -- sideBar.background from VS Code theme
      local panel_border = '#536686'   -- editorGroup.border from VS Code theme
      local green = '#4BF8A8'          -- '#10FA8D'
      local purple = '#fca7ea'
      local magenta = '#ED8AEF'
      local magenta2 = '#ff007c'
      local yellow_bright = '#ffd8ab'
      local cyan = '#70E8DB'
      local cyan_bright = '#222A38'

      require('tokyonight').setup({
        style = 'night',
        transparent = false,
        terminal_colors = true,
        styles = {
          comments = { italic = true },
          keywords = { italic = true, bold = true },
          functions = {},
          variables = {},
          sidebars = 'dark',
          floats = 'dark',
        },
        sidebars = { 'qf', 'help', 'vista_kind', 'terminal', 'packer' },
        day_brightness = 0.3,
        hide_inactive_statusline = false,
        dim_inactive = false,
        lualine_bold = false,
        on_colors = function(colors)
          -- Main background colors
          colors.green = green
          colors.magenta = magenta
          colors.cyan = cyan
          colors.bg = bg
          colors.bg_dark = bg_dark
          colors.bg_darker = bg_darker
          colors.bg_float = bg_highlight
          colors.bg_popup = bg_highlight
          colors.bg_sidebar = bg_dark
          colors.bg_statusline = bg
          colors.bg_visual = bg_visual
          colors.bg_cursor_line = bg_cursor_line

          -- Text colors
          colors.fg = fg
          colors.fg_dark = fg_dark
          colors.fg_darker = fg_darker
          colors.fg_gutter = fg_gutter
          colors.fg_sidebar = fg_dark

          -- Border and line colors
          colors.border = border
          colors.fg_border = border

          -- Special colors
          colors.comment = fg_darker
        end,
        on_highlights = function(hl, c)
          hl['@property'] = {
            fg = '#F19A68', -- "#F6A373",
          }
          hl['@variable'] = {
            fg = c.red,
          }
          hl['@variable.parameter'] = {
            fg = c.magenta,
          }
          hl.Constant = {
            fg = c.red,
          }
          hl['@keyword'] = {
            bold = true,
            cterm = {
              bold = true,
              italic = true,
            },
            fg = c.cyan,
            italic = true,
          }
          hl['@keyword.function'] = {
            fg = c.cyan,
            italic = true,
          }
          hl['@keyword.return'] = {
            fg = c.magenta,
            italic = true,
          }
          hl.LineNr = {
            fg = c.orange,
            bg = bg,
            bold = true,
          }
          hl.Number = {
            fg = c.fg,
          }
          hl.CursorLineNr = {
            fg = c.orange,
            bg = bg_cursor_line,
            bold = true,
          }
          hl.BlinkCmpMenu = {
            bg = panel_bg,
          }
          hl.BlinkCmpMenuBorder = {
            bg = panel_bg,
            fg = panel_border,
          }
          hl.BlinkCmpMenuSelection = {
            bg = bg_visual,
          }
          hl.BlinkCmpGhostText = {
            fg = fg_darker,
          }
          hl.BlinkCmpLabelMatch = {
            bold = true,
          }
          hl.NoiceSplitBackground = {
            bg = '#252F41',
          }
          hl.NoiceSplitBorder = {
            bg = panel_bg,
            -- fg = panel_border,
            fg = c.orange,
          }
          hl.NoicePopupBackground = {
            bg = panel_bg,
          }
          hl.NoicePopupBorder = {
            bg = panel_bg,
            fg = panel_border,
          }
          hl.NoiceNotifyBackground = {
            bg = panel_bg,
          }
          hl.NoiceNotifyBorder = {
            bg = panel_bg,
            fg = panel_border,
          }
          hl.SnacksPickerBackground = {
            bg = panel_bg,
          }
          hl.SnacksPickerBorder = {
            bg = panel_bg,
            fg = panel_border,
          }
          hl.NormalFloat = {
            bg = panel_bg,
            fg = c.fg,
          }
          hl.FloatTitle = {
            bg = panel_bg,
            fg = c.orange,
          }
          hl.SnacksPickerInputTitle = {
            bg = panel_bg,
            fg = c.orange,
          }
          hl.SnacksPickerInputBorder = {
            bg = panel_bg,
            fg = c.orange,
          }
          hl.SnacksPickerBoxTitle = {
            bg = panel_bg,
            fg = c.orange,
          }
          hl.SnacksPickerBoxInputTitle = {
            bg = panel_bg,
            fg = c.orange,
          }
          hl.SnacksPickerBoxInputBorder = {
            bg = panel_bg,
            fg = c.orange,
          }
          -- ColorColumn - vertical line that marks textwidth limit
          hl.ColorColumn = {
            bg = bg_highlight,
            fg = 'NONE',
          }
        end,
      })
      vim.cmd([[ colorscheme tokyonight-moon]])
    end,
  },

  -- Treesitter is a new parser generator tool that we can use in Neovim to power faster and more accurate syntax highlighting
  -- https://github.com/nvim-treesitter/nvim-treesitter | https://lazyvim.org/plugins/treesitter#nvim-treesitter
  {
    'nvim-treesitter/nvim-treesitter',
    version = false, -- last release is way too old and doesn't work on Windows
    build = ':TSUpdate',
    event = 'VeryLazy',
    lazy = vim.fn.argc(-1) == 0, -- load treesitter early when opening a file from the cmdline
    init = function(plugin)
      -- PERF: add nvim-treesitter queries to the rtp and it's custom query predicates early
      -- This is needed because a bunch of plugins no longer `require("nvim-treesitter")`, which
      -- no longer trigger the **nvim-treesitter** module to be loaded in time.
      -- Luckily, the only things that those plugins need are the custom queries, which we make available
      -- during startup.
      require('lazy.core.loader').add_to_rtp(plugin)
      require('nvim-treesitter.query_predicates')
    end,
    cmd = { 'TSUpdateSync', 'TSUpdate', 'TSInstall' },
    opts_extend = { 'ensure_installed' },
    dependencies = {
      -- Text Objects for Treesitter
      -- https://github.com/nvim-treesitter/nvim-treesitter-textobjects | https://lazyvim.org/plugins/treesitter#nvim-treesitter-textobjects
      {
        'nvim-treesitter/nvim-treesitter-textobjects',
        branch = 'main',
        event = 'VeryLazy',
        opts = {},
        keys = function()
          local moves = {
            goto_next_start = { [']f'] = '@function.outer', [']c'] = '@class.outer', [']a'] = '@parameter.inner' },
            goto_next_end = { [']F'] = '@function.outer', [']C'] = '@class.outer', [']A'] = '@parameter.inner' },
            goto_previous_start = { ['[f'] = '@function.outer', ['[c'] = '@class.outer', ['[a'] = '@parameter.inner' },
            goto_previous_end = { ['[F'] = '@function.outer', ['[C'] = '@class.outer', ['[A'] = '@parameter.inner' },
          }
          local ret = {} --- @type LazyKeysSpec[]
          for method, keymaps in pairs(moves) do
            for key, query in pairs(keymaps) do
              local desc = query:gsub('@', ''):gsub('%..*', '')
              desc = desc:sub(1, 1):upper() .. desc:sub(2)
              desc = (key:sub(1, 1) == '[' and 'Prev ' or 'Next ') .. desc
              desc = desc .. (key:sub(2, 2) == key:sub(2, 2):upper() and ' End' or ' Start')
              ret[#ret + 1] = {
                key,
                function()
                  -- don't use treesitter if in diff mode and the key is one of the c/C keys
                  if vim.wo.diff and key:find('[cC]') then
                    return vim.cmd('normal! ' .. key)
                  end
                  require('nvim-treesitter-textobjects.move')[method](query, 'textobjects')
                end,
                desc = desc,
                mode = { 'n', 'x', 'o' },
                silent = true,
              }
            end
          end
          return ret
        end,
        config = function(_, opts)
          local TS = require('nvim-treesitter-textobjects')
          if not TS.setup then
            Neo.error('Please use `:Lazy` and update `nvim-treesitter`')
            return
          end
          TS.setup(opts)
        end,
      },
      -- Treesitter Context | A plugin for displaying the context of the current cursor position
      -- https://github.com/nvim-treesitter/nvim-treesitter-context | https://lazyvim.org/extras/ui/treesitter-context#nvim-treesitter-context
      {
        'nvim-treesitter/nvim-treesitter-context',
        event = 'VeryLazy',
        opts = {
          mode = 'cursor',
          max_lines = 3,
        },
      },
    },
    opts = {
      ensure_installed = {
        'bash',
        'c',
        'css',
        'diff',
        'dockerfile',
        'git_config',
        'git_rebase',
        'gitattributes',
        'gitcommit',
        'gitignore',
        'go',
        'gomod',
        'gosum',
        'gowork',
        'html',
        'ini',
        'javascript',
        'jsdoc',
        'json',
        'latex',
        'lua',
        'luadoc',
        'luap',
        'make',
        'markdown_inline',
        'markdown',
        'norg',
        'printf',
        'python',
        'query',
        'regex',
        'ruby',
        'scss',
        'svelte',
        'toml',
        'tsx',
        'typescript',
        'typst',
        'vim',
        'vimdoc',
        'vue',
        'xml',
        'yaml',
      },
      ignore_install = { 'latex' },
      highlight = {
        enable = true,
        -- Setting this to true will run `:h syntax` and tree-sitter at the same time.
        -- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
        -- Using this option may slow down your editor, and you may see some duplicate highlights.
        -- Instead of true it can also be a list of languages
        -- https://github.com/catppuccin/nvim?tab=readme-ov-file#wrong-treesitter-highlights
        additional_vim_regex_highlighting = false,
      },
      indent = { enable = true },
      folds = { enable = true },
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = '<CR>',
          node_incremental = '<CR>',
          scope_incremental = '<TAB>',
          node_decremental = '<S-TAB>',
        },
      },
      textobjects = {
        select = {
          enable = true,
          lookahead = true,

          keymaps = {
            -- You can use the capture groups defined in textobjects.scm
            ['af'] = { query = '@function.outer', desc = 'around a function' },
            ['if'] = { query = '@function.inner', desc = 'inner part of a function' },
            ['ac'] = { query = '@class.outer', desc = 'around a class' },
            ['ic'] = { query = '@class.inner', desc = 'inner part of a class' },
            ['ai'] = { query = '@conditional.outer', desc = 'around an if statement' },
            ['ii'] = { query = '@conditional.inner', desc = 'inner part of an if statement' },
            ['al'] = { query = '@loop.outer', desc = 'around a loop' },
            ['il'] = { query = '@loop.inner', desc = 'inner part of a loop' },
            ['ap'] = { query = '@parameter.outer', desc = 'around parameter' },
            ['ip'] = { query = '@parameter.inner', desc = 'inside a parameter' },
          },
          selection_modes = {
            ['@parameter.outer'] = 'v',   -- charwise
            ['@parameter.inner'] = 'v',   -- charwise
            ['@function.outer'] = 'v',    -- charwise
            ['@conditional.outer'] = 'V', -- linewise
            ['@loop.outer'] = 'V',        -- linewise
            ['@class.outer'] = '<c-v>',   -- blockwise
          },
          include_surrounding_whitespace = false,
        },
        move = {
          enable = true,
          set_jumps = true, -- whether to set jumps in the jumplist
          goto_previous_start = {
            ['[f'] = { query = '@function.outer', desc = 'Previous function' },
            ['[c'] = { query = '@class.outer', desc = 'Previous class' },
            ['[p'] = { query = '@parameter.inner', desc = 'Previous parameter' },
          },
          goto_next_start = {
            [']f'] = { query = '@function.outer', desc = 'Next function' },
            [']c'] = { query = '@class.outer', desc = 'Next class' },
            [']p'] = { query = '@parameter.inner', desc = 'Next parameter' },
          },
        },
        swap = {
          enable = true,
          swap_next = {
            ['<leader>a'] = '@parameter.inner',
          },
          swap_previous = {
            ['<leader>A'] = '@parameter.inner',
          },
        },
      },
    },
    config = function(_, opts)
      vim.api.nvim_create_autocmd('FileType', {
        group = vim.api.nvim_create_augroup('neovim_custom_treesitter_start_highlighting', { clear = true }),
        callback = function(ev)
          -- highlighting
          pcall(vim.treesitter.start)
        end,
      })
      require('nvim-treesitter.configs').setup(opts)
    end,
  },

  -- Helpview | A modern UI for Neovim's help system
  -- The plugin should be loaded after your colorscheme to ensure the correct highlight groups are used
  -- https://github.com/OXY2DEV/helpview.nvim
  {
    'OXY2DEV/helpview.nvim',
    lazy = false,
    opts = {},
  },

  -- Automatically add closing tags for HTML and JSX
  -- https://github.com/windwp/nvim-ts-autotag | https://lazyvim.org/plugins/treesitter#nvim-ts-autotag
  {
    'windwp/nvim-ts-autotag',
    event = 'VeryLazy',
    opts = {},
  },

  -- Mini Icons | A set of icons for Neovim
  -- https://github.com/nvim-mini/mini.icons | https://lazyvim.org/plugins/ui#miniicons
  {
    'nvim-mini/mini.icons',
    lazy = true,
    opts = {
      file = {
        ['.keep'] = { glyph = '󰊢', hl = 'MiniIconsGrey' },
        ['devcontainer.json'] = { glyph = '', hl = 'MiniIconsAzure' },
      },
      filetype = {
        dotenv = { glyph = '', hl = 'MiniIconsYellow' },
      },
    },
    init = function()
      package.preload['nvim-web-devicons'] = function()
        require('mini.icons').mock_nvim_web_devicons()
        return package.loaded['nvim-web-devicons']
      end
    end,
  },

  -- SNACKS | A modern UI library for Neovim | https://github.com/folke/snacks.nvim
  -- https://lazyvim.org/extras/editor/snacks_picker#snacksnvim-1
  {
    'folke/snacks.nvim',
    priority = 1000,
    lazy = false,
    opts = function(_, opts)
      return vim.tbl_deep_extend('force', opts or {}, {
        dashboard = {
          enabled = true,
          open_on_startup = true,
          preset = {
            header = snacks_dashboard.header(),
            keys = {
              { icon = '󰀶 ', key = 's', desc = 'Smart Find Files', action = ':lua Snacks.picker.smart({})' },
              { icon = ' ', key = 'f', desc = 'Find File', action = ':lua Snacks.picker.files()' },
              { icon = ' ', key = 'n', desc = 'New File', action = ':ene | startinsert' },
              { icon = ' ', key = 'g', desc = 'Find Text', action = ':lua Snacks.picker.grep()' },
              { icon = ' ', key = 'r', desc = 'Recent Files', action = ':lua Snacks.picker.recent()' },
              { icon = '󰒲 ', key = 'l', desc = 'Lazy', action = ':Lazy' },
              { icon = ' ', key = 'q', desc = 'Quit', action = '<CMD>:qa<CR>' },
            },
          },
          sections = {
            { section = 'header' },
            { section = 'keys',   gap = 1, padding = 1 },
            { section = 'startup' },
          },
        },
        -- Focus on the active scope by dimming the rest
        -- https://github.com/folke/snacks.nvim/blob/main/docs/dim.md#%EF%B8%8F-config
        -- dim = { enabled = true },
        -- A file explorer for snacks (replace netrw)
        -- https://github.com/folke/snacks.nvim/blob/main/docs/explorer.md
        explorer = { enabled = true, replace_netrw = true },
        -- Image viewer using Kitty Graphics Protocol, supported by kitty, wezterm and ghostty
        -- Supports pdf, png, jpg, jpeg, gif, bmp, webp, tiff, heic, avif, mp4, mov, avi, mkv, webm
        -- https://github.com/folke/snacks.nvim/blob/main/docs/image.md
        image = { enabled = true },
        -- Visualize indent guides and scopes based on treesitter or indent
        -- https://github.com/folke/snacks.nvim/blob/main/docs/indent.md
        indent = { enabled = true },
        -- Better vim.ui.input
        -- https://github.com/folke/snacks.nvim/blob/main/docs/input.md
        input = { enabled = true },
        -- Pretty vim.notify (disabled in favor of noice.nvim)
        -- https://github.com/folke/snacks.nvim/blob/main/docs/notifier.md | https://github.com/folke/snacks.nvim/blob/main/docs/notify.md
        notifier = { enabled = true },
        -- When doing nvim somefile.txt, it will render the file as quickly as possible, before loading your plugins
        -- https://github.com/folke/snacks.nvim/blob/main/docs/quickfile.md
        quickfile = { enabled = true },
        -- Scope detection based on treesitter or indent. The indent-based algorithm is similar to what is used in mini.indentscope.
        -- https://github.com/folke/snacks.nvim/blob/main/docs/scope.md
        scope = { enabled = true },
        -- Scratch buffers with a persistent file
        -- https://github.com/folke/snacks.nvim/blob/main/docs/scratch.md
        scratch = {
          enabled = true,
          ft = function()
            return vim.bo.filetype ~= '' and vim.bo.filetype or 'lua'
          end,
          win = {
            style = 'scratch',
            -- width = 0.7,
            -- height = 0.6,
            -- border = 'rounded',
            -- enter = true,
            -- minimal = false,
            -- title_pos = 'center',
            -- footer_pos = 'center',
            -- keys = {
            --   q = 'close',
            -- },
          },
          win_by_ft = {
            lua = {
              keys = {
                ['source'] = {
                  '<D-CR>',
                  function(self)
                    local name = 'scratch.' .. vim.fn.fnamemodify(vim.api.nvim_buf_get_name(self.buf), ':e')
                    Snacks.debug.run({ buf = self.buf, name = name })
                  end,
                  desc = 'Source buffer',
                  mode = { 'n', 'x' },
                },
              },
            },
          },
        },
        -- Disable snacks scroll when animate is enabled
        -- https://github.com/folke/snacks.nvim/blob/main/docs/scroll.md
        scroll = { enabled = false },
        -- Pretty status column
        -- https://github.com/folke/snacks.nvim/blob/main/docs/statuscolumn.md
        statuscolumn = { enabled = false }, -- we set this in options.lua
        -- Create and toggle floating/split terminals
        -- https://github.com/folke/snacks.nvim/blob/main/docs/terminal.md
        terminal = { enabled = true },
        -- Toggle keymaps integrated with which-key icons / colors
        -- https://github.com/folke/snacks.nvim/blob/main/docs/toggle.md
        toggle = { enabled = true, notify = true },
        -- Auto-show LSP references and quickly navigate between them
        -- https://github.com/folke/snacks.nvim/blob/main/docs/words.md
        words = { enabled = true },
        -- Zen mode • distraction-free coding
        -- https://github.com/folke/snacks.nvim/blob/main/docs/zen.md
        zen = {
          toggles = {
            dim = true,
            git_signs = false,
            mini_diff_signs = false,
            diagnostics = true,
            inlay_hints = false,
          },
          show = {
            statusline = false, -- can only be shown when using the global statusline
            tabline = false,
          },
          win = {
            style = 'zen',
          },
          on_open = require('core/vi/maps/execute_on_esc')({
            on_esc = function(_)
              return Snacks.zen()
            end,
            desc = 'Quit on <Esc>',
          }),
          zoom = {
            toggles = {},
            show = { statusline = true, tabline = true },
            win = {
              backdrop = false,
              width = 0, -- full width
            },
          },
        },
        win = { enabled = true },
        picker = {
          enabled = true,
          layout = {
            layout = { backdrop = true },
          },
          -- Global win options for all pickers to make them visually distinct
          win = {
            input = {
              win_options = {
                winhighlight = 'Normal:SnacksPickerBackground,FloatBorder:SnacksPickerBorder',
              },
              keys = {
                s = 'flash',
                ['<A-s>'] = { 'flash', mode = { 'n', 'i' } },
              },
            },
            list = {
              win_options = {
                winhighlight = 'Normal:SnacksPickerBackground,FloatBorder:SnacksPickerBorder',
              },
            },
          },
          formatters = {
            file = { filename_first = true },
          },
          actions = {},
          sources = {
            explorer = {
              finder = 'explorer',
              sort = { fields = { 'sort' } },
              supports_live = true,
              tree = true,
              watch = true,
              diagnostics = true,
              diagnostics_open = false,
              git_status = true,
              git_status_open = false,
              git_untracked = true,
              follow_file = true,
              focus = 'list',
              auto_close = false,
              hidden = true,
              ignored = false,
              exclude = snacks_default_exclusions,
              jump = { close = true },
              cwd = vim.fn.expand('%:p:h'),
              layout = { preset = 'sidebar', preview = false },
              -- to show the explorer to the right, add the below to
              -- your config under `opts.picker.sources.explorer`
              -- layout = { layout = { position = "right" } },
              formatters = {
                file = { filename_only = true },
                severity = { pos = 'right' },
              },
              matcher = { sort_empty = false, fuzzy = false },
              config = function(options)
                return require('snacks.picker.source.explorer').setup(options)
              end,
              win = {
                list = {
                  keys = {
                    ['<BS>'] = 'explorer_up',
                    ['l'] = 'confirm',
                    ['h'] = 'explorer_close', -- close directory
                    ['a'] = 'explorer_add',
                    ['d'] = 'explorer_del',
                    ['r'] = 'explorer_rename',
                    ['c'] = 'explorer_copy',
                    ['m'] = 'explorer_move',
                    ['o'] = 'explorer_open', -- open with system application
                    ['P'] = 'toggle_preview',
                    ['y'] = { 'explorer_yank', mode = { 'n', 'x' } },
                    ['p'] = 'explorer_paste',
                    ['u'] = 'explorer_update',
                    ['<c-c>'] = 'tcd',
                    ['<leader>/'] = 'picker_grep',
                    ['<c-t>'] = 'terminal',
                    ['.'] = 'explorer_focus',
                    ['I'] = 'toggle_ignored',
                    ['H'] = 'toggle_hidden',
                    ['Z'] = 'explorer_close_all',
                    [']g'] = 'explorer_git_next',
                    ['[g'] = 'explorer_git_prev',
                    [']d'] = 'explorer_diagnostic_next',
                    ['[d'] = 'explorer_diagnostic_prev',
                    [']w'] = 'explorer_warn_next',
                    ['[w'] = 'explorer_warn_prev',
                    [']e'] = 'explorer_error_next',
                    ['[e'] = 'explorer_error_prev',
                  },
                },
              },
            },
            files = {
              hidden = true,
              exclude = snacks_default_exclusions,
              actions = {
                edit_split_down = { action = 'confirm', cmd = 'botright split' },
                edit_split_up = { action = 'confirm', cmd = 'topleft split' },
                edit_split_right = { action = 'confirm', cmd = 'leftabove vsplit | bprev | wincmd l' },
                -- edit_split_right = { action = 'confirm', cmd = 'botright vsplit' },
                edit_split_left = { action = 'confirm', cmd = 'topleft vsplit' },
              },
              win = {
                input = {
                  keys = {
                    ['<D-Down>'] = { 'edit_split', mode = { 'n', 'i' }, desc = 'Edit Split Down' },
                    ['<D-Up>'] = { 'edit_split_up', mode = { 'n', 'i' }, desc = 'Edit Split Up' },
                    ['<D-Right>'] = { 'edit_vsplit', mode = { 'n', 'i' }, desc = 'Edit Split Right' },
                    ['<D-Left>'] = { 'edit_split_left', mode = { 'n', 'i' }, desc = 'Edit Split Left' },
                  },
                },
                list = {
                  keys = {
                    ['<D-Down>'] = { 'edit_split', mode = { 'n', 'i' }, desc = 'Edit Split Down' },
                    ['<D-Up>'] = { 'edit_split_up', mode = { 'n', 'i' }, desc = 'Edit Split Up' },
                    ['<D-Right>'] = { 'edit_vsplit', mode = { 'n', 'i' }, desc = 'Edit Split Right' },
                    ['<D-Left>'] = { 'edit_split_left', mode = { 'n', 'i' }, desc = 'Edit Split Left' },
                  },
                },
              },
            },
            grep = {
              finder = 'grep',
              regex = true,
              format = 'file',
              show_empty = true,
              live = true, -- live grep by default
              supports_live = true,
              hidden = true,
              ignored = false,
              exclude = snacks_default_exclusions,
            },
            grep_buffers = {
              finder = 'grep',
              format = 'file',
              live = true,
              buffers = true,
              need_search = false,
              supports_live = true,
              hidden = true,
              ignored = false,
              exclude = snacks_default_exclusions,
            },
            smart = {
              multi = { 'buffers', 'recent', 'files' },
              format = 'file',     -- use `file` format for all sources
              matcher = {
                cwd_bonus = true,  -- boost cwd matches
                frecency = true,   -- use frecency boosting
                sort_empty = true, -- sort even when the filter is empty
              },
              transform = 'unique_file',
              hidden = true,
              ignored = false,
              exclude = snacks_default_exclusions,
              actions = {
                edit_split_down = { action = 'confirm', cmd = 'botright split' },
                edit_split_up = { action = 'confirm', cmd = 'topleft split' },
                edit_split_right = { action = 'confirm', cmd = 'leftabove vsplit | bprev | wincmd l' },
                -- edit_split_right = { action = 'confirm', cmd = 'botright vsplit' },
                edit_split_left = { action = 'confirm', cmd = 'topleft vsplit' },
              },
              win = {
                input = {
                  keys = {
                    ['<D-Down>'] = { 'edit_split', mode = { 'n', 'i' }, desc = 'Edit Split Down' },
                    ['<D-Up>'] = { 'edit_split_up', mode = { 'n', 'i' }, desc = 'Edit Split Up' },
                    ['<D-Right>'] = { 'edit_vsplit', mode = { 'n', 'i' }, desc = 'Edit Split Right' },
                    ['<D-Left>'] = { 'edit_split_left', mode = { 'n', 'i' }, desc = 'Edit Split Left' },
                  },
                },
                list = {
                  keys = {
                    ['<D-Down>'] = { 'edit_split', mode = { 'n', 'i' }, desc = 'Edit Split Down' },
                    ['<D-Up>'] = { 'edit_split_up', mode = { 'n', 'i' }, desc = 'Edit Split Up' },
                    ['<D-Right>'] = { 'edit_vsplit', mode = { 'n', 'i' }, desc = 'Edit Split Right' },
                    ['<D-Left>'] = { 'edit_split_left', mode = { 'n', 'i' }, desc = 'Edit Split Left' },
                  },
                },
              },
            },
            commands = {
              confirm = function(picker, item)
                picker:close()
                if item then
                  vim.schedule(function()
                    vim.cmd(item.cmd)
                  end)
                end
              end,
            },
            buffers = {
              win = {
                input = {
                  keys = {
                    ['<D-x>'] = { 'bufdelete', mode = { 'n', 'i' }, desc = 'Delete' },
                    ['<D-Down>'] = { 'move_split_down', mode = { 'n', 'i' }, desc = 'Move Split Down' },
                    ['<D-Up>'] = { 'move_split_up', mode = { 'n', 'i' }, desc = 'Move Split Up' },
                    ['<D-Right>'] = { 'move_split_right', mode = { 'n', 'i' }, desc = 'Move Split Right' },
                    ['<D-Left>'] = { 'move_split_left', mode = { 'n', 'i' }, desc = 'Move Split Left' },
                  },
                },
                list = {
                  keys = {
                    ['<D-x>'] = { 'bufdelete', mode = { 'n', 'i' }, desc = 'Delete' },
                    ['<D-Down>'] = { 'move_split_down', mode = { 'n', 'i' }, desc = 'Move Split Down' },
                    ['<D-Up>'] = { 'move_split_up', mode = { 'n', 'i' }, desc = 'Move Split Up' },
                    ['<D-Right>'] = { 'move_split_right', mode = { 'n', 'i' }, desc = 'Move Split Right' },
                    ['<D-Left>'] = { 'move_split_left', mode = { 'n', 'i' }, desc = 'Move Split Left' },
                  },
                },
              },
            },
            help = {
              -- Search for the word under the cursor or the current visual selection, if any
              pattern = function(picker)
                return picker:word()
              end,
            },
          },
        },
        styles = {
          {
            position = "float",
            titlte = 'Neovim Help!',
            backdrop = 60,
            height = 0.9,
            width = 0.9,
            zindex = 50,
          },
          scratch = {
            titlte = 'Playground',
            keys = { esc = 'close' },
          },
          notification_history = {
            keys = { q = 'close', esc = 'close' },
          }
        }
      })
    end,
  },

  -- Mini Animate | Animates many common Neovim actions, like scrolling, moving the cursor, and resizing windows
  -- https://github.com/nvim-mini/mini.animate | https://lazyvim.org/extras/ui/mini-animate#minianimate
  {
    'nvim-mini/mini.animate',
    event = 'VeryLazy',
    cond = vim.g.neovide == nil,
    opts = function(_, opts)
      -- don't use animate when scrolling with the mouse
      local mouse_scrolled = false
      for _, scroll in ipairs({ 'Up', 'Down' }) do
        local key = '<ScrollWheel' .. scroll .. '>'
        vim.keymap.set({ '', 'i' }, key, function()
          mouse_scrolled = true
          return key
        end, { expr = true })
      end

      vim.api.nvim_create_autocmd('FileType', {
        pattern = 'grug-far',
        callback = function()
          vim.b.minianimate_disable = true
        end,
      })

      Snacks.toggle({
        name = 'Mini Animate',
        get = function()
          return not vim.g.minianimate_disable
        end,
        set = function(state)
          vim.g.minianimate_disable = not state
        end,
      }):map('<leader>ua')

      local animate = require('mini.animate')
      return vim.tbl_deep_extend('force', opts, {
        cursor = {
          -- Whether to enable this animation
          enable = false,
        },
        resize = {
          timing = animate.gen_timing.linear({ duration = 50, unit = 'total' }),
        },
        scroll = {
          timing = animate.gen_timing.linear({ duration = 150, unit = 'total' }),
          subscroll = animate.gen_subscroll.equal({
            predicate = function(total_scroll)
              if mouse_scrolled then
                mouse_scrolled = false
                return false
              end
              return total_scroll > 1
            end,
          }),
        },
      })
    end,
  },

  -- Noice | Highly experimental plugin that completely replaces the UI for messages, cmdline and the popupmenu
  -- https://github.com/folke/noice.nvim
  {
    'folke/noice.nvim',
    event = 'VeryLazy',
    dependencies = {
      'MunifTanjim/nui.nvim',
    },
    opts = function(_, opts)
      return vim.tbl_deep_extend('force', opts or {}, {
        -- https://github.com/folke/noice.nvim/wiki/A-Guide-to-Messages#lsp-messages
        lsp = {
          override = {
            ['vim.lsp.util.convert_input_to_markdown_lines'] = true,
            ['vim.lsp.util.stylize_markdown'] = true,
          },
          hover = {
            enable = false,
          },
          signature = {
            enabled = true,
          },
          documentation = {
            enabled = true,
          },
        },
        -- Hide written messages
        -- https://github.com/folke/noice.nvim/wiki/Configuration-Recipes#hide-written-messages-1
        routes = {
          {
            filter = {
              event = 'msg_show',
              any = {
                { find = '%d+L, %d+B' },
                { find = '; after #%d+' },
                { find = '; before #%d+' },
              },
            },
            view = 'mini',
          },
          {
            filter = {
              event = 'notify',
              find = 'No information available',
            },
            opts = { skip = true },
          },
          {
            filter = {
              event = 'msg_show',
              kind = 'search_count',
            },
            opts = { skip = true },
          },
        },
        messages = {
          -- NOTE: If you enable messages, then the cmdline is enabled automatically.
          -- This is a current Neovim limitation.
          enabled = true,              -- enables the Noice messages UI
          view = 'notify',             -- default view for messages
          view_error = 'notify',       -- view for errors
          view_warn = 'notify',        -- view for warnings
          view_history = 'messages',   -- view for :messages
          view_search = 'virtualtext', -- view for search count messages. Set to `false` to disable
        },
        popupmenu = {
          enabled = true,  -- enables the Noice popupmenu UI
          backend = 'nui', -- backend to use to show regular cmdline completions
          -- Icons for completion item kinds (see defaults at noice.config.icons.kinds)
          kind_icons = {}, -- set to `false` to disable icons
        },
        -- default options for require('noice').redirect
        -- see the section on Command Redirection
        redirect = {
          view = 'popup',
          filter = { event = 'msg_show' },
        },
        -- You can add any custom commands below that will be available with `:Noice command`
        commands = {
          history = {
            -- options for the message history that you get with `:Noice`
            view = 'split',
            opts = { enter = true, format = 'details' },
            filter = {
              any = {
                { event = 'notify' },
                { error = true },
                { warning = true },
                { event = 'msg_show', kind = { '' } },
                { event = 'lsp',      kind = 'message' },
              },
            },
          },
          -- :Noice last
          last = {
            view = 'popup',
            opts = { enter = true, format = 'details' },
            filter = {
              any = {
                { event = 'notify' },
                { error = true },
                { warning = true },
                { event = 'msg_show', kind = { '' } },
                { event = 'lsp',      kind = 'message' },
              },
            },
            filter_opts = { count = 1 },
          },
          -- :Noice errors
          errors = {
            -- options for the message history that you get with `:Noice`
            view = 'popup',
            opts = { enter = true, format = 'details' },
            filter = { error = true },
            filter_opts = { reverse = true },
          },
          all = {
            -- options for the message history that you get with `:Noice`
            view = 'split',
            opts = { enter = true, format = 'details' },
            filter = {},
          },
        },
        notify = {
          enabled = true,
          view = 'notify',
        },
        -- Custom views with distinct backgrounds for better panel separation
        views = {
          split = {
            win_options = {
              winhighlight = 'Normal:NoiceSplitBackground,FloatBorder:NoiceSplitBorder',
            },
          },
          popup = {
            win_options = {
              winhighlight = 'Normal:NoicePopupBackground,FloatBorder:NoicePopupBorder',
            },
          },
          notify = {
            win_options = {
              winhighlight = 'Normal:NoiceNotifyBackground,FloatBorder:NoiceNotifyBorder',
            },
          },
        },
        -- https://github.com/folke/noice.nvim/wiki/Configuration-Recipes#presets
        presets = {
          bottom_search = true,
          command_palette = true,
          long_message_to_split = true,
          lsp_doc_border = true,
        },
      })
    end,
  },

  -- Aerial | A fast and lightweight alternative to the built-in LSP symbols
  -- https://github.com/stevearc/aerial.nvim
  {
    'stevearc/aerial.nvim',
    event = 'VeryLazy',
    dependencies = {
      'nvim-treesitter/nvim-treesitter',
      'nvim-tree/nvim-web-devicons',
    },
    opts = function(_, opts)
      local kind_filter = {
        default = {
          'Class',
          'Constructor',
          'Enum',
          'Field',
          'Function',
          'Interface',
          'Method',
          'Module',
          'Namespace',
          'Package',
          'Property',
          'Struct',
          'Trait',
        },
        markdown = false,
        help = false,
        -- you can specify a different filter for each filetype
        lua = {
          'Class',
          'Constructor',
          'Enum',
          'Field',
          'Function',
          'Interface',
          'Method',
          'Module',
          'Namespace',
          -- 'Package', -- remove package since luals uses it for control flow structures
          'Property',
          'Struct',
          'Trait',
        },
      }
      local icons = vim.deepcopy(icons.kinds)

      -- HACK: fix lua's weird choice for `Package` for control
      -- structures like if/else/for/etc.
      icons.lua = { Package = icons.Control }

      --- @type table<string, string[]>|false
      local filter_kind = false
      if kind_filter then
        filter_kind = assert(vim.deepcopy(kind_filter))
        filter_kind._ = filter_kind.default
        filter_kind.default = nil
      end

      return vim.tbl_deep_extend('force', opts or {}, {
        attach_mode = 'global',
        backends = { 'lsp', 'treesitter', 'markdown', 'man' },
        show_guides = true,
        layout = {
          resize_to_content = false,
          win_opts = {
            winhl = 'Normal:NormalFloat,FloatBorder:NormalFloat,SignColumn:SignColumnSB',
            signcolumn = 'yes',
            statuscolumn = ' ',
          },
        },
        icons = icons,
        filter_kind = filter_kind,
        -- stylua: ignore
        guides = {
          mid_item   = '├╴',
          last_item  = '└╴',
          nested_top = '│ ',
          whitespace = '  ',
        },
      })
    end,
  },

  -- Lualine | Blazing fast and easy to configure statusline written in pure lua
  -- https://github.com/nvim-lualine/lualine.nvim
  {
    'nvim-lualine/lualine.nvim',
    event = 'VeryLazy',
    opts = function(_, opts)
      -- Lualine has the following sections. Each section has components.
      -- +-------------------------------------------------+
      -- | A | B | C                             X | Y | Z |
      -- +-------------------------------------------------+
      vim.o.laststatus = vim.g.lualine_laststatus
      return vim.tbl_deep_extend('force', opts or {}, {
        options = {
          theme = 'auto',
          globalstatus = vim.o.laststatus == 3,
          disabled_filetypes = { statusline = { 'dashboard', 'alpha', 'ministarter', 'snacks_dashboard' } },
          section_separators = { left = '', right = '' },
          component_separators = { left = '', right = '' },
        },
        sections = {
          lualine_a = {
            {
              'mode',
              fmt = function(str)
                return str:sub(1, 1) .. ' '
              end,
            },
          },
          lualine_b = {
            'branch',
          },
          lualine_c = {
            statusline.sessions.lualine_c.root_basename,
            statusline.sessions.lualine_c.diagnostics,
            {
              'filetype',
              icon_only = true,
              separator = '',
              padding = { left = 1, right = 0 },
              on_click = function()
                vim.cmd('FileTypes')
              end,
            },
            { 'filename' },
            {
              'aerial',
              sep = ' ',     -- separator between symbols
              sep_icon = '', -- separator between icon and symbol

              -- The number of symbols to render top-down. In order to render only 'N' last
              -- symbols, negative numbers may be supplied. For instance, 'depth = -1' can
              -- be used in order to render only current symbol.
              depth = 5,

              -- When 'dense' mode is on, icons are not rendered near their symbols. Only
              -- a single icon that represents the kind of current symbol is rendered at
              -- the beginning of status line.
              dense = false,

              -- The separator to be used to separate symbols in dense mode.
              dense_sep = '.',

              -- Color the symbol icons.
              colored = true,
              on_click = function()
                Snacks.picker.lsp_symbols({ layout = 'dropdown', enter = true, focus = 'list' })
              end,
            },
          },
          lualine_x = {
            Snacks.profiler.status(),
            statusline.sessions.lualine_x.formatters,
            statusline.sessions.lualine_x.copilot,
            statusline.sessions.lualine_x.message,
            statusline.sessions.lualine_x.history,
            statusline.sessions.lualine_x.dap,
            statusline.sessions.lualine_x.lazy,
            statusline.sessions.lualine_x.diff,
          },
          lualine_y = {
            { 'progress', separator = ' ',                  padding = { left = 1, right = 0 } },
            { 'location', padding = { left = 0, right = 1 } },
          },
          lualine_z = {
            statusline.sessions.lualine_z.time,
          },
        },
        extensions = { 'neo-tree', 'lazy', 'fzf' },
      })
    end,
  },

  -- Improve viewing Markdown files in Neovim
  -- https://github.com/MeanderingProgrammer/render-markdown.nvim?tab=readme-ov-file | https://youtu.be/AAkrmfkC1L4?t=167
  {
    'MeanderingProgrammer/render-markdown.nvim',
    dependencies = { 'nvim-treesitter/nvim-treesitter', 'echasnovski/mini.icons' }, -- if you use standalone mini plugins
    opts = function(_, opts)
      return vim.tbl_deep_extend('force', opts or {}, {
        latex = { enabled = false },
        completions = {
          blink = { enabled = true },
          lsp = { enabled = true },
        },
      })
    end,
  },

  -- URL detection and opening functionality
  -- https://github.com/sontungexpt/url-open
  {
    'sontungexpt/url-open',
    event = 'VeryLazy',
    cmd = "URLOpenUnderCursor",
    keys = {
      -- Map <D-LeftMouse> (Cmd+Click on macOS, Super+Click elsewhere) to open URL under cursor in normal mode
      {
        '<D-LeftMouse>',
        '<ESC>:URLOpenUnderCursor<CR>',
        mode = 'n',
        desc = 'Open URL under cursor (Cmd+Click)',
      },
    },
    opts = {
      -- Highlight all URLs in the buffer
      highlight = {
        enabled = true,
        -- Custom highlight group for URLs
        hl_group = 'UrlOpenHighlight',
      },
      -- Auto-detect URLs on buffer load and text change
      auto_detect = true,
      -- File types where URL detection should be enabled
      file_types = {
        'markdown',
        'text',
        'gitcommit',
        'help',
        'lua',
        'vim',
        'javascript',
        'typescript',
        'python',
        'go',
        'rust',
        'java',
        'c',
        'cpp',
        'html',
        'css',
        'json',
        'yaml',
        'toml',
        'ini',
        'conf',
        'config',
        'readme',
        'md',
        'txt',
        'log',
        'diff',
        'patch',
      },
      -- default will open url with default browser of your system or you can choose your browser like this
      -- open_app = "micorsoft-edge-stable",
      -- google-chrome, firefox, micorsoft-edge-stable, opera, brave, vivaldi
      open_app = "default",
      -- If true, only open the URL when the cursor is in the middle of the URL.
      -- If false, open the next URL found from the cursor position,
      -- which means you can open a URL even when the cursor is in front of the URL or in the middle of the URL.
      open_only_when_cursor_on_url = false,
      highlight_url = {
        all_urls = {
          enabled = true,
          fg = "#FFC395", -- "text" or "#rrggbb"
          -- fg = "text", -- text will set underline same color with text
          bg = nil,       -- nil or "#rrggbb"
          underline = false,
        },
        cursor_move = {
          enabled = true,
          fg = "#ff9e64", -- "text" or "#rrggbb"
          -- fg = "text", -- text will set underline same color with text
          bg = nil,       -- nil or "#rrggbb"
          underline = true,
          bold = true,
        },
      },
      -- deep_pattern = false,
      -- a list of patterns to open url under cursor
      patterns = {
        -- Standard HTTP/HTTPS URLs
        'https?://[%w%-%.]+[%w%-%.%?%#%&%/%+%=%~%@%:%,%;%!%_]*',
        -- URLs without protocol (www.example.com)
        'www%.[%w%-%.]+[%w%-%.%?%#%&%/%+%=%~%@%:%,%;%!%_]*',
        -- Email addresses
        '[%w%._%+-]+@[%w%-%.]+[%w%-%.]*',
        -- File paths (optional, can be disabled if too aggressive)
        -- '[%w%-%./]+[%w%-%.]+',
      },
      -- a list of patterns to open url under cursor
      extra_patterns = {
        {
          -- so the url will be https://www.npmjs.com/package/[pattern_found]
          pattern = '["]([^%s]*)["]:%s*"[^"]*%d[%d%.]*"',
          prefix = "https://www.npmjs.com/package/",
          suffix = "",
          file_patterns = { "package%.json" },
          excluded_file_patterns = nil,
          extra_condition = function(pattern_found)
            return not vim.tbl_contains({ "version", "proxy" }, pattern_found)
          end,
        },
        {
          -- so the url will be https://www.npmjs.com/package/[pattern_found]/issues
          pattern = '["]([^%s]*)["]:%s*"[^"]*%d[%d%.]*"',
          prefix = "https://www.npmjs.com/package/",
          suffix = "/issues",
          file_patterns = { "package%.json" },
          excluded_file_patterns = nil,
          extra_condition = function(pattern_found)
            return not vim.tbl_contains({ "version", "proxy" }, pattern_found)
          end,
        },
      },
    }
  },

  -- SHOWKEYS - Minimal Eye-candy keys screencaster for Neovim 200 ~ LOC | https://github.com/nvzone/showkeys
  -- https://youtu.be/E4qXZv34NQQ?si=612rj4bmIUpgnsDw&t=203
  {
    'nvzone/showkeys',
    cmd = 'ShowkeysToggle',
    event = 'VeryLazy',
    -- Called during startup, plugins' configurations typically is set in an init function
    init = function()
      vim.cmd('ShowkeysToggle')
    end,
    opts = function(_, opts)
      return vim.tbl_deep_extend('force', opts, {
        winhl = 'FloatBorder:Comment,Normal:Normal',
        maxkeys = 3,
        show_count = true,
        keyformat = {
          ['<BS>'] = '󰁮 ',
          ['<C>'] = '⌃',
          ['<CR>'] = '↵',
          ['<D>'] = '⌘',
          ['<Del>'] = '⌦',
          ['<DEL>'] = '⌦',
          ['<Down>'] = '↓',
          ['<End>'] = '⇲',
          ['<END>'] = '⇲',
          ['<Enter>'] = '↵',
          ['<ENTER>'] = '↵',
          ['<Esc>'] = '⎋',
          ['<ESC>'] = '⎋',
          ['<Home>'] = '⇱',
          ['<HOME>'] = '⇱',
          ['<Left>'] = '←',
          ['<M>'] = '⌥',
          ['<Return>'] = '⏎',
          ['<RETURN>'] = '⏎',
          ['<Right>'] = '→',
          ['<S>'] = '⇧',
          ['<Space>'] = '␣',
          ['<SPACE>'] = '␣',
          ['<SPC>'] = '␣',
          ['<Tab>'] = '⇥',
          ['<TAB>'] = '⇥',
          ['<Up>'] = '↑',
          ['<PageUp>'] = '⇞',
          ['<PageDown>'] = '⇟',
        },
      })
    end,
  }
}
