-- A completion plugin for neovim coded in Lua.
-- https://github.com/hrsh7th/nvim-cmp
-- https://github.com/neovim/nvim-lspconfig/wiki/Autocompletion
_G.imports 'cmp', (cmp) ->
  _G.imports 'lspkind', (lspkind) ->
    feedkeys = require 'etc/map/feed_keys'
    has_words_before_cursor = require 'etc/fn/has_words_before_cursor'
    source_mapping = {
      vsnip: '🔖 vsnip',
      buffer: '⚗️ buffer',
      nvim_lua: '🌙 nvim',
      nvim_lsp: '🌙 lsp',
      treesitter: '🌳 sitter',
      spell: '🚨 spell',
      path: 'PATH',
      zsh: 'zsh',
      cmdline: 'cmdline',
      conventionalcommits: 'conventionalcommits'
    }
    get_kind = (kind) -> string.format('%s %s', lspkind.presets.default[kind], kind)
    get_menu = (entry) -> source_mapping[entry.source.name]

    vim.cmd[[
    " gray
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
    ]]

    cmp.setup({
      preselect: cmp.PreselectMode.None,
      snippet: {
        expand: (params) ->
          vim.fn['vsnip#anonymous'](params.body) -- For `vsnip` user.
      },
      window: {completion: cmp.config.window.bordered!, documentation: cmp.config.window.bordered!},
      mapping: cmp.mapping.preset.insert {
        ['<Esc>']: cmp.mapping.abort!,
        ['<CR>']: cmp.mapping.confirm({behavior: cmp.ConfirmBehavior.Replace, select: true}),
        ['<Tab>']: cmp.mapping((fallback) ->
          return cmp.select_next_item! if cmp.visible!
          return feedkeys('<Plug>(vsnip-expand-or-jump)', '') if vim.fn['vsnip#available'](1) == 1
          return cmp.complete! if has_words_before_cursor!
          fallback!,
          {'i', 's'}
        ),
        ['<S-Tab>']: cmp.mapping((fallback) ->
          return cmp.select_prev_item! if cmp.visible!
          return feedkeys('<Plug>(vsnip-jump-prev)', '') if vim.fn['vsnip#jumpable'](-1) == 1
          fallback!,
          {'i', 's'}
        )
      },
      sources: cmp.config.sources({
        {name: 'vsnip'},
        {name: 'nvim_lsp'},
        {name: 'path'},
        {name: 'nvim_lua'},
        {name: 'spell'},
        {name: 'zsh'},
        {name: 'git'},
        {name: 'cmdline'},
        {name: 'treesitter'},
        {name: 'conventionalcommits'},
        {name: 'buffer', option: {get_bufnrs: () -> {vim.api.nvim_get_current_buf!}}}
      }),
      formatting: {
        deprecated: true,
        format: (entry, vim_item) ->
          vim_item.menu = get_menu(entry)
          vim_item.kind = get_kind(entry.kind)
          vim_item
      },
      view: {entries: 'native'},
      experimental: {ghost_text: false},
      matching: {disallow_fuzzy_matching: false, disallow_partial_matching: false, disallow_prefix_unmatching: false}
    })
