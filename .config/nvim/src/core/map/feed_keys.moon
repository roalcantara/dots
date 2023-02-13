tcodes = require 'core/map/tcodes'

feedkeys = (args, mode)->
  if type(args) == 'string'
    vim.api.nvim_feedkeys(tcodes(args, true, true, true), mode, true)
  else
    vim.api.nvim_feedkeys(tcodes(args[1], args[2], args[3], args[4]), mode, true)

return feedkeys
