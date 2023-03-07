local path = require('etc/fn/path')
return require('etc/fn/var').set({
  vsnip_snippet_dir = path.snippets(),
  vsnip_filetypes = {
    javascriptreact = {
      'javascript'
    },
    typescriptreact = {
      'typescript'
    }
  },
  vsnip_choice_delay = 500,
  vsnip_sync_delay = 0
})
