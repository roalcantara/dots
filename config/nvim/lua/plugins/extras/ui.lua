return {
  -- TOKYONIGHT | A clean, dark Neovim theme written in Lua, with support for lsp, treesitter and lots of plugins.
  -- https://github.com/folke/tokyonight.nvim
  {
    'folke/tokyonight.nvim',
    opts = function(_, opts)
      -- The theme comes in three styles, `storm`, a darker variant `night` and `day`
      -- https://github.com/folke/tokyonight.nvim/blob/main/extras/lua/tokyonight_storm.lua
      return vim.tbl_deep_extend('force', opts, {
        style = 'storm',
      })
    end,
  },

  {
    "akinsho/bufferline.nvim",
    opts = {
      options = {
        -- stylua: ignore
        close_command = function(n) Snacks.bufdelete(n) end,
        -- stylua: ignore
        right_mouse_command = function(n) Snacks.bufdelete(n) end,
        diagnostics = "nvim_lsp",
        always_show_bufferline = false,
        diagnostics_indicator = function(_, _, diag)
          local icons = LazyVim.config.icons.diagnostics
          local ret = (diag.error and icons.Error .. diag.error .. " " or "")
              .. (diag.warning and icons.Warn .. diag.warning or "")
          return vim.trim(ret)
        end,
        offsets = {
          {
            filetype = "neo-tree",
            text = "Neo-tree",
            highlight = "Directory",
            text_align = "left",
          },
          {
            filetype = "snacks_layout_box",
          },
        },
        get_element_icon = function(opts)
          return LazyVim.config.icons.ft[opts.filetype]
        end,
      },
    }
  },

  -- MINI.ICONS | Icon provider for neovim. Part of 'mini.nvim' library.
  -- https://github.com/echasnovski/mini.icons
  {
    'echasnovski/mini.icons',
    version = '*',
    opts = {
      -- Style of general icon (for non-file icon)
      style = 'glyph',
    },
  },

  -- NVIM-LUALINE | A blazing fast and easy to configure neovim statusline plugin written in Lua
  -- https://github.com/nvim-lualine/lualine.nvim
  {
    'nvim-lualine/lualine.nvim',
    dependencies = {
      'echasnovski/mini.icons', -- optional, for file icons
    },
    opts = {
      theme = 'tokyonight-storm',
    },
  },

  -- TREESITTER | A tree-sitter based parser and syntax highlighter for Neovim
  -- https://github.com/nvim-treesitter/nvim-treesitter
  -- https://lazyvim.org/plugins/treesitter#nvim-treesitter
  {
    'nvim-treesitter/nvim-treesitter',
    version = false,
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = {
      "nvim-treesitter/nvim-treesitter-textobjects",
    },
    opts = function(_, opts)
      return require("nvim-treesitter.configs").setup({
        sync_install = false,
        ignore_install = { "javascript" },
        modules = {},
        highlight = {
          enable = true,
          additional_vim_regex_highlighting = false,
        },
        indent = { enable = true },
        auto_install = true,
        ensure_installed = {
          'dockerfile',
          'ghostty',
          'git_config',
          'git_rebase',
          'gitattributes',
          'gitcommit',
          'gitignore',
          "bash",
          "c",
          "go",
          "gomod",
          "gosum",
          "gowork",
          "html",
          "javascript",
          "json",
          "lua",
          "luadoc",
          "luap",
          "query",
          "regex",
          "rust",
          "vim",
          "vimdoc",
          "yaml",
        },
        incremental_selection = {
          enable = true,
          keymaps = {
            init_selection = "<leader>vv",
            node_incremental = "+",
            scope_incremental = false,
            node_decremental = "_",
          },
        },
        textobjects = {
          select = {
            enable = true,
            lookahead = true,

            keymaps = {
              -- You can use the capture groups defined in textobjects.scm
              ["af"] = { query = "@function.outer", desc = "around a function" },
              ["if"] = { query = "@function.inner", desc = "inner part of a function" },
              ["ac"] = { query = "@class.outer", desc = "around a class" },
              ["ic"] = { query = "@class.inner", desc = "inner part of a class" },
              ["ai"] = { query = "@conditional.outer", desc = "around an if statement" },
              ["ii"] = { query = "@conditional.inner", desc = "inner part of an if statement" },
              ["al"] = { query = "@loop.outer", desc = "around a loop" },
              ["il"] = { query = "@loop.inner", desc = "inner part of a loop" },
              ["ap"] = { query = "@parameter.outer", desc = "around parameter" },
              ["ip"] = { query = "@parameter.inner", desc = "inside a parameter" },
            },
            selection_modes = {
              ["@parameter.outer"] = "v",   -- charwise
              ["@parameter.inner"] = "v",   -- charwise
              ["@function.outer"] = "v",    -- charwise
              ["@conditional.outer"] = "V", -- linewise
              ["@loop.outer"] = "V",        -- linewise
              ["@class.outer"] = "<c-v>",   -- blockwise
            },
            include_surrounding_whitespace = false,
          },
          move = {
            enable = true,
            set_jumps = true, -- whether to set jumps in the jumplist
            goto_previous_start = {
              ["[f"] = { query = "@function.outer", desc = "Previous function" },
              ["[c"] = { query = "@class.outer", desc = "Previous class" },
              ["[p"] = { query = "@parameter.inner", desc = "Previous parameter" },
            },
            goto_next_start = {
              ["]f"] = { query = "@function.outer", desc = "Next function" },
              ["]c"] = { query = "@class.outer", desc = "Next class" },
              ["]p"] = { query = "@parameter.inner", desc = "Next parameter" },
            },
          },
          swap = {
            enable = true,
            swap_next = {
              ["<leader>a"] = "@parameter.inner",
            },
            swap_previous = {
              ["<leader>A"] = "@parameter.inner",
            },
          },
        },
      })
      -- return vim.tbl_deep_extend('force', opts or {}, {
      --   ensure_installed = vim.tbl_deep_extend('force', opts.ensure_installed or {}, {
      --     'lua',
      --     'css',
      --     'dockerfile',
      --     'ghostty',
      --     'git_config',
      --     'git_rebase',
      --     'gitattributes',
      --     'gitcommit',
      --     'gitignore',
      --     'go',
      --     'gomod',
      --     'gosum',
      --     'gotmpl',
      --     'ini',
      --     'make',
      --     'ruby',
      --     'scss',
      --     'xml',
      --   }),
      --   sync_installed = true,
      --   highlight = vim.tbl_deep_extend('force', opts.highlight or {}, {
      --     enable = true,
      --   }),
      --   indent = vim.tbl_deep_extend('force', opts.indent or {}, {
      --     enable = true,
      --   }),
      -- })
    end,
  },

  -- MINI.AI | Neovim Lua plugin to extend and create `a`/`i` textobjects. Part of 'mini.nvim' library.
  -- https://github.com/echasnovski/mini.ai
  {
    'echasnovski/mini.ai',
    opts = function()
      local ai = require("mini.ai")
      return {
        n_lines = 500,
        custom_textobjects = {
          o = ai.gen_spec.treesitter({ -- code block
            a = { "@block.outer", "@conditional.outer", "@loop.outer" },
            i = { "@block.inner", "@conditional.inner", "@loop.inner" },
          }),
          f = ai.gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }), -- function
          c = ai.gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" }),       -- class
          t = { "<([%p%w]-)%f[^<%w][^<>]->.-</%1>", "^<.->().*()</[^/]->$" },           -- tags
          d = { "%f[%d]%d+" },                                                          -- digits
          e = {                                                                         -- Word with case
            { "%u[%l%d]+%f[^%l%d]", "%f[%S][%l%d]+%f[^%l%d]", "%f[%P][%l%d]+%f[^%l%d]", "^[%l%d]+%f[^%l%d]" },
            "^().*()$",
          },
          g = LazyVim.mini.ai_buffer,                                -- buffer
          u = ai.gen_spec.function_call(),                           -- u for "Usage"
          U = ai.gen_spec.function_call({ name_pattern = "[%w_]" }), -- without dot in function name
        },
      }
    end
  },

  { "tpope/vim-sleuth" },

  -- MINI.PAIRS | https://github.com/echasnovski/mini.pairs
  -- Neovim Lua plugin to automatically manage character pairs. Part of 'mini.nvim' library.
  {
    'echasnovski/mini.pairs',
    opts = {
      modes = { insert = true, command = true, terminal = false },
      -- skip autopair when next character is one of these
      skip_next = [=[[%w%%%'%[%"%.%`%$]]=],
      -- skip autopair when the cursor is inside these treesitter nodes
      skip_ts = { 'string' },
      -- skip autopair when next character is closing pair
      -- and there are more closing pairs than opening pairs
      skip_unbalanced = true,
      -- better deal with markdown code blocks
      markdown = true,
    },
  },

  -- MINI.ICONS | Icon provider for neovim. Part of 'mini.nvim' library.
  -- https://github.com/echasnovski/mini.icons
  {
    'echasnovski/mini.icons',
    opts = {
      file = {
        [".keep"] = { glyph = "󰊢", hl = "MiniIconsGrey" },
        ["devcontainer.json"] = { glyph = "", hl = "MiniIconsAzure" },
      },
      filetype = {
        dotenv = { glyph = "", hl = "MiniIconsYellow" },
      },
    },
  },

  -- MINI.SURROUND | Fast and feature-rich surround actions. Part of 'mini.nvim' library.
  -- https://github.com/echasnovski/mini.surround
  {
    'echasnovski/mini.surround',
    opts = {
      mappings = {
        add = 'sa',            -- Add surrounding in Normal and Visual modes
        delete = 'sd',         -- Delete surrounding
        find = 'sf',           -- Find surrounding (to the right)
        find_left = 'sF',      -- Find surrounding (to the left)
        highlight = 'sh',      -- Highlight surrounding
        replace = 'sr',        -- Replace surrounding
        update_n_lines = 'sn', -- Update `n_lines`
      }
    },
  },

  -- MINI.INDENTSCOPE | Visualize and work with indent scope. Part of 'mini.nvim' library.
  -- https://github.com/echasnovski/mini.indentscope
  -- {
  --   'echasnovski/mini.indentscope',
  --   version = '*',
  --   opts = {
  --     -- Draw options
  --     draw = {
  --       -- Delay (in ms) between event and start of drawing scope indicator
  --       delay = 100,
  --       -- Animation rule for scope's first drawing. A function which, given
  --       -- next and total step numbers, returns wait time (in ms). See
  --       -- |MiniIndentscope.gen_animation| for builtin options. To disable
  --       -- animation, use `require('mini.indentscope').gen_animation.none()`.
  --       animation = function() require('mini.indentscope').gen_animation.none() end,
  --       -- Symbol priority. Increase to display on top of more symbols.
  --       priority = 2,
  --     },
  --     -- Module mappings. Use `''` (empty string) to disable one.
  --     mappings = {
  --       -- Textobjects
  --       object_scope = 'ii',
  --       object_scope_with_border = 'ai',
  --       -- Motions (jump to respective border line; if not present - body line)
  --       goto_top = '[i',
  --       goto_bottom = ']i',
  --     },
  --     -- Options which control scope computation
  --     options = {
  --       -- Type of scope's border: which line(s) with smaller indent to
  --       -- categorize as border. Can be one of: 'both', 'top', 'bottom', 'none'.
  --       border = 'both',
  --       -- Whether to use cursor column when computing reference indent.
  --       -- Useful to see incremental scopes with horizontal cursor movements.
  --       indent_at_cursor = true,
  --       -- Whether to first check input line to be a border of adjacent scope.
  --       -- Use it if you want to place cursor on function header to get scope of
  --       -- its body.
  --       try_as_border = false,
  --     },
  --     -- Which character to use for drawing scope indicator
  --     symbol = '│',
  --   },
  -- },

  -- -- -- MINI.DIFF | Work with diff hunks. Part of 'mini.nvim' library.
  -- -- -- https://github.com/echasnovski/mini.diff
  -- -- {
  -- --   'echasnovski/mini.diff',
  -- --   version = '*',
  -- --   opts = {
  -- --     -- Options for how hunks are visualized
  -- --     view = {
  -- --       -- Visualization style. Possible values are 'sign' and 'number'.
  -- --       -- Default: 'number' if line numbers are enabled, 'sign' otherwise.
  -- --       style = 'sign',
  -- --       -- Signs used for hunks with 'sign' view
  -- --       signs = {
  -- --         add = '▎',
  -- --         change = '▎',
  -- --         delete = '',
  -- --       },
  -- --       -- Priority of used visualization extmarks
  -- --       priority = 199,
  -- --     },
  -- --     -- Source for how reference text is computed (what text is considered
  -- --     -- to be the source of truth to compare with). Should be one of:
  -- --     -- - 'git' - use Git index as reference text
  -- --     -- - 'file' - use current state of file as reference text
  -- --     source = 'git',
  -- --     -- Delays (in ms) defining asynchronous processes
  -- --     delay = {
  -- --       -- How much to wait before update after every text change
  -- --       text_change = 200,
  -- --     },
  -- --     -- Module mappings. Use `''` (empty string) to disable one.
  -- --     mappings = {
  -- --       -- Apply hunks inside a visual/operator region
  -- --       apply = 'gh',
  -- --       -- Reset hunks inside a visual/operator region
  -- --       reset = 'gH',
  -- --       -- Hunk range textobject to be used inside operator
  -- --       textobject = 'gh',
  -- --       -- Go to hunk range in corresponding direction
  -- --       goto_first = '[H',
  -- --       goto_prev = '[h',
  -- --       goto_next = ']h',
  -- --       goto_last = ']H',
  -- --     },
  -- --   },
  -- -- },

  -- -- -- MINI.TABLINE | Minimal and fast tabline. Part of 'mini.nvim' library.
  -- -- -- https://github.com/echasnovski/mini.tabline
  -- -- {
  -- --   'echasnovski/mini.tabline',
  -- --   version = '*',
  -- --   opts = {
  -- --     -- Whether to show file icons (requires 'mini.icons')
  -- --     show_icons = true,
  -- --     -- Function which formats the tab label
  -- --     -- By default surrounds with space and possibly prepends with icon
  -- --     format = nil,
  -- --     -- Whether to set Vim's settings for tabline (make it always shown and
  -- --     -- allow hidden buffers)
  -- --     set_vim_settings = true,
  -- --     -- Where to show tabline in case of single tab
  -- --     tabpage_section = 'left',
  -- --   },
  -- -- },

  -- -- MINI.NOTIFY | Show notifications. Part of 'mini.nvim' library.
  -- -- https://github.com/echasnovski/mini.notify
  -- {
  --   'echasnovski/mini.notify',
  --   version = '*',
  --   opts = {
  --     -- Content management
  --     content = {
  --       -- Function which formats the notification message
  --       -- By default prepends message with notification time
  --       format = nil,
  --       -- Function which sorts notifications with identical timestamp
  --       -- By default sorts by message text
  --       sort = nil,
  --     },
  --     -- Notifications about LSP progress
  --     lsp_progress = {
  --       -- Whether to enable showing
  --       enable = true,
  --       -- Duration (in ms) of how long last message should be shown
  --       duration_last = 1000,
  --     },
  --     -- Window options
  --     window = {
  --       -- Floating window config
  --       config = {},
  --       -- Maximum window width as share (between 0 and 1) of available columns
  --       max_width_share = 0.382,
  --       -- Value of 'winblend' option
  --       winblend = 25,
  --     },
  --   },
  --   config = function(_, opts)
  --     require('mini.notify').setup(opts)
  --     vim.notify = require('mini.notify').make_notify()
  --   end,
  -- },

  -- TWILIGHT | Twilight is a Lua plugin for Neovim 0.5 that dims inactive portions of the code you're editing
  -- https://github.com/folke/twilight.nvim
  {
    'folke/twilight.nvim',
    opts = {
      dimming = {
        alpha = 0.25,
        color = { "Normal", "#ffffff" },
        term_bg = "#000000",
        inactive = false,
      },
      context = 10,
      treesitter = true,
      expand = {
        "function",
        "method",
        "table",
        "if_statement",
      },
      exclude = {},
    },
  },

  -- FIDGET | Extensible UI for Neovim notifications and LSP progress messages (VSCode-like LSP progress indicator)
  -- https://github.com/j-hui/fidget.nvim
  {
    'j-hui/fidget.nvim',
    tag = 'legacy',
    event = 'LspAttach',
    opts = {
      text = {
        spinner = "pipe",
        done = "✔",
        commenced = "Started",
        completed = "Completed",
      },
      align = {
        bottom = true,
        right = true,
      },
      timer = {
        spinner_rate = 125,
        fidget_decay = 2000,
        task_decay = 1000,
      },
      window = {
        relative = "win",
        blend = 100,
        zindex = nil,
        border = "none",
      },
      fmt = {
        leftpad = true,
        stack_upwards = true,
        max_width = 0,
        fidget = function(fidget_name, spinner)
          return string.format("%s %s", spinner, fidget_name)
        end,
        task = function(task_name, message, percentage)
          return string.format(
            "%s%s [%s]",
            message,
            percentage and string.format(" (%s%%)", percentage) or "",
            task_name
          )
        end,
      },
      sources = {
        ["null-ls"] = {
          ignore = true,
        },
      },
      debug = {
        logging = false,
        strict = false,
      },
    },
  },

  -- Automatically add closing tags for HTML and JSX
  -- https://github.com/windwp/nvim-ts-autotag
  'windwp/nvim-ts-autotag',

  -- NVIM-COLORIZER | High-performance color highlighter (VSCode-like color preview)
  -- https://github.com/norcalli/nvim-colorizer.lua?tab=readme-ov-file#installation-and-usage
  {
    'norcalli/nvim-colorizer.lua',
    opts = {
      filetypes = { "*" },
      user_default_options = {
        RGB = true,
        RRGGBB = true,
        names = true,
        RRGGBBAA = false,
        AARRGGBB = false,
        rgb_fn = false,
        hsl_fn = false,
        css = false,
        css_fn = false,
        mode = "background",
        tailwind = false,
        sass = { enable = false, parsers = { "css" } },
        virtualtext = "■",
      },
      buftypes = {},
    },
  },

  -- SNACKS | A modern UI library for Neovim | https://github.com/folke/snacks.nvim
  -- https://lazyvim.org/extras/editor/snacks_picker#snacksnvim-1
  {
    'snacks.nvim',
    opts = function(_, opts)
      return vim.tbl_deep_extend('force', opts or {}, {
        dashboard = {
          enabled = true,
          preset = {
            pick = function(cmd, opts)
              return LazyVim.pick(cmd, opts)()
            end,
            header = require('core/extra/ui/dashboard_helper').header(),
            keys = {
              { icon = "󰀶 ", key = "s", desc = "Smart Find Files", action = ":lua Snacks.picker.smart({})" },
              { icon = " ", key = "f", desc = "Find File", action = ':lua Snacks.dashboard.pick("files")' },
              { icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
              { icon = " ", key = "g", desc = "Find Text", action = ':lua Snacks.dashboard.pick("live_grep")' },
              { icon = " ", key = "r", desc = "Recent Files", action = ':lua Snacks.dashboard.pick("oldfiles")' },
              {
                icon = " ",
                key = "c",
                desc = "Config",
                action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})",
              },
              { icon = " ", key = "x", desc = "Lazy Extras", action = ":LazyExtras" },
              { icon = "󰒲 ", key = "l", desc = "Lazy", action = ":Lazy" },
              { icon = " ", key = "q", desc = "Quit", action = ":qa" },
            },
          },
        },
      })
    end,
  },

  -- -- SHOWKEYS - Minimal Eye-candy keys screencaster for Neovim 200 ~ LOC | https://github.com/nvzone/showkeys
  -- -- https://youtu.be/E4qXZv34NQQ?si=612rj4bmIUpgnsDw&t=203
  -- {
  --   'nvzone/showkeys',
  --   cmd = 'ShowkeysToggle',
  --   event = 'VeryLazy',
  --   -- Called during startup, plugins' configurations typically is set in an init function
  --   init = function()
  --     vim.cmd('ShowkeysToggle')
  --   end,
  --   opts = function(_, opts)
  --     return vim.tbl_deep_extend('force', opts, {
  --       winhl = 'FloatBorder:Comment,Normal:Normal',
  --       maxkeys = 3,
  --       show_count = true,
  --       keyformat = {
  --         ['<BS>'] = '󰁮 ',
  --         ['<C>'] = '⌃',
  --         ['<CR>'] = '↵',
  --         ['<D>'] = '⌘',
  --         ['<Del>'] = '⌦',
  --         ['<DEL>'] = '⌦',
  --         ['<Down>'] = '↓',
  --         ['<End>'] = '⇲',
  --         ['<END>'] = '⇲',
  --         ['<Enter>'] = '↵',
  --         ['<ENTER>'] = '↵',
  --         ['<Esc>'] = '⎋',
  --         ['<ESC>'] = '⎋',
  --         ['<Home>'] = '⇱',
  --         ['<HOME>'] = '⇱',
  --         ['<Left>'] = '←',
  --         ['<M>'] = '⌥',
  --         ['<Return>'] = '⏎',
  --         ['<RETURN>'] = '⏎',
  --         ['<Right>'] = '→',
  --         ['<S>'] = '⇧',
  --         ['<Space>'] = '␣',
  --         ['<SPACE>'] = '␣',
  --         ['<SPC>'] = '␣',
  --         ['<Tab>'] = '⇥',
  --         ['<TAB>'] = '⇥',
  --         ['<Up>'] = '↑',
  --         ['<PageUp>'] = '⇞',
  --         ['<PageDown>'] = '⇟',
  --       },
  --     })
  --   end,
  -- },

  -- GHOSTTY - A ghostty plugin for Neovim
  -- https://github.com/isak102/ghostty.nvim
  {
    'isak102/ghostty.nvim',
    -- cond = paths.is_executable('ghostty'),
    opts = {
      -- The autocmd pattern matched against the filename of the buffer. If this pattern
      -- matches, ghostty.nvim will run on save in that buffer. This pattern is passed to
      -- nvim_create_autocmd, check `:h autocmd-pattern` for more information. Can be
      -- either a string or a list of strings
      -- file_pattern = vim.fn.expand(paths.to_xdg_config_home({ 'ghostty', 'config' })),
      -- The ghostty executable to run.
      ghostty_cmd = 'ghostty',
      -- The timeout in milliseconds for the check command.
      -- If the command takes longer than this it will be killed.
      check_timeout = 1000,
    },
  },

  -- TREE-SITTER-GHOSTTY - A tree-sitter parser for ghostty
  -- https://github.com/bezhermoso/tree-sitter-ghostty
  {
    'bezhermoso/tree-sitter-ghostty',
    build = 'make nvim_install',
    -- cond = paths.is_executable('ghostty'),
  },
}
