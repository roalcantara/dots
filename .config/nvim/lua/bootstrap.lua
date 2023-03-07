local path = require('etc/fn/path')
_G.err = require('etc/fn/log').err
_G.info = require('etc/fn/log').info
_G.imports = require('etc/fn/imports')
_G.is_headless = require('etc/fn/is-headless')
_G.has_plugin = require('etc/fn/has_plugin')
local clone
clone = function(onComplete)
  local handle
  vim.fn.setenv('MACOSX_DEPLOYMENT_TARGET', '10.15')
  handle = vim.loop.spawn('git', {
    args = {
      'clone',
      '--depth',
      '1',
      path.packer.url,
      path.packer.path()
    }
  }, vim.schedule_wrap(function(_, _)
    handle:close()
    return vim.cmd('packadd packer.nvim')
  end))
end
local bootstrap
bootstrap = function(onComplete)
  if path.packer.exists() and (onComplete and type(onComplete) == 'function') then
    return onComplete()
  end
  if vim.fn.executable('git') ~= 1 then
    return _G.err('[packer] Bootstrap failed, git is required!')
  end
  if path.packer.plugins.exists() then
    vim.fn.delete(path.packer.plugins.path())
  end
  return clone(onComplete)
end
return bootstrap
