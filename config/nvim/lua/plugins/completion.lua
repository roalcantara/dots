return {
  {
    'saghen/blink.cmp',
    lazy = false,
    version = "1.*",
    dependencies = {
      'rafamadriz/friendly-snippets',
      "onsails/lspkind.nvim",
      -- Conventional Commits source for blink-cmp
      -- https://github.com/disrupted/blink-cmp-conventional-commits?tab=readme-ov-file#installation
      'disrupted/blink-cmp-conventional-commits',
      -- Configurable GitHub Copilot blink.cmp source for Neovim
      -- https://github.com/fang2hou/blink-copilot?tab=readme-ov-file#with--lazyvim-copilot-extra
      {
        'fang2hou/blink-copilot',
        opts = {
          max_completions = 5, -- Global default for max completions
          max_attempts = 4,    -- Global default for max attempts
        }
      },
      -- Git source for blink-cmp
      -- https://github.com/Kaiser-Yang/blink-cmp-git?tab=readme-ov-file#lazynvim
      {
        'Kaiser-Yang/blink-cmp-git',
        dependencies = { 'nvim-lua/plenary.nvim' },
      },
      {
        'folke/lazydev.nvim',
        ft = 'lua',
        opts = {
          library = {
            -- See the configuration section for more details
            -- Load luvit types when the `vim.uv` word is found
            { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
          },
        },
      },
      {
        'xzbdmw/colorful-menu.nvim',
        opts = {
          ls = {
            lua_ls = {
              -- Maybe you want to dim arguments a bit.
              arguments_hl = "@comment",
            },
            gopls = {
              -- By default, we render variable/function's type in the right most side,
              -- to make them not to crowd together with the original label.

              -- when true:
              -- foo             *Foo
              -- ast         "go/ast"

              -- when false:
              -- foo *Foo
              -- ast "go/ast"
              align_type_to_right = true,
              -- When true, label for field and variable will format like "foo: Foo"
              -- instead of go's original syntax "foo Foo". If align_type_to_right is
              -- true, this option has no effect.
              add_colon_before_type = false,
              -- See https://github.com/xzbdmw/colorful-menu.nvim/pull/36
              preserve_type_when_truncate = true,
            },
            -- for lsp_config or typescript-tools
            ts_ls = {
              -- false means do not include any extra info,
              -- see https://github.com/xzbdmw/colorful-menu.nvim/issues/42
              extra_info_hl = "@comment",
            },
            vtsls = {
              -- false means do not include any extra info,
              -- see https://github.com/xzbdmw/colorful-menu.nvim/issues/42
              extra_info_hl = "@comment",
            },
            ["rust-analyzer"] = {
              -- Such as (as Iterator), (use std::io).
              extra_info_hl = "@comment",
              -- Similar to the same setting of gopls.
              align_type_to_right = true,
              -- See https://github.com/xzbdmw/colorful-menu.nvim/pull/36
              preserve_type_when_truncate = true,
            },
            clangd = {
              -- Such as "From <stdio.h>".
              extra_info_hl = "@comment",
              -- Similar to the same setting of gopls.
              align_type_to_right = true,
              -- the hl group of leading dot of "•std::filesystem::permissions(..)"
              import_dot_hl = "@comment",
              -- See https://github.com/xzbdmw/colorful-menu.nvim/pull/36
              preserve_type_when_truncate = true,
            },
            zls = {
              -- Similar to the same setting of gopls.
              align_type_to_right = true,
            },
            roslyn = {
              extra_info_hl = "@comment",
            },
            dartls = {
              extra_info_hl = "@comment",
            },
            -- The same applies to pyright/pylance
            basedpyright = {
              -- It is usually import path such as "os"
              extra_info_hl = "@comment",
            },
            pylsp = {
              extra_info_hl = "@comment",
              -- Dim the function argument area, which is the main
              -- difference with pyright.
              arguments_hl = "@comment",
            },
            -- If true, try to highlight "not supported" languages.
            fallback = true,
            -- this will be applied to label description for unsupport languages
            fallback_extra_info_hl = "@comment",
          },
          -- If the built-in logic fails to find a suitable highlight group for a label,
          -- this highlight is applied to the label.
          fallback_highlight = "@variable",
          -- If provided, the plugin truncates the final displayed text to
          -- this width (measured in display cells). Any highlights that extend
          -- beyond the truncation point are ignored. When set to a float
          -- between 0 and 1, it'll be treated as percentage of the width of
          -- the window: math.floor(max_width * vim.api.nvim_win_get_width(0))
          -- Default 60.
          max_width = 60,
        },
      }
    },
    opts = {
      -- Configure native snippets
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
      appearance = {
        -- sets the fallback highlight groups to nvim-cmp's highlight groups
        -- useful for when your theme doesn't support blink.cmp
        -- will be removed in a future release, assuming themes add support
        use_nvim_cmp_as_default = false,
        -- set to 'mono' for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
        -- adjusts spacing to ensure icons are aligned
        nerd_font_variant = "mono",
      },
      sources = {
        default = function(ctx)
          local success, node = pcall(vim.treesitter.get_node)
          if success and node and vim.tbl_contains({ 'comment', 'line_comment', 'block_comment' }, node:type()) then
            return { 'buffer', 'copilot' }
            -- elseif vim.bo.filetype == 'lua' then
            --   return { 'lsp', 'path' }
          else
            return { 'copilot', 'lazydev', 'lsp', 'path', 'snippets', 'buffer' }
          end
        end,
        providers = {
          copilot = {
            name = "copilot",
            module = "blink-copilot",
            score_offset = 100,
            async = true
          },
          lazydev = {
            name = "LazyDev",
            module = "lazydev.integrations.blink",
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
          -- Native Snippets
          snippets = {
            name = "snippets",
            module = "blink.cmp.sources.snippets",
            score_offset = -3,
            opts = {
              friendly_snippets = true,
              search_paths = { vim.fn.stdpath("config") .. "/snippets" },
              global_snippets = { "all" },
              extended_filetypes = {},
              ignored_filetypes = {},
            }
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
      keymap = {
        -- https://cmp.saghen.dev/configuration/keymap.html#super-tab
        -- preset = 'super-tab',
        ['<C-space>'] = { 'show', 'show_documentation', 'hide_documentation' },
        ['<C-e>'] = { 'hide', 'fallback' },
        ['<Tab>'] = {
          function(cmp)
            if cmp.snippet_active() then
              return cmp.accept()
            else
              return cmp.select_and_accept()
            end
          end,
          'snippet_forward',
          'fallback'
        },
        ['<S-Tab>'] = { 'snippet_backward', 'fallback' },
        ['<Up>'] = { 'select_prev', 'fallback' },
        ['<Down>'] = { 'select_next', 'fallback' },
        ['<C-p>'] = { 'select_prev', 'fallback_to_mappings' },
        ['<C-n>'] = { 'select_next', 'fallback_to_mappings' },

        ['<C-b>'] = { 'scroll_documentation_up', 'fallback' },
        ['<C-f>'] = { 'scroll_documentation_down', 'fallback' },

        ['<C-k>'] = { 'show_signature', 'hide_signature', 'fallback' },
      },
      cmdline = {
        enabled = true,
        completion = { menu = { auto_show = true } },
        keymap = {
          ["<CR>"] = { "accept_and_enter", "fallback" },
        },
      },
      completion = {
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
          draw = {
            padding = { 1, 0 },
            columns = { { "kind_icon" }, { "label", gap = 1 } },
            components = {
              kind_icon = {
                text = function(ctx)
                  local icon = ctx.kind_icon
                  if vim.tbl_contains({ "Path" }, ctx.source_name) then
                    local dev_icon, _ = require("nvim-web-devicons").get_icon(ctx.label)
                    if dev_icon then
                      icon = dev_icon
                    end
                  else
                    icon = require("lspkind").symbolic(ctx.kind, {
                      mode = "symbol",
                    })
                  end

                  -- if type(icon) == nil then
                  --  local icons = require('core/ui').icons
                  --  icon = icons.kinds.Copilot
                  -- end

                  return icon .. ' ' .. ctx.icon_gap
                end,
                -- Optionally, use the highlight groups from nvim-web-devicons
                -- You can also add the same function for `kind.highlight` if you want to
                -- keep the highlight groups in sync with the icons.
                highlight = function(ctx)
                  local hl = ctx.kind_hl
                  if vim.tbl_contains({ "Path" }, ctx.source_name) then
                    -- local highlights_info = require("colorful-menu").blink_components_highlight(ctx)
                    -- if highlights_info ~= nil then
                    --  hl = highlights_info.highlights
                    -- end
                    local dev_icon, dev_hl = require("nvim-web-devicons").get_icon(ctx.label)
                    if dev_icon then
                      hl = dev_hl
                    end
                  end
                  return hl
                end,
              },
              label = {
                text = function(ctx)
                  return require("colorful-menu").blink_components_text(ctx)
                end,
                highlight = function(ctx)
                  return require("colorful-menu").blink_components_highlight(ctx)
                end,
              },
            },
            -- -- components = {
            -- --   kind_icon = {
            -- --     text = function(ctx)
            -- --       local icon = ctx.kind_icon
            -- --       if vim.tbl_contains({ "Path" }, ctx.source_name) then
            -- --         local dev_icon, _ = require("nvim-web-devicons").get_icon(ctx.label)
            -- --         if dev_icon then
            -- --           icon = dev_icon
            -- --         end
            -- --       else
            -- --         icon = require("lspkind").symbolic(ctx.kind, {
            -- --           mode = "symbol",
            -- --         })
            -- --       end

            -- --       return icon .. ctx.icon_gap
            -- --     end,

            -- --     -- Optionally, use the highlight groups from nvim-web-devicons
            -- --     -- You can also add the same function for `kind.highlight` if you want to
            -- --     -- keep the highlight groups in sync with the icons.
            -- --     highlight = function(ctx)
            -- --       local hl = ctx.kind_hl
            -- --       if vim.tbl_contains({ "Path" }, ctx.source_name) then
            -- --         local dev_icon, dev_hl = require("nvim-web-devicons").get_icon(ctx.label)
            -- --         if dev_icon then
            -- --           hl = dev_hl
            -- --         end
            -- --       end
            -- --       return hl
            -- --     end,
            -- --   },
            -- --   label = {
            -- --     text = function(ctx)
            -- --       return require("colorful-menu").blink_components_text(ctx)
            -- --     end,
            -- --     highlight = function(ctx)
            -- --       return require("colorful-menu").blink_components_highlight(ctx)
            -- --     end,
            -- --   },
            -- -- },
            -- components = {
            --   label = {
            --     width = { fill = true, max = 60 },
            --     text = function(ctx)
            --       local icon = ctx.kind_icon
            --       if vim.tbl_contains({ "Path" }, ctx.source_name) then
            --         local dev_icon, _ = require("nvim-web-devicons").get_icon(ctx.label)
            --         if dev_icon then
            --           icon = dev_icon
            --         end
            --       else
            --         icon = require("lspkind").symbolic(ctx.kind, {
            --           mode = "symbol",
            --         })
            --       end
            --       local highlights_info = require("colorful-menu").blink_highlights(ctx)
            --       if highlights_info ~= nil then
            --         vim_item.abbr_hl_group = highlights_info.highlights
            --         vim_item.abbr = highlights_info.text
            --         icon = highlights_info
            --       end

            --       return icon .. '  ' .. ctx.icon_gap
            --     end,
            --     highlight = function(ctx)
            --       local highlights = {}
            --       local highlights_info = require("colorful-menu").blink_highlights(ctx)
            --       if highlights_info ~= nil then
            --         highlights = highlights_info.highlights
            --       end
            --       for _, idx in ipairs(ctx.label_matched_indices) do
            --         table.insert(highlights, { idx, idx + 1, group = "BlinkCmpLabelMatch" })
            --       end
            --       -- Do something else
            --       return highlights
            --     end,
            --   },
            -- },
          },
          -- Avoid overlapping with the ghost text
          -- https://cmp.saghen.dev/recipes.html#avoid-multi-line-completion-ghost-text
          direction_priority = function()
            local ctx = require('blink.cmp').get_context()
            local item = require('blink.cmp').get_selected_item()
            if ctx == nil or item == nil then return { 's', 'n' } end

            local item_text = item.textEdit ~= nil and item.textEdit.newText or item.insertText or item.label
            local is_multi_line = item_text:find('\n') ~= nil

            -- after showing the menu upwards, we want to maintain that direction
            -- until we re-open the menu, so store the context id in a global variable
            if is_multi_line or vim.g.blink_cmp_upwards_ctx_id == ctx.id then
              vim.g.blink_cmp_upwards_ctx_id = ctx.id
              return { 'n', 's' }
            end
            return { 's', 'n' }
          end,
        },
        documentation = {
          window = {
            border = nil,
            scrollbar = false,
            winhighlight = 'Normal:BlinkCmpDoc,FloatBorder:BlinkCmpDocBorder,EndOfBuffer:BlinkCmpDoc',
          },
          auto_show = false,
          auto_show_delay_ms = 10000,
          -- Try to prevent duplicate documentation
          treesitter_highlighting = true,
        },
        list = {
          max_items = 50, -- Maximum number of items to display
          selection = { preselect = function(ctx) return not require('blink.cmp').snippet_active({ direction = 1 }) end, auto_insert = true },
          cycle = {
            -- When `true`, calling `select_next` at the _bottom_ of the completion list
            -- will select the _first_ completion item.
            from_bottom = true,
            -- When `true`, calling `select_prev` at the _top_ of the completion list
            -- will select the _last_ completion item.
            from_top = true,
          },
        },
        accept = {
          -- experimental auto-brackets support
          auto_brackets = {
            enabled = true,
          },
        },
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
          -- Which directions to show the window,
          -- falling back to the next direction when there's not enough space,
          -- or another window is in the way
          -- direction_priority = { 'n', 's' },
          direction_priority = function()
            local ctx = require('blink.cmp').get_context()
            local item = require('blink.cmp').get_selected_item()
            if ctx == nil or item == nil then return { 's', 'n' } end

            local item_text = item.textEdit ~= nil and item.textEdit.newText or item.insertText or item.label
            local is_multi_line = item_text:find('\n') ~= nil

            -- after showing the menu upwards, we want to maintain that direction
            -- until we re-open the menu, so store the context id in a global variable
            if is_multi_line or vim.g.blink_cmp_upwards_ctx_id == ctx.id then
              vim.g.blink_cmp_upwards_ctx_id = ctx.id
              return { 'n', 's' }
            end
            return { 's', 'n' }
          end,
          -- Can accept a function if you need more control
          -- direction_priority = function()
          --   if condition then return { 'n', 's' } end
          --   return { 's', 'n' }
          -- end,

          -- Disable if you run into performance issues
          treesitter_highlighting = true,
          show_documentation = false,
        },
      }
    }
  }
}
