return {
  {
    'saghen/blink.cmp',
    dependencies = {
      'disrupted/blink-cmp-conventional-commits',
      'fang2hou/blink-copilot',
      {
        'Kaiser-Yang/blink-cmp-git',
        dependencies = { 'nvim-lua/plenary.nvim' },
      },
      'xzbdmw/colorful-menu.nvim',
    },
    opts = function(_, opts)
      local ui_helper = require('core/ui/ui_helper')
      local paths = require('core/vi/paths')

      -- Configure native snippets
      opts.snippets = {
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
      }

      -- Configure custom appearance kind icons
      opts.appearance = {
        use_nvim_cmp_as_default = false,
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
      }

      -- Configure cmdline completion
      opts.cmdline = {
        enabled = true,
        keymap = { preset = 'cmdline' },
        completion = {
          trigger = {
            show_on_blocked_trigger_characters = {},
            show_on_x_blocked_trigger_characters = {},
          },
          list = {
            selection = {
              preselect = true,
              auto_insert = true,
            },
          },
          menu = {
            auto_show = function(ctx)
              return vim.fn.getcmdtype() == ':' or ctx.mode == 'cmdwin'
            end,
          },
          ghost_text = { enabled = true },
        }
      }

      -- Configure custom sources integration
      opts.sources = {
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
            score_offset = 100,
          },
          lsp = {
            name = 'LSP',
            module = 'blink.cmp.sources.lsp',
            transform_items = function(_, items)
              return vim.tbl_filter(function(item)
                return item.kind ~= require('blink.cmp.types').CompletionItemKind.Text
              end, items)
            end,
            opts = { tailwind_color_icon = '██' },
            enabled = true,
            async = false,
            timeout_ms = 2000,
            should_show_items = true,
            max_items = nil,
            min_keyword_length = 0,
            fallbacks = { 'buffer' },
            score_offset = 0,
            override = nil,
          },
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
                return paths.bufcwd(context.bufnr)
              end,
              show_hidden_files_by_default = false,
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
            opts = {
              complete_func = function()
                return vim.bo.omnifunc
              end,
            },
          },
        },
      }

      -- Configure custom keymaps
      opts.keymap = {
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
          'fallback_to_mappings',
        },
        ['<S-Tab>'] = {
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
      }

      -- Configure custom drawing columns for colorful-menu
      opts.completion = {
        menu = {
          enabled = true,
          border = nil,
          min_width = 15,
          max_height = 20,
          winblend = 0,
          scrolloff = 2,
          scrollbar = false,
          auto_show = true,
          draw = {
            align_to = 'label',
            padding = { 1, 1 },
            gap = 2,
            cursorline_priority = 10000,
            treesitter = { 'lsp' },
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
            columns = { { 'kind_icon' }, { 'label', gap = 1 } },
          },
          direction_priority = ui_helper.detect_window_direction_order_priority,
        },
        documentation = {
          window = {
            border = nil,
            scrollbar = false,
            winhighlight = 'Normal:BlinkCmpDoc,FloatBorder:BlinkCmpDocBorder,EndOfBuffer:BlinkCmpDoc',
          },
          auto_show = false,
          auto_show_delay_ms = 10000,
          treesitter_highlighting = true,
        },
        list = {
          max_items = 200,
          selection = {
            preselect = function(ctx)
              return not require('blink.cmp').snippet_active({ direction = 1 })
            end,
            auto_insert = true,
          },
          cycle = {
            from_bottom = true,
            from_top = true,
          },
        },
        accept = {
          auto_brackets = {
            enabled = true,
          },
        },
        ghost_text = {
          enabled = true,
          show_with_selection = true,
          show_without_selection = false,
          show_with_menu = true,
          show_without_menu = true,
          },
        }

      opts.signature = {
        enabled = false,
        trigger = {
          enabled = false,
          show_on_keyword = false,
          blocked_trigger_characters = {},
          blocked_retrigger_characters = {},
          show_on_trigger_character = true,
          show_on_insert = false,
          show_on_insert_on_trigger_character = true,
        },
        window = {
          min_width = 1,
          max_width = 100,
          max_height = 10,
          border = 'rounded',
          winblend = 0,
          winhighlight = 'Normal:BlinkCmpSignatureHelp,FloatBorder:BlinkCmpSignatureHelpBorder',
          scrollbar = false,
          direction_priority = ui_helper.detect_window_direction_order_priority,
          treesitter_highlighting = true,
          show_documentation = false,
        },
      }

      opts.fuzzy = { implementation = 'prefer_rust_with_warning' }
    end,
  },
}
