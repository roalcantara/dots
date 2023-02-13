-- Snippet plugin for vim/nvim that supports LSP/VSCode's snippet format
-- https://github.com/hrsh7th/vim-vsnip
path = require('core/paths/path')
require('core/vi/var').set({
  vsnip_snippet_dir: path.snippets!, -- Specify system snippet directories
  vsnip_filetypes: { -- Specify extended filetypes.
    javascriptreact: { -- For example, you can extend `javascript` filetype with `javascriptreact` filetype.
      'javascript'
    },
    typescriptreact: {'typescript'}
  },
  vsnip_choice_delay: 500, -- Specify delay time to show choice candidates.
  vsnip_sync_delay: 0 -- Specify delay time to sync snippet.
})
