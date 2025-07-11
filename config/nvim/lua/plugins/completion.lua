local get_default_sources = require('core/vi/ui/lsp/sources_by_filetype')

return {
  {
    "saghen/blink.cmp",
    dependencies = {
      -- LAZYDEV - Configure Lua LSP Neovim config for runtime, plugins, completions, annotations, signatures and apis
      -- https://github.com/folke/lazydev.nvim
      'folke/lazydev.nvim',

      -- Conventional Commits source for blink-cmp
      -- https://github.com/disrupted/blink-cmp-conventional-commits?tab=readme-ov-file#installation
      'disrupted/blink-cmp-conventional-commits',

      -- Configurable GitHub Copilot blink.cmp source for Neovim
      -- https://github.com/fang2hou/blink-copilot?tab=readme-ov-file#with--lazyvim-copilot-extra
      'fang2hou/blink-copilot',

      -- Git source for blink-cmp
      -- https://github.com/Kaiser-Yang/blink-cmp-git?tab=readme-ov-file#lazynvim
      {
        'Kaiser-Yang/blink-cmp-git',
        dependencies = { 'nvim-lua/plenary.nvim' },
      },
    },
    opts = function(_, opts)
      vim.tbl_extend("force", opts or {}, {
        keymap = { preset = "super-tab" },
        -- add lazydev to your completion providers
        -- https://cmp.saghen.dev/configuration/reference.html#sources
        -- https://github.com/folke/lazydev.nvim?tab=readme-ov-file#-installation
        sources = {
          default = { "lazydev", "lsp", "path", "snippets", "buffer" },
          providers = {
            lazydev = {
              name = "LazyDev",
              module = "lazydev.integrations.blink",
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
                return vim.tbl_filter(
                  function(item) return item.kind ~= require('blink.cmp.types').CompletionItemKind.Text end,
                  items
                )
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

            path = {
              module = 'blink.cmp.sources.path',
              score_offset = 3,
              fallbacks = { 'buffer' },
              opts = {
                trailing_slash = true,
                label_trailing_slash = true,
                get_cwd = function(context) return vim.fn.expand(('#%d:p:h'):format(context.bufnr)) end,
                show_hidden_files_by_default = false,
                -- Treat `/path` as starting from the current working directory (cwd) instead of the root of your filesystem
                ignore_root_slash = false,
              }
            },

            snippets = {
              module = 'blink.cmp.sources.snippets',
              score_offset = -1, -- receives a -3 from top level snippets.score_offset
              -- For `snippets.preset == 'mini_snippets'`
              opts = {
                -- Whether to use a cache for completion items
                use_items_cache = true,
              }
            },

            buffer = {
              module = 'blink.cmp.sources.buffer',
              score_offset = -3,
              opts = {
                -- default to all visible buffers
                get_bufnrs = function()
                  return vim
                    .iter(vim.api.nvim_list_wins())
                    :map(function(win) return vim.api.nvim_win_get_buf(win) end)
                    :filter(function(buf) return vim.bo[buf].buftype ~= 'nofile' end)
                    :totable()
                end,
                -- buffers when searching with `/` or `?`
                get_search_bufnrs = function() return { vim.api.nvim_get_current_buf() } end,
                -- Maximum total number of characters (across all selected buffers) for which buffer completion runs synchronously. Above this, asynchronous processing is used.
                max_sync_buffer_size = 20000,
                -- Maximum total number of characters (across all selected buffers) for which buffer completion runs asynchronously. Above this, buffer completions are skipped to avoid performance issues.
                max_async_buffer_size = 500000,
                -- Whether to enable buffer source in substitute (:s) and global (:g) commands.
                -- Note: Enabling this option will temporarily disable Neovim's 'inccommand' feature
                -- while editing Ex commands, due to a known redraw issue (see neovim/neovim#9783).
                -- This means you will lose live substitution previews when using :s, :smagic, or :snomagic
                -- while buffer completions are active.
                enable_in_ex_commands = false,
              }
            },

            cmdline = {
              module = 'blink.cmp.sources.cmdline',
              -- Disable shell commands on windows, since they cause neovim to hang
              enabled = function()
                return vim.fn.has('win32') == 0
                  or vim.fn.getcmdtype() ~= ':'
                  or not vim.fn.getcmdline():match("^[%%0-9,'<>%-]*!")
              end,
            },

            omni = {
              module = 'blink.cmp.sources.complete_func',
              enabled = function() return vim.bo.omnifunc ~= 'v:lua.vim.lsp.omnifunc' end,
              --- @type blink.cmp.CompleteFuncOpts
              opts = {
                complete_func = function() return vim.bo.omnifunc end,
              },
            },
          },
        },
        -- Experimental signature help support
        -- https://cmp.saghen.dev/configuration/reference.html#signature
        signature = {
          enabled = true,
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
            -- Which directions to show the window,
            -- falling back to the next direction when there's not enough space,
            -- or another window is in the way
            direction_priority = { 'n', 's' },
            -- Can accept a function if you need more control
            -- direction_priority = function()
            --   if condition then return { 'n', 's' } end
            --   return { 's', 'n' }
            -- end,

            -- Disable if you run into performance issues
            treesitter_highlighting = true,
            show_documentation = true,
          },
        }
      })
    end
  }
}
