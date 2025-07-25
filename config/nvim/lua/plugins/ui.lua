-- Adding a plugin is as simple as adding the plugin spec to one of the files under lua/plugins/*.lua.
-- You can structure your lua/plugins folder with a file per plugin, or a separate file containing all the plugin specs for some functionality.
-- You can create as many files there as you want. In order to disable a plugin, add a spec with enabled=false
-- https://lazyvim.org/configuration/plugins
return {
  -- Treesitter is a new parser generator tool to power faster and more accurate syntax highlighting
  -- https://lazyvim.org/configuration/examples
  -- https://lazyvim.org/plugins/treesitter#nvim-treesitter
  {
    'nvim-treesitter/nvim-treesitter',
    init = function()
      -- Mise + Neovim Cookbook | Code highlight for run commands
      -- Ensure to only apply the highlighting on mise files instead of all toml files
      -- https://mise.jdx.dev/mise-cookbook/neovim.html#code-highlight-for-run-commands
      require("vim.treesitter.query").add_predicate("is-mise?", function(_, _, bufnr, _)
        local filepath = vim.api.nvim_buf_get_name(tonumber(bufnr) or 0)
        local filename = vim.fn.fnamemodify(filepath, ":t")
        return string.match(filename, ".*mise.*%.toml$") ~= nil
      end, { force = true, all = false })
    end,
    opts = function(_, opts)
      opts = opts or {}
      opts.auto_install = true
      opts.highlight = {
        enable = true,
        -- Setting this to true will run `:h syntax` and tree-sitter at the same time.
        -- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
        -- Using this option may slow down your editor, and you may see some duplicate highlights.
        -- Instead of true it can also be a list of languages
        -- https://github.com/catppuccin/nvim?tab=readme-ov-file#wrong-treesitter-highlights
        additional_vim_regex_highlighting = false,
      }
      opts.indent = { enable = true }
      opts.ignore_install = { 'latex' }
      vim.list_extend(opts.ensure_installed, {
        'css',
        'dockerfile',
        'git_config',
        'git_rebase',
        'gitattributes',
        'gitcommit',
        'gitignore',
        'ini',
        'make',
        'norg',
        'ruby',
        'scss',
        'svelte',
        'tsx',
        'typescript',
        'typst',
        'vue',
      })
      return opts
    end,
  },

  -- SNACKS | A modern UI library for Neovim | https://github.com/folke/snacks.nvim
  -- https://lazyvim.org/extras/editor/snacks_picker#snacksnvim-1
  {
    'folke/snacks.nvim',
    dependencies = {
      'folke/flash.nvim'
    },
    opts = function(_, opts)
      local snacks_default_exclusions = require('core/vi/ui/snacks/defaults').default_exclusions
      return vim.tbl_deep_extend('force', opts or {}, {
        dashboard = {
          enabled = true,
          open_on_startup = true,
          preset = {
            pick = function(cmd, opt)
              return LazyVim.pick(cmd, opt)()
            end,
            header = require('core/vi/ui/snacks/dashboard').header(),
            keys = {
              { icon = '󰀶 ', key = 's', desc = 'Smart Find Files', action = ':lua Snacks.picker.smart({})' },
              { icon = ' ', key = 'f', desc = 'Find File', action = ':lua Snacks.picker.files()' },
              { icon = ' ', key = 'n', desc = 'New File', action = ':ene | startinsert' },
              { icon = ' ', key = 'g', desc = 'Find Text', action = ':lua Snacks.picker.grep()' },
              { icon = ' ', key = 'r', desc = 'Recent Files', action = ':lua Snacks.picker.recent()' },
              { icon = ' ', key = 'x', desc = 'Lazy Extras', action = ':LazyExtras' },
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
          enabled = false,
          ft = function()
            return vim.bo.filetype ~= '' and vim.bo.filetype or 'lua'
          end,
          win = {
            width = 0.7,
            height = 0.6,
            border = 'rounded',
            enter = true,
            minimal = false,
            title_pos = 'center',
            footer_pos = 'center',
            keys = {
              ['source'] = {
                '<D-cr>',
                function(self)
                  local name = 'scratch.' .. vim.fn.fnamemodify(vim.api.nvim_buf_get_name(self.buf), ':e')
                  Snacks.debug.run({ buf = self.buf, name = name })
                end,
                desc = 'Run',
                mode = { 'n', 'i', 'v', 'x' },
              },
              ['reset'] = {
                '<D-r>',
                function(self)
                  self:reset()
                end,
                desc = 'Reset',
                mode = { 'n', 'i', 'v', 'x' },
              },
              ['quit'] = {
                '<D-S-Bslash>',
                function(self)
                  self:close()
                end,
                desc = 'Quit',
                mode = { 'n', 'i', 'v', 'x' },
              },
              q = 'close',
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
          actions = {
            flash = function(picker)
              require('flash').jump({
                pattern = '',
                label = { after = { 0, 0 } },
                search = {
                  mode = 'search',
                  exclude = {
                    function(win)
                      return vim.bo[vim.api.nvim_win_get_buf(win)].filetype ~= 'snacks_picker_list'
                    end,
                  },
                },
                action = function(match)
                  local idx = picker.list:row2idx(match.pos[1])
                  picker.list:_move(idx, true, true)
                end,
              })
            end,

            -- move_split_down = function(picker)
            --   vim.cmd('botright split')
            --   vim.api.nvim_set_current_buf(picker.list:get_item().buf)
            -- end,

            -- move_split_up = function(picker)
            --   vim.cmd('topleft split')
            --   vim.api.nvim_set_current_buf(picker.list:get_item().buf)
            -- end,

            -- move_split_right = function(picker)
            --   vim.cmd('botright vsplit')
            --   vim.api.nvim_set_current_buf(picker.list:get_item().buf)
            -- end,

            -- move_split_left = function(picker)
            --   vim.cmd('topleft vsplit')
            --   vim.api.nvim_set_current_buf((picker.list or picker.input):get_item().buf)
            -- end,

            -- edit_split_down = { action = 'confirm', cmd = 'botright split' },
            -- edit_split_up = { action = 'confirm', cmd = 'topleft split' },
            -- edit_split_right = { action = 'confirm', cmd = 'leftabove vsplit | bprev | wincmd l' },
            -- -- edit_split_right = { action = 'confirm', cmd = 'botright vsplit' },
            -- edit_split_left = { action = 'confirm', cmd = 'topleft vsplit' },
          },
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
    opts = function(_, opts)
      -- https://github.com/folke/noice.nvim?tab=readme-ov-file#%EF%B8%8F-configuration
      return vim.tbl_deep_extend('force', opts or {}, {
        -- https://github.com/folke/noice.nvim/wiki/Configuration-Recipes#presets
        presets = vim.tbl_deep_extend('force', opts.presets or {}, {
          lsp_doc_border = true,
        }),
        -- Hide written messages
        -- https://github.com/folke/noice.nvim?tab=readme-ov-file#-routes
        -- https://github.com/folke/noice.nvim/wiki/Configuration-Recipes#hide-written-messages-1
        routes = vim.tbl_deep_extend('force', opts.routes or {}, {
          {
            filter = {
              event = 'notify',
              find = 'No information available',
            },
            opts = { skip = true },
          },
        }),
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
      if opts.sections.lualine_c[2] then
        opts.sections.lualine_c[2] = vim.tbl_deep_extend('force', opts.sections.lualine_c[2] or {}, {
          on_click = function()
            vim.cmd('LspToggleDiagnostics')
          end,
        })
      end
      if opts.sections.lualine_c[3] then
        opts.sections.lualine_c[3] = vim.tbl_deep_extend('force', opts.sections.lualine_c[3] or {}, {
          on_click = function()
            vim.cmd('FileTypes')
          end,
        })
      end
      if opts.sections.lualine_c[5] then
        opts.sections.lualine_c[5] = vim.tbl_deep_extend('force', opts.sections.lualine_c[5] or {}, {
          on_click = function()
            Snacks.picker.lsp_symbols({ layout = 'dropdown', enter = true, focus = 'list' })
          end,
        })
      end
      if opts.sections.lualine_x[6] then
        opts.sections.lualine_x[6] = vim.tbl_deep_extend('force', opts.sections.lualine_x[6] or {}, {
          on_click = function()
            vim.schedule(function()
              vim.cmd [[Lazy sync]]
              refresh('window', 'statusline')
            end)
          end,
        })
      end

      table.insert(opts.sections.lualine_x, {
        function()
          return '🔄'
        end,
        cond = function()
          return vim.fn.exists('g:lazy_version')
        end,
      })

      table.insert(opts.sections.lualine_x, {
        function()
          return '󱉶'
        end,
        fmt = function()
          return table.concat(require("lint").get_running(), ", ")
        end,
        cond = function()
          return #require("lint").get_running() > 0
        end,
      })

      return vim.tbl_deep_extend('force', opts or {}, {
        options = {
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
          }
        }
      })
    end,
  },

  -- Automatically validate your Ghostty configuration on save
  -- https://github.com/isak102/ghostty.nvim
  {
    'isak102/ghostty.nvim',
    lazy = true,
    cond = require('core/vi/fn/paths').is_executable('ghostty'),
    opts = {
      -- The autocmd pattern matched against the filename of the buffer. If this pattern
      -- matches, ghostty.nvim will run on save in that buffer. This pattern is passed to
      -- nvim_create_autocmd, check ":h autocmd-pattern" for more information. Can be
      -- either a string or a list of strings
      -- file_pattern = vim.fn.expand(paths.to_xdg_config_home({ 'ghostty', 'config' })),
      -- The ghostty executable to run.
      ghostty_cmd = 'ghostty',
      -- The timeout in milliseconds for the check command.
      -- If the command takes longer than this it will be killed.
      check_timeout = 1000,
    },
  },

  -- SHOWKEYS - Minimal Eye-candy keys screencaster
  -- https://github.com/nvzone/showkeys | https://youtu.be/E4qXZv34NQQ
  {
    'nvzone/showkeys',
    lazy = true,
    cmd = 'ShowkeysToggle',
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
  },
}
