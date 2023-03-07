---Builds document_formatting capability.
build = (_, _, _)->
  -- deprecated
  -- https://neovim.io/doc/user/deprecated.html
  vim.cmd[[autocmd CursorHold * lua vim.diagnostic.open_float(0, {scope="line"})]]

return build
