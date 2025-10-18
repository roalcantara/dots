return {
  -- Completion plugin with support for LSPs, cmdline, signature help and snippets
  -- https://cmp.saghen.dev
  -- https://youtu.be/GKIxgCcKAq4
  {
    'saghen/blink.cmp',
    event = 'VeryLazy',
    version = '1.*',
    dependencies = {
      { "nvim-tree/nvim-web-devicons", opts = {} },
      {
        -- Configures LuaLS to support auto-completion and type checking while editing your Neovim configuration
        -- https://github.com/folke/lazydev.nvim?tab=readme-ov-file#-installation | https://www.lazyvim.org/plugins/coding#lazydevnvim
        'folke/lazydev.nvim',
        ft = 'lua', -- only load on lua files
        opts = {
          -- Configure library paths
          library = {
            -- It can be relative, which means they will be resolved from the plugin dir.
            'lazy.nvim',
            -- It can also be a table with trigger words / modifiers
            -- Load luvit types when the `vim.uv` word is found
            { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
            { path = 'LazyVim',            words = { 'LazyVim' } },
            { path = 'snacks.nvim',        words = { 'Snacks' } },
            { path = 'lazy.nvim',          words = { 'LazyVim' } },
          },
          integrations = {
            -- Fixes lspconfig's workspace management for LuaLS
            -- Only create a new workspace if the buffer is not part
            -- of an existing workspace or one of its libraries
            lspconfig = true,
            -- add the cmp source for completion of:
            -- `require "modname"`
            -- `---@module "modname"`
            cmp = true,
            -- same, but for Coq
            coq = false,
          },
        },
      },
      'rafamadriz/friendly-snippets',
      'onsails/lspkind.nvim',
      -- Conventional Commits source for blink-cmp
      -- https://github.com/disrupted/blink-cmp-conventional-commits?tab=readme-ov-file#installation
      'disrupted/blink-cmp-conventional-commits',
      -- Configurable GitHub Copilot blink.cmp source for Neovim
      -- https://github.com/fang2hou/blink-copilot?tab=readme-ov-file#-recipes
      'fang2hou/blink-copilot',
      -- Git source for blink-cmp
      -- https://github.com/Kaiser-Yang/blink-cmp-git?tab=readme-ov-file#lazynvim
      {
        'Kaiser-Yang/blink-cmp-git',
        dependencies = { 'nvim-lua/plenary.nvim' },
      },
      -- Bring enjoyment to your auto completion.
      -- https://github.com/xzbdmw/colorful-menu.nvim
      'xzbdmw/colorful-menu.nvim',
    },
    opts = function(_, opts)
      local ui_helper = require('core/ui/ui_helper')
      local paths = require('core/vi/paths')

      return {
        -- Configure native snippets
        -- https://cmp.saghen.dev/configuration/snippets.html
        snippets = {
          expand = function(snippet)
            vim.snippet.expand(snippet)
          end,
          active = function(filter)
            if filter and filter.direction then
              return vim.snippet.active({ direction = filter.direction })
            end
            return vim.snippet.active()
          end,
          jump = function(direction)
            vim.snippet.jump(direction)
          end,
        },
        -- https://cmp.saghen.dev/configuration/appearance.html
        appearance = {
          -- sets the fallback highlight groups to nvim-cmp's highlight groups
          -- useful for when your theme doesn't support blink.cmp
          -- will be removed in a future release, assuming themes add support
          use_nvim_cmp_as_default = false,
          -- set to 'mono' for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
          -- adjusts spacing to ensure icons are aligned
          nerd_font_variant = 'mono',

          kind_icons = {
            claude = '󰋦',
            openai = '󱢆',
            codestral = '󱎥',
            gemini = '',
            Groq = '',
            Openrouter = '󱂇',
            Ollama = '󰳆',
            ['Llama.cpp'] = '󰳆',
            Deepseek = '',
          },
        },
        -- https://cmp.saghen.dev/modes/cmdline.html
        cmdline = {
          enabled = true,
          keymap = { preset = 'cmdline' },
          -- https://cmp.saghen.dev/modes/cmdline.html#keymap-preset
          completion = {
            -- https://cmp.saghen.dev/modes/cmdline.html#show-menu-automatically
            trigger = {
              show_on_blocked_trigger_characters = {},
              show_on_x_blocked_trigger_characters = {},
            },
            list = {
              selection = {
                -- When `true`, will automatically select the first item in the completion list
                preselect = true,
                -- When `true`, inserts the completion item automatically when selecting it
                auto_insert = true,
              },
            },
            menu = {
              auto_show = function(ctx)
                return vim.fn.getcmdtype() == ':' or ctx.mode == 'cmdwin'
              end,
            },
            -- https://cmp.saghen.dev/modes/cmdline.html#ghost-text
            ghost_text = { enabled = true },
          }
        },
        -- https://cmp.saghen.dev/configuration/sources.html
        -- https://cmp.saghen.dev/configuration/sources.html#community-sources
        sources = {
          default = function(ctx)
            local success, node = pcall(vim.treesitter.get_node)
            if success and node and vim.tbl_contains({ 'comment', 'line_comment', 'block_comment' }, node:type()) then
              return { 'buffer', 'copilot' }
            else
              return { 'copilot', 'lazydev', 'lsp', 'path', 'snippets', 'buffer' }
            end
          end,
          providers = {
            copilot = {
              name = 'copilot',
              module = 'blink-copilot',
              score_offset = 100,
              async = true,
            },
            lazydev = {
              name = 'LazyDev',
              module = 'lazydev.integrations.blink',
              -- make lazydev completions top priority (see `:h blink.cmp`)
              score_offset = 100,
            },
            lsp = {
              name = 'LSP',
              module = 'blink.cmp.sources.lsp',
              -- You may enable the buffer source, when LSP is available, by setting this to `{}`
              -- You may want to set the score_offset of the buffer source to a lower value, such as -5 in this case
              -- Filter text items from the LSP provider, since we have the buffer provider for that

              -- Function to transform the items before they're returned
              transform_items = function(_, items)
                return vim.tbl_filter(function(item)
                  return item.kind ~= require('blink.cmp.types').CompletionItemKind.Text
                end, items)
              end,
              opts = { tailwind_color_icon = '██' },
              --- These properties apply to !!ALL sources!!
              --- NOTE: All of these options may be functions to get dynamic behavior
              --- See the type definitions for more information
              enabled = true,           -- Whether or not to enable the provider
              async = false,            -- Whether we should show the completions before this provider returns, without waiting for it
              timeout_ms = 2000,        -- How long to wait for the provider to return before showing completions and treating it as asynchronous
              should_show_items = true, -- Whether or not to show the items
              max_items = nil,          -- Maximum number of items to display in the menu
              min_keyword_length = 0,   -- Minimum number of characters in the keyword to trigger the provider
              -- If this provider returns 0 items, it will fallback to these providers.
              -- If multiple providers fallback to the same provider, all of the providers must return 0 items for it to fallback
              fallbacks = { 'buffer' },
              score_offset = 0, -- Boost/penalize the score of the items
              override = nil,   -- Override the source's functions
            },
            -- Native Snippets
            snippets = {
              name = 'snippets',
              module = 'blink.cmp.sources.snippets',
              score_offset = -3,
              opts = {
                friendly_snippets = true,
                search_paths = { paths.stdpaths.snippets },
                global_snippets = { 'all' },
                extended_filetypes = {},
                ignored_filetypes = {},
              },
            },
            path = {
              module = 'blink.cmp.sources.path',
              score_offset = 3,
              fallbacks = { 'buffer' },
              opts = {
                trailing_slash = true,
                label_trailing_slash = true,
                get_cwd = function(context)
                  -- return the current working directory of the buffer
                  return paths.bufcwd(context.bufnr)
                end,
                show_hidden_files_by_default = false,
                -- Treat `/path` as starting from the current working directory (cwd) instead of the root of your filesystem
                ignore_root_slash = false,
              },
            },
            cmdline = {
              module = 'blink.cmp.sources.cmdline'
            },
            omni = {
              module = 'blink.cmp.sources.complete_func',
              enabled = function()
                return vim.bo.omnifunc ~= 'v:lua.vim.lsp.omnifunc'
              end,
              --- @type blink.cmp.CompleteFuncOpts
              opts = {
                complete_func = function()
                  return vim.bo.omnifunc
                end,
              },
            },
          },
        },
        -- https://cmp.saghen.dev/configuration/keymap.html
        keymap = {
          -- https://cmp.saghen.dev/configuration/keymap.html#super-tab
          -- preset = 'super-tab',
          ['<C-space>'] = { 'show', 'show_documentation', 'hide_documentation' },
          ['<C-e>'] = { 'hide', 'fallback' },
          ['<Tab>'] = {
            -- 1. On Tab, if snippet is active, accept it
            -- 2. Otherwise, 'select_and_accept' => Accepts the currently selected item, or the first item if none are selected
            -- 3. Otherwise, 'snippet_forward' => Jumps to the next snippet placeholder
            -- 4. Otherwise, 'fallback_to_mappings' => Runs the next non-blink keymap (not built-in behavior)
            function(cmp)
              if cmp.snippet_active() then
                return cmp.accept()
              else
                return cmp.select_and_accept()
              end
            end,
            'snippet_forward',
            'fallback_to_mappings',
          },
          ['<S-Tab>'] = {
            -- 1. On Shift-Tab, if snippet is active, 'snippet_backward' => Jumps to the previous snippet placeholder
            -- 2. Otherwise, 'fallback_to_mappings' => Runs the next non-blink keymap (not built-in behavior)
            function(cmp)
              if cmp.snippet_active() then
                return cmp.snippet_backward()
              end
            end,
            'fallback_to_mappings',
          },
          ['<Up>'] = { 'select_prev', 'fallback' },
          ['<Down>'] = { 'select_next', 'fallback' },
          ['<C-k>'] = { 'show_signature', 'hide_signature', 'fallback_to_mappings', 'fallback' },
        },
        -- https://cmp.saghen.dev/configuration/completion.html
        completion = {
          -- Manages the appearance of the completion menu
          -- https://cmp.saghen.dev/configuration/completion.html#menu
          menu = {
            enabled = true,
            border = nil, -- Defaults to `vim.o.winborder` on nvim 0.11+
            min_width = 15,
            max_height = 20,
            winblend = 0,
            -- winhighlight =
            -- 'Normal:BlinkCmpMenu,FloatBorder:BlinkCmpMenuBorder,CursorLine:BlinkCmpMenuSelection,Search:None',
            -- Keep the cursor X lines away from the top/bottom of the window
            scrolloff = 2,
            -- Note that the gutter will be disabled when border ~= 'none'
            scrollbar = false,
            -- Whether to automatically show the window when new completion items are available
            auto_show = true,
            -- Blink uses a grid-based layout to render the completion menu.
            -- https://cmp.saghen.dev/configuration/completion.html#menu-draw
            -- https://cmp.saghen.dev/recipes.html#completion-menu-drawing
            draw = {
              -- Aligns the keyword you've typed to a component in the menu
              align_to = 'label', -- or 'none' to disable, or 'cursor' to align to the cursor
              -- Left and right padding, optionally { left, right } for different padding on each side
              padding = { 1, 1 },
              -- Gap between columns
              gap = 2,
              -- Priority of the cursorline highlight, setting this to 0 will render it below other highlights
              cursorline_priority = 10000,
              -- Use treesitter to highlight the label text for the given list of sources
              treesitter = { 'lsp' },
              -- Define text and highlight functions which are called for each completion item. Each defines:
              --   ellipsis: whether to add an ellipsis when truncating the text
              --   width: control the min, max and fill behavior of the component
              --   text function: will be called for each item
              --   highlight function: will be called only when the line appears on screen
              components = {
                kind = {
                  ellipsis = false,
                  width = { fill = true },
                  text = function(ctx) return ctx.kind end,
                  highlight = ui_helper.get_kind_highlight,
                },
                kind_icon = {
                  text = ui_helper.get_kind_icon_with_gap,
                  highlight = ui_helper.get_kind_highlight,
                },
                label = {
                  text = ui_helper.get_label_text,
                  highlight = ui_helper.get_label_highlight,
                },
                label_description = {
                  width = { max = 30 },
                  text = function(ctx) return ctx.label_description end,
                  highlight = 'BlinkCmpLabelDescription',
                },
                source_name = {
                  width = { max = 30 },
                  text = function(ctx) return ctx.source_name end,
                  highlight = 'BlinkCmpSource',
                },
                source_id = {
                  width = { max = 30 },
                  text = function(ctx) return ctx.source_id end,
                  highlight = 'BlinkCmpSource',
                },
              },

              -- Columns effectively allow you to vertically align a set of components.
              -- Each column, defined as an array in draw.columns, will be rendered for all of the completion items,
              -- where the longest rendered row will determine the width of the column.
              -- For a setup similar to nvim-cmp, use the following config:
              -- columns = { { "label", "label_description", gap = 1 }, { "kind_icon", "kind" } }
              -- We don't need label_description now because label and label_description are already combined together in label by colorful-menu.nvim.
              -- https://github.com/xzbdmw/colorful-menu.nvim?tab=readme-ov-file#use-it-in-blinkcmp
              columns = { { 'kind_icon' }, { 'label', gap = 1 } },
            },

            -- Avoid overlapping with the ghost text
            -- https://cmp.saghen.dev/recipes.html#avoid-multi-line-completion-ghost-text
            direction_priority = ui_helper.detect_window_direction_order_priority,
          },
          -- Manages the documentation window
          -- https://cmp.saghen.dev/configuration/completion.html#documentation
          documentation = {
            window = {
              border = nil,
              scrollbar = false,
              winhighlight = 'Normal:BlinkCmpDoc,FloatBorder:BlinkCmpDocBorder,EndOfBuffer:BlinkCmpDoc',
            },
            -- Try to prevent duplicate documentation
            auto_show = false,
            auto_show_delay_ms = 10000,
            treesitter_highlighting = true,
          },
          -- Manages the completion list and its behavior when selecting items
          -- https://cmp.saghen.dev/configuration/completion.html#list
          list = {
            max_items = 200, -- Maximum number of items to display
            -- https://cmp.saghen.dev/configuration/keymap.html#super-tab
            selection = {
              preselect = function(ctx)
                return not require('blink.cmp').snippet_active({ direction = 1 })
              end,
              auto_insert = true,
            },
            cycle = {
              -- When `true`, calling `select_next` at the _bottom_ of the completion list
              -- will select the _first_ completion item.
              from_bottom = true,
              -- When `true`, calling `select_prev` at the _top_ of the completion list
              -- will select the _last_ completion item.
              from_top = true,
            },
          },
          -- Manages the behavior when accepting an item in the completion menu
          -- https://cmp.saghen.dev/configuration/completion.html#accept
          accept = {
            -- experimental auto-brackets support
            auto_brackets = {
              enabled = true,
            },
          },
          -- Shows a preview of the currently selected item as virtual text inline
          -- https://cmp.saghen.dev/configuration/completion.html#ghost-text
          ghost_text = {
            enabled = true,
            show_with_selection = true,     -- Show the ghost text when an item has been selected
            show_without_selection = false, -- Show the ghost text when no item has been selected, defaulting to the first item
            show_with_menu = true,          -- only show when menu is closed
            show_without_menu = true,       -- Show the ghost text when the menu is closed
          },
        },
        -- Experimental signature help support
        -- https://cmp.saghen.dev/configuration/reference.html#signature
        signature = {
          enabled = false,
          trigger = {
            -- Show the signature help automatically
            enabled = false,
            -- Show the signature help window after typing any of alphanumerics, `-` or `_`
            show_on_keyword = false,
            blocked_trigger_characters = {},
            blocked_retrigger_characters = {},
            -- Show the signature help window after typing a trigger character
            show_on_trigger_character = true,
            -- Show the signature help window when entering insert mode
            show_on_insert = false,
            -- Show the signature help window when the cursor comes after a trigger character when entering insert mode
            show_on_insert_on_trigger_character = true,
          },
          window = {
            min_width = 1,
            max_width = 100,
            max_height = 10,
            border = 'rounded', -- Defaults to `vim.o.winborder` on nvim 0.11+ or 'padded' when not defined/<=0.10
            winblend = 0,
            winhighlight = 'Normal:BlinkCmpSignatureHelp,FloatBorder:BlinkCmpSignatureHelpBorder',
            scrollbar = false, -- Note that the gutter will be disabled when border ~= 'none'
            -- Direction order priority to show the window; { 's', 'n' } by default
            direction_priority = ui_helper.detect_window_direction_order_priority,
            treesitter_highlighting = true, -- Disable if you run into performance issues
            show_documentation = false,
          },
        },
        -- (Default) Rust fuzzy matcher for typo resistance and significantly better performance
        -- You may use a lua implementation instead by using `implementation = "lua"` or fallback to the lua implementation,
        -- when the Rust fuzzy matcher is not available, by using `implementation = "prefer_rust"`
        -- https://cmp.saghen.dev/configuration/fuzzy.html
        -- https://github.com/saghen/frizbee
        fuzzy = { implementation = 'prefer_rust_with_warning' },
      }
    end,
  },
}
