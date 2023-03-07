-- vscode-like pictograms for neovim lsp completion items
-- https://github.com/onsails/lspkind-nvim
_G.imports 'lspkind', (plugin) ->
  plugin.init{
    mode: 'symbol_text', -- enables text annotations
    preset: 'default', -- 'default' | 'codicons' (requires vscode-codicons font installed)
    symbol_map: { -- override preset symbols
      Text: '',
      Method: 'ƒ',
      Function: '',
      Constructor: '',
      Field: 'ﰠ',
      Variable: '',
      Class: '',
      Interface: 'ﰮ',
      Module: '',
      Property: '',
      Unit: '',
      Value: '',
      Enum: '了',
      Keyword: '',
      Snippet: '﬌',
      Color: '',
      File: '',
      Reference: '',
      Folder: '',
      EnumMember: '',
      Constant: '',
      Struct: '',
      Event: '',
      Operator: '',
      TypeParameter: ''
    }
  }
