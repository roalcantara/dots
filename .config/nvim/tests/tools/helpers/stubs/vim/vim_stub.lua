local stub_mixin = require('tools/helpers/stubs/stub_mixin')
local VimStub = {
  _ = {},
  cmd = {},
  g = {},
  opt = {},
  o = {},
  go = {},
  bo = {},
  wo = {},
  b = {},
  w = {},
  t = {},
  v = {},
  env = {},
  fn = require('tools/helpers/stubs/vim/vim_fn_stub'),
  stubs = {}
}
VimStub.__index = VimStub

return stub_mixin(VimStub)
