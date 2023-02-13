build = (on_attach, capabilities)->
  vim.cmd[[ autocmd FileType go setlocal omnifunc=v:lua.vim.lsp.omnifunc ]]
  return {
    :on_attach,
    :capabilities,
    settings: {
      gopls: {analyses: {unusedparams: true}, staticcheck: true},
      json: {
        schemas: require('schemastore').json.schemas{select: {'.eslintrc', 'package.json'}},
        validate: {enable: true}
      }
    }
  }

return build
