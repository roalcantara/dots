local busted = require('busted')

busted.setup(function()
  -- inspect = require('inspect')
  vim = require('tools/helpers/stubs/vim/vim_stub')
end)

busted.teardown(function()
  vim = nil
  -- inspect = nil
end)
