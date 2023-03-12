local sys = require('fn/sys')

local M = {
  plugin_manager = {
    name = 'lazy',
    package = 'lazy.nvim',
  },
  lsp_manager = {
    name = 'mason',
    package = 'mason.nvim',
  },
}

function M.shada()
  return sys.cache('shada')
end

function M.session()
  return sys.cache('session')
end

function M.undo()
  return sys.data('undo')
end

function M.backup()
  return sys.data('backup')
end

function M.view()
  return sys.data('view')
end

function M.swap()
  return sys.data('swap')
end

function M.spellfile()
  return sys.data('spell', 'en.utf-8.add')
end

function M.snippets()
  return sys.xdg_config('snippets')
end

function M.pack(...)
  return sys.data('site', 'pack', ...)
end

function M.plug_opt(...)
  return M.pack(M.plugin_manager.name, 'opt', ...)
end

function M.plug_start(...)
  return M.pack(M.plugin_manager.name, 'start', ...)
end

function M.plug_manager_exists()
  return sys.exists(M.plug_start(M.plugin_manager.package))
end

function M.plugin()
  return sys.config('plugin')
end

function M.lsp_bin(...)
  return sys.data(M.lsp_manager.name, 'bin', ...)
end

function M.lsp_lang(...)
  return sys.join_paths('opt', 'lsp', 'lang', ...)
end

return M
