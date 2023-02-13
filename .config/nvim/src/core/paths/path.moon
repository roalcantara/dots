-- Returns the path to a file on the standard paths.
-- @param standardpath 'cache'        String  Cache directory: arbitrary temporary storage for plugins, etc.
-- @param standardpath 'config'       String  User configuration directory. init.vim is stored here.
-- @param standardpath 'config_dirs'  List    Other configuration directories.
-- @param standardpath 'data'         String  User data directory.
-- @param standardpath 'data_dirs'    List    Other data directories.
-- @param standardpath 'log'          String  Logs directory (for use by plugins too).
-- @param standardpath 'run'          String  Run directory: temporary, local storage for sockets, named pipes, etc.
-- @param standardpath 'state'        String  Session state directory: storage for file drafts, swap, undo, shada.
-- @param path string @to append
-- @return string @The path
stdpath = (standardpath, path)->
  return vim.fn.stdpath(standardpath) .. '/'..path if path
  vim.fn.stdpath(standardpath)

to_dots = (path)->
  return vim.fn.getenv('XDG_CONFIG_HOME') .. '/'..path if path
  vim.fn.getenv('XDG_CONFIG_HOME')

exists = (path)-> vim.fn.empty(vim.fn.glob(path)) == 0
to_config = (path)-> stdpath('config', path)
to_data = (path)-> stdpath('data', path)
to_cache = (path)-> stdpath('cache', path)
to_debug = (path)-> stdpath('cache', 'debug/'..path)
to_log = (path)-> stdpath('log', path)
to_pack = (path)-> to_data('site/pack/' .. path)
to_packer_start = (path)-> to_pack('packer/start/' .. path)

path = {
  --- @param path string @to append to ~/.config
  --- @return string the given arg concatenated with $XDG_CONFIG_HOME
  dots: to_dots,

  --- @param path string @to append to ~/.config/nvim
  --- @return string the given arg concatenated with the config folder
  config: to_config,

  --- @param path string @to append to ~/.local/share/nvim/@path
  --- @return string the given arg concatenated with the data folder
  data: to_data,

  --- @param path string @to append to ~/.cache/nvim/@path
  --- @return string the given arg concatenated with the cache folder
  cache: to_cache,

  --- @param path string @to append to ~/.cache/nvim/debug
  --- @return string the given arg concatenated with the debug folder
  debug: to_debug,

  --- Checks if a path is a readable file.
  --- @return boolean retuls true if path is a readable file
  exists: exists,

  --- @param path string @to append to ~/.cache/nvim/debug/log/@path
  --- @return string the given arg concatenated with the path to the log file
  log: to_log,

  --- @return string the path to ~/.local/share/nvim/session
  session: ()->  to_cache('session'),

  --- @return string the path to ~/.local/share/nvim/undo
  undo: ()->  to_data('undo'),

  --- @return string the path to ~/.local/share/nvim/backup
  backup: ()-> to_data('backup'),

  --- @return string the path to ~/.local/share/nvim/view
  view: ()-> to_data('view'),

  --- @return string the path to ~/.local/share/nvim/swap
  swap: ()-> to_data('swap'),

  --- @return string the path to ~/.local/share/nvim/spell
  spellfile: ()-> to_data('spell/en.utf-8.add'),

  --- @return string the path to ~/.config/snippets
  snippets: ()-> to_dots('snippets'),

  lsp: {
    path: ()-> to_data('mason/bin'),
    --- @param path string @paths to append to ~/.local/share/nvim/mason/bin/@path
    --- @return string the given arg concatenated with the path to a installed language server
    path_to: (path)-> to_data('mason/bin/' .. path),
    --- @param lang string @paths to append to neo/etc/lsp/langs/@lang
    --- @return string @the path to LSP custom settings
    config: (lang)-> 'neo/etc/lsp/lang/' .. lang,
  },
  packer: {
    --- @param path string @paths to append to neo/etc/lsp/langs/@path
    --- @return string the path to ~/.local/share/nvim/site/pack/
    root: to_pack,
    --- @param path string @paths to append to neo/etc/lsp/langs/@path
    --- @return string the path to ~/.local/share/nvim/site/pack/packer/start/plugin
    start: to_packer_start,
    --- @return string the path to ~/.local/share/nvim/site/pack/packer/start/packer.nvim
    path: ()-> to_packer_start('packer.nvim'),
    --- @return boolean true if the path to ~/.local/share/nvim/site/pack/packer/start/packer.nvim exists
    exists: ()-> exists(to_packer_start('packer.nvim'))
  }
}

return path
