return {
  {
    'folke/tokyonight.nvim',
    lazy = false, -- make sure we load this during startup if it is your main colorscheme
    priority = 1000,
    opts = {
      transparent = true,
      styles = {
        floats = 'normal'
      }
    },
    config = function(_, opts)
      require('tokyonight').setup(opts)
      vim.cmd.colorscheme('tokyonight-moon')
      vim.cmd(':hi statusline guibg=NONE')
      vim.api.nvim_set_hl(0, 'BlinkCmpMenu', { bg = '#1a1b2e' })                       -- Darker menu bg
      vim.api.nvim_set_hl(0, 'BlinkCmpMenuBorder', { bg = '#1a1b2e', fg = '#364a82' }) -- Match border
      vim.api.nvim_set_hl(0, 'BlinkCmpMenuSelection', { bg = '#2d3f76' })              -- Selection highlight
      vim.api.nvim_set_hl(0, 'BlinkCmpGhostText', { fg = '#737AA2' })                  -- Label foreground color

      -- Configure BlinkCmpLabelMatch to only have bold style (no foreground color)
      -- This improves the colorful-menu.nvim appearance
      vim.api.nvim_set_hl(0, 'BlinkCmpLabelMatch', { bold = true })
    end
  },

  -- Treesitter is a new parser generator tool that we can
  -- use in Neovim to power faster and more accurate syntax highlighting.
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
    dependencies = {
      'nvim-treesitter/nvim-treesitter-textobjects',
    },
    opts = {
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
        'html',
        'ini',
        'javascript',
        'jsdoc',
        'json',
        'jsonc',
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
        'go',
        'gomod',
        'gosum',
        'gowork',
      },
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = '<leader>vv',
          node_incremental = '+',
          scope_incremental = false,
          node_decremental = '_',
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
      require('nvim-treesitter.configs').setup(opts)
    end,
  },

  {
    'nvim-treesitter/nvim-treesitter-textobjects',
    event = 'VeryLazy',
    enabled = true,
    config = function()
      local lazy = require('core/vi/plugins')
      -- If treesitter is already loaded, we need to run config again for textobjects
      if lazy.is_loaded('nvim-treesitter') then
        local opts = lazy.opts('nvim-treesitter')
        require('nvim-treesitter.configs').setup({ textobjects = opts.textobjects })
      end

      -- When in diff mode, we want to use the default
      -- vim text objects c & C instead of the treesitter ones.
      local move = require('nvim-treesitter.textobjects.move') --- @type table<string,fun(...)>
      local configs = require('nvim-treesitter.configs')
      for name, fn in pairs(move) do
        if name:find('goto') == 1 then
          move[name] = function(q, ...)
            if vim.wo.diff then
              local config = configs.get_module('textobjects.move')[name] --- @type table<string,string>
              for key, query in pairs(config or {}) do
                if q == query and key:find('[%]%[][cC]') then
                  vim.cmd('normal! ' .. key)
                  return
                end
              end
            end
            return fn(q, ...)
          end
        end
      end
    end,
  },

  -- Helpview | A modern UI for Neovim's help system
  -- The plugin should be loaded after your colorscheme to ensure the correct highlight groups are used
  -- https://github.com/OXY2DEV/helpview.nvim
  {
    "OXY2DEV/helpview.nvim",
    lazy = false,
    opts = {},
  },

  -- Automatically add closing tags for HTML and JSX
  {
    'windwp/nvim-ts-autotag',
    event = 'VeryLazy',
    opts = {},
  },

  -- SNACKS | A modern UI library for Neovim | https://github.com/folke/snacks.nvim
  -- https://lazyvim.org/extras/editor/snacks_picker#snacksnvim-1
  {
    'folke/snacks.nvim',
    priority = 1000,
    lazy = false,
    opts = function(_, opts)
      local snacks_default_exclusions = require('core/ui/snacks/defaults').default_exclusions
      return vim.tbl_deep_extend('force', opts or {}, {
        dashboard = {
          enabled = true,
          open_on_startup = true,
          preset = {
            header = require('core/ui/snacks/dashboard').header(),
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
                ["source"] = {
                  '<D-CR>',
                  function(self)
                    local name = "scratch." .. vim.fn.fnamemodify(vim.api.nvim_buf_get_name(self.buf), ":e")
                    Snacks.debug.run({ buf = self.buf, name = name })
                  end,
                  desc = "Source buffer",
                  mode = { "n", "x" },
                },
              },
            },
          },
        },
        -- Smooth scrolling for Neovim. Properly handles scrolloff and mouse scrolling.
        -- https://github.com/folke/snacks.nvim/blob/main/docs/scroll.md
        scroll = { enabled = true },
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
          win = {
            input = {
              keys = {
                s = 'flash',
                ['<A-s>'] = { 'flash', mode = { 'n', 'i' } }
              },
            },
          },
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
      'MunifTanjim/nui.nvim'
    },
    opts = function(_, opts)
      return vim.tbl_deep_extend('force', opts or {}, {
        -- https://github.com/folke/noice.nvim/wiki/A-Guide-to-Messages#lsp-messages
        lsp = {
          override = {
            ['vim.lsp.util.convert_input_to_markdown_lines'] = true,
            ['vim.lsp.util.stylize_markdown'] = true
          },
          hover = {
            enable = false
          },
          signature = {
            enabled = true,
          },
          documentation = {
            enabled = true,
          }
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
              event = "msg_show",
              kind = "search_count",
            },
            opts = { skip = true },
          }
        },
        messages = {
          -- NOTE: If you enable messages, then the cmdline is enabled automatically.
          -- This is a current Neovim limitation.
          enabled = true,              -- enables the Noice messages UI
          view = "notify",             -- default view for messages
          view_error = "notify",       -- view for errors
          view_warn = "notify",        -- view for warnings
          view_history = "messages",   -- view for :messages
          view_search = "virtualtext", -- view for search count messages. Set to `false` to disable
        },
        popupmenu = {
          enabled = true,  -- enables the Noice popupmenu UI
          backend = "nui", -- backend to use to show regular cmdline completions
          -- Icons for completion item kinds (see defaults at noice.config.icons.kinds)
          kind_icons = {}, -- set to `false` to disable icons
        },
        -- default options for require('noice').redirect
        -- see the section on Command Redirection
        redirect = {
          view = "popup",
          filter = { event = "msg_show" },
        },
        -- You can add any custom commands below that will be available with `:Noice command`
        commands = {
          history = {
            -- options for the message history that you get with `:Noice`
            view = "split",
            opts = { enter = true, format = "details" },
            filter = {
              any = {
                { event = "notify" },
                { error = true },
                { warning = true },
                { event = "msg_show", kind = { "" } },
                { event = "lsp",      kind = "message" },
              },
            },
          },
          -- :Noice last
          last = {
            view = "popup",
            opts = { enter = true, format = "details" },
            filter = {
              any = {
                { event = "notify" },
                { error = true },
                { warning = true },
                { event = "msg_show", kind = { "" } },
                { event = "lsp",      kind = "message" },
              },
            },
            filter_opts = { count = 1 },
          },
          -- :Noice errors
          errors = {
            -- options for the message history that you get with `:Noice`
            view = "popup",
            opts = { enter = true, format = "details" },
            filter = { error = true },
            filter_opts = { reverse = true },
          },
          all = {
            -- options for the message history that you get with `:Noice`
            view = "split",
            opts = { enter = true, format = "details" },
            filter = {},
          },
        },
        notify = {
          enabled = true,
          view = 'notify',
        },
        -- https://github.com/folke/noice.nvim/wiki/Configuration-Recipes#presets
        presets = {
          bottom_search = true,
          command_palette = true,
          long_message_to_split = true,
          lsp_doc_border = true
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
      'nvim-tree/nvim-web-devicons'
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
      local icons = vim.deepcopy(require('core/ui/icons').kinds)

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
            winhl = "Normal:NormalFloat,FloatBorder:NormalFloat,SignColumn:SignColumnSB",
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
    end
  },

  -- Lualine | Blazing fast and easy to configure statusline written in pure lua
  -- https://github.com/nvim-lualine/lualine.nvim
  {
    'nvim-lualine/lualine.nvim',
    event = "VeryLazy",
    opts = function(_, opts)
      -- Lualine has the following sections. Each section has components.
      -- +-------------------------------------------------+
      -- | A | B | C                             X | Y | Z |
      -- +-------------------------------------------------+
      local function refresh(scope, ...)
        local places = { ... }
        if #places == 0 then
          places = { 'statusline', 'winbar', 'tabline' }
        end

        return require('lualine').refresh({
          force = true,
          scope = scope,
          place = places,
        })
      end

      -- PERF: we don't need this lualine require madness 🤷
      local lualine_require = require('lualine_require')
      lualine_require.require = require

      local icons = require('core/ui/icons')

      vim.o.laststatus = vim.g.lualine_laststatus

      return vim.tbl_deep_extend('force', opts or {}, {
        options = {
          theme = "auto",
          globalstatus = vim.o.laststatus == 3,
          disabled_filetypes = { statusline = { 'dashboard', 'alpha', 'ministarter', 'snacks_dashboard' } },
          section_separators = { left = '', right = '' },
          component_separators = { left = '', right = '' }
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
            require('core/ui/statusline').root_dir(),
            {
              'diagnostics',
              symbols = {
                error = icons.diagnostics.Error,
                warn = icons.diagnostics.Warn,
                info = icons.diagnostics.Info,
                hint = icons.diagnostics.Hint,
              },
              on_click = function()
                vim.cmd('LspToggleDiagnostics')
              end,
            },
            {
              'filetype',
              icon_only = true,
              separator = '',
              padding = { left = 1, right = 0 },
              on_click = function()
                vim.cmd('FileTypes')
              end,
            },
            { require('core/ui/statusline').pretty_path() },
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
            }
          },
          lualine_x = {
            Snacks.profiler.status(),
            require('core/ui/statusline').status(icons.kinds.Copilot, function()
              local clients = package.loaded['copilot'] and
                require('core/vi/lsp/utils').get_clients({ name = 'copilot', bufnr = 0 }) or
                {}
              if #clients > 0 then
                local status = require('copilot.api').status.data.status
                return (status == 'InProgress' and 'pending') or (status == 'Warning' and 'error') or 'ok'
              end
            end),
            -- https://github.com/folke/noice.nvim?tab=readme-ov-file#-statusline-components
            -- stylua: ignore
            {
              function() return require('noice').api.status.command.get() end,
              cond = function() return package.loaded['noice'] and require('noice').api.status.command.has() end,
              color = function() return { fg = Snacks.util.color('Statement') } end,
            },
            -- stylua: ignore
            {
              function() return require('noice').api.status.mode.get() end,
              cond = function() return package.loaded['noice'] and require('noice').api.status.mode.has() end,
              color = function() return { fg = Snacks.util.color('Constant') } end,
            },
            -- stylua: ignore
            {
              function() return require('noice').api.status.search.get() end,
              cond = function() return package.loaded['noice'] and require('noice').api.status.search.has() end,
              color = function() return { fg = Snacks.util.color('Statement') } end,
            },
            -- stylua: ignore
            {
              function() return '  ' .. require('dap').status() end,
              cond = function() return package.loaded['dap'] and require('dap').status() ~= '' end,
              color = function() return { fg = Snacks.util.color('Debug') } end,
            },
            -- stylua: ignore
            {
              require('lazy.status').updates,
              cond = require('lazy.status').has_updates,
              color = function() return { fg = Snacks.util.color('Special') } end,
              on_click = function()
                vim.schedule(function()
                  vim.cmd [[Lazy sync]]
                  refresh('window', 'statusline')
                end)
              end,
            },
            {
              'diff',
              symbols = {
                added = icons.git.added,
                modified = icons.git.modified,
                removed = icons.git.removed,
              },
              source = function()
                local gitsigns = vim.b.gitsigns_status_dict
                if gitsigns then
                  return {
                    added = gitsigns.added,
                    modified = gitsigns.changed,
                    removed = gitsigns.removed,
                  }
                end
              end,
            },
          },
          lualine_y = {
            { 'progress', separator = ' ',                  padding = { left = 1, right = 0 } },
            { 'location', padding = { left = 0, right = 1 } },
          },
          lualine_z = {
            function()
              return ' ' .. os.date('%R')
            end,
          },
        },
        extensions = { 'neo-tree', 'lazy', 'fzf' },
      })
    end,
  },

  -- WhichKey | A popup that displays possible keybindings of the command you started typing
  -- https://github.com/folke/which-key.nvim
  {
    'folke/which-key.nvim',
    event = 'VeryLazy',
    opts_extend = { 'spec' },
    opts = {
      preset = 'helix',
      defaults = {},
      spec = {
        {
          mode = { 'n', 'v' },
          { '<leader><tab>', group = 'tabs' },
          { '<leader>c', group = 'code' },
          { '<leader>d', group = 'debug' },
          { '<leader>dp', group = 'profiler' },
          { '<leader>f', group = 'file/find' },
          { '<leader>g', group = 'git' },
          { '<leader>gh', group = 'hunks' },
          { '<leader>q', group = 'quit/session' },
          { '<leader>s', group = 'search' },
          { '<leader>u', group = 'ui', icon = { icon = '󰙵 ', color = 'cyan' } },
          { '<leader>x', group = 'diagnostics/quickfix', icon = { icon = '󱖫 ', color = 'green' } },
          { '[', group = 'prev' },
          { ']', group = 'next' },
          { 'g', group = 'goto' },
          { 'gs', group = 'surround' },
          { 'z', group = 'fold' },
          {
            '<leader>b',
            group = 'buffer',
            expand = function()
              return require('which-key.extras').expand.buf()
            end,
          },
          {
            '<leader>w',
            group = 'windows',
            proxy = '<c-w>',
            expand = function()
              return require("which-key.extras").expand.win()
            end,
          },
          -- better descriptions
          { 'gx', desc = 'Open with system app' },
        },
      },
    },
    keys = {
      {
        '<leader>?',
        function()
          require('which-key').show({ global = false })
        end,
        desc = 'Buffer Keymaps (which-key)',
      },
      {
        '<c-w><space>',
        function()
          require('which-key').show({ keys = '<c-w>', loop = true })
        end,
        desc = 'Window Hydra Mode (which-key)',
      },
    },
    config = function(_, opts)
      local wk = require('which-key')
      wk.setup(opts)
      if not vim.tbl_isempty(opts.defaults) then
        Snacks.warn('which-key: opts.defaults is deprecated. Please use opts.spec instead.')
        wk.register(opts.defaults)
      end
    end,
  },

  -- Plugin to improve viewing Markdown files in Neovim
  -- https://github.com/MeanderingProgrammer/render-markdown.nvim?tab=readme-ov-file
  -- https://youtu.be/AAkrmfkC1L4?t=167
  {
    'MeanderingProgrammer/render-markdown.nvim',
    dependencies = { 'nvim-treesitter/nvim-treesitter', 'echasnovski/mini.icons' }, -- if you use standalone mini plugins
    opts = function(_, opts)
      return vim.tbl_deep_extend('force', opts or {}, {
        latex = { enabled = false },
        completions = {
          blink = { enabled = true },
          lsp = { enabled = true }
        },
      })
    end,
  },
}
