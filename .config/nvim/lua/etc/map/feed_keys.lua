local tcodes = require('etc/map/tcodes')
local feedkeys
feedkeys = function(args, mode)
  if type(args) == 'string' then
    return vim.api.nvim_feedkeys(tcodes(args, true, true, true), mode, true)
  else
    return vim.api.nvim_feedkeys(tcodes(args[1], args[2], args[3], args[4]), mode, true)
  end
end
return feedkeys
