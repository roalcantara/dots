return _G.imports('cmp', function(cmp)
  return _G.imports('lspkind', function(lspkind)
    local feedkeys = require('etc/map/feed_keys')
    local has_words_before_cursor = require('etc/fn/has_words_before_cursor')
    local source_mapping = {
      vsnip = '🔖 vsnip',
      buffer = '⚗️ buffer',
      nvim_lua = '🌙 nvim',
      nvim_lsp = '🌙 lsp',
      treesitter = '🌳 sitter',
      spell = '🚨 spell',
      path = 'PATH',
      zsh = 'zsh',
      cmdline = 'cmdline',
      conventionalcommits = 'conventionalcommits'
    }
    local get_kind
    get_kind = function(kind)
      return string.format('%s %s', lspkind.presets.default[kind], kind)
    end
    local get_menu
    get_menu = function(entry)
      return source_mapping[entry.source.name]
    end
    vim.cmd([[    " gray
    highlight! CmpItemAbbrDeprecated guibg=NONE gui=strikethrough guifg=#808080

    " blue
    highlight! CmpItemAbbrMatch guibg=NONE guifg=#569CD6
    highlight! CmpItemAbbrMatchFuzzy guibg=NONE guifg=#569CD6

    " light blue
    highlight! CmpItemKindVariable guibg=NONE guifg=#9CDCFE
    highlight! CmpItemKindInterface guibg=NONE guifg=#9CDCFE
    highlight! CmpItemKindText guibg=NONE guifg=#9CDCFE

    " pink
    highlight! CmpItemKindFunction guibg=NONE guifg=#C586C0
    highlight! CmpItemKindMethod guibg=NONE guifg=#C586C0

    " front
    highlight! CmpItemKindKeyword guibg=NONE guifg=#D4D4D4
    highlight! CmpItemKindProperty guibg=NONE guifg=#D4D4D4
    highlight! CmpItemKindUnit guibg=NONE guifg=#D4D4D4
    ]])
    return cmp.setup({
      preselect = cmp.PreselectMode.None,
      snippet = {
        expand = function(params)
          return vim.fn['vsnip#anonymous'](params.body)
        end
      },
      window = {
        completion = cmp.config.window.bordered(),
        documentation = cmp.config.window.bordered()
      },
      mapping = cmp.mapping.preset.insert({
        ['<Esc>'] = cmp.mapping.abort(),
        ['<CR>'] = cmp.mapping.confirm({
          behavior = cmp.ConfirmBehavior.Replace,
          select = true
        }),
        ['<Tab>'] = cmp.mapping(function(fallback)
          if cmp.visible() then
            return cmp.select_next_item()
          end
          if vim.fn['vsnip#available'](1) == 1 then
            return feedkeys('<Plug>(vsnip-expand-or-jump)', '')
          end
          if has_words_before_cursor() then
            return cmp.complete()
          end
          return fallback()
        end, {
          'i',
          's'
        }),
        ['<S-Tab>'] = cmp.mapping(function(fallback)
          if cmp.visible() then
            return cmp.select_prev_item()
          end
          if vim.fn['vsnip#jumpable'](-1) == 1 then
            return feedkeys('<Plug>(vsnip-jump-prev)', '')
          end
          return fallback()
        end, {
          'i',
          's'
        })
      }),
      sources = cmp.config.sources({
        {
          name = 'vsnip'
        },
        {
          name = 'nvim_lsp'
        },
        {
          name = 'path'
        },
        {
          name = 'nvim_lua'
        },
        {
          name = 'spell'
        },
        {
          name = 'zsh'
        },
        {
          name = 'git'
        },
        {
          name = 'cmdline'
        },
        {
          name = 'treesitter'
        },
        {
          name = 'conventionalcommits'
        },
        {
          name = 'buffer',
          option = {
            get_bufnrs = function()
              return {
                vim.api.nvim_get_current_buf()
              }
            end
          }
        }
      }),
      formatting = {
        deprecated = true,
        format = function(entry, vim_item)
          vim_item.menu = get_menu(entry)
          vim_item.kind = get_kind(entry.kind)
          return vim_item
        end
      },
      view = {
        entries = 'native'
      },
      experimental = {
        ghost_text = false
      },
      matching = {
        disallow_fuzzy_matching = false,
        disallow_partial_matching = false,
        disallow_prefix_unmatching = false
      }
    })
  end)
end)
