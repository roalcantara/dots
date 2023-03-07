path = require('etc/fn/path')
_G.err = require('etc/fn/log').err
_G.info = require('etc/fn/log').info
_G.imports = require('etc/fn/imports')
_G.is_headless = require('etc/fn/is-headless')
_G.has_plugin = require('etc/fn/has_plugin')

clone = (onComplete)->
  local handle
  vim.fn.setenv('MACOSX_DEPLOYMENT_TARGET', '10.15')
  handle = vim.loop.spawn('git',
    { args: { 'clone', '--depth', '1', path.packer.url, path.packer.path! } },
    vim.schedule_wrap((_, _)->
      -- Wrapper to call `init` based on the success of the above `git` operation
      handle\close!
      vim.cmd('packadd packer.nvim')
    )
  )

---Bootstrap packer
---@return boolean result is true if packer is installed
bootstrap = (onComplete) ->
  if path.packer.exists! and (onComplete and type(onComplete) == 'function')
    return onComplete!

  if vim.fn.executable('git') ~= 1
    return _G.err('[packer] Bootstrap failed, git is required!')

  if path.packer.plugins.exists!
    vim.fn.delete(path.packer.plugins.path!)

  clone(onComplete)

return bootstrap
