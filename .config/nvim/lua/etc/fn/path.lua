local stdpath
stdpath = function(standardpath, path)
  if path then
    return vim.fn.stdpath(standardpath) .. '/' .. path
  end
  return vim.fn.stdpath(standardpath)
end
local to_dots
to_dots = function(path)
  if path then
    return vim.fn.getenv('XDG_CONFIG_HOME') .. '/' .. path
  end
  return vim.fn.getenv('XDG_CONFIG_HOME')
end
local exists
exists = function(path)
  return vim.fn.empty(vim.fn.glob(path)) == 0
end
local to_config
to_config = function(path)
  return stdpath('config', path)
end
local to_data
to_data = function(path)
  return stdpath('data', path)
end
local to_cache
to_cache = function(path)
  return stdpath('cache', path)
end
local to_debug
to_debug = function(path)
  return stdpath('cache', 'debug/' .. path)
end
local to_log
to_log = function(path)
  return stdpath('log', path)
end
local to_pack
to_pack = function(path)
  return to_data('site/pack/' .. path)
end
local to_packer_opt
to_packer_opt = function(path)
  return to_pack('packer/opt/' .. path)
end
local to_packer_start
to_packer_start = function(path)
  return to_pack('packer/start/' .. path)
end
local path = {
  dots = to_dots,
  config = to_config,
  data = to_data,
  cache = to_cache,
  debug = to_debug,
  exists = exists,
  log = to_log,
  session = function()
    return to_cache('session')
  end,
  undo = function()
    return to_data('undo')
  end,
  backup = function()
    return to_data('backup')
  end,
  view = function()
    return to_data('view')
  end,
  swap = function()
    return to_data('swap')
  end,
  spellfile = function()
    return to_data('spell/en.utf-8.add')
  end,
  snippets = function()
    return to_dots('snippets')
  end,
  lsp = {
    path = function()
      return to_data('mason/bin')
    end,
    path_to = function(path)
      return to_data('mason/bin/' .. path)
    end,
    config = function(lang)
      return 'opt/lsp/lang/' .. lang
    end
  },
  packer = {
    plugins = {
      path = function()
        return to_config('plugin')
      end,
      exists = function()
        return exists(to_config('plugin'))
      end
    },
    url = 'https://github.com/wbthomason/packer.nvim',
    root = to_pack,
    start = to_packer_start,
    path = function()
      return to_packer_start('packer.nvim')
    end,
    exists = function()
      return exists(to_packer_start('packer.nvim'))
    end
  }
}
return path
