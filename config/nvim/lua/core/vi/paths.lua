local sys_os = require('core/etc/sys/os')
local storage = require('core/neo/storage')
local strings = require('core/vi/strings')

-- Path and file system utilities
local M = {
  -- Project root detection utilities
  cache = {},
  spec = { 'lsp', { '.git', 'lua' }, 'cwd' },
  detectors = {},
  sys = sys_os,
  separator = sys_os.get_separator,
  expand = vim.fn.expand,
  basename = vim.fs.basename,
  dirname = vim.fs.dirname,
  homebrew_prefix = vim.env.HOMEBREW_PREFIX or '/opt/homebrew',
}

--- Returns |standard-path| locations of various default files and directories.
--- The locations are driven by |base-directories| which you can configure via |$NVIM_APPNAME| or the `$XDG_…` environment variables.
--- @param what 'cache' | 'config' | 'config_dirs' | 'data' | 'data_dirs' | 'log' | 'run' | 'state' The type of standard path to get
--- @return string The standard path
--- @example
--- ```lua
--- stdpath_base('config') -- => "/Users/user/.config/nvim"
--- stdpath_base('state') -- => "/Users/user/.local/state/nvim"
--- ```
local function stdpath_base(what)
  return storage.memo('paths::stdpath', vim.fn.stdpath, what)
end

--- Join multiple paths
--- @param ... string Paths to join
--- @return string Joined path
function M.join(...)
  local args = { ... } or {}
  return storage.memoize(storage.cache_key('paths::join', ...), function()
    return sys_os.join(unpack(args))
  end)
end

--- Returns |standard-path| locations of various default files and directories.
--- The locations are driven by |base-directories| which you can configure via |$NVIM_APPNAME| or the `$XDG_…` environment variables.
--- @param what 'cache' | 'config' | 'config_dirs' | 'data' | 'data_dirs' | 'log' | 'run' | 'state' The type of standard path to get
--- @param ... string Additional arguments to pass to stdpath
--- @return string The standard path
--- @example
--- ```lua
--- stdpath('config') -- => "/Users/user/.config/nvim"
--- stdpath('state', 'undo') -- => "/Users/user/.local/state/nvim/undo"
--- stdpath('config', 'subdir', 'file.txt') -- => "/Users/user/.config/nvim/subdir/file.txt"
--- ```
function M.stdpath(what, ...)
  local args = { ... } or {}
  return storage.memoize(storage.cache_key('paths::stdpath', what, ...), function()
    return M.join(stdpath_base(what), unpack(args))
  end)
end

--- Get standard Neovim paths
--- @return table Table with config, data, cache, and state paths
function M.get_stdpaths()
  return storage.memo('paths::stdpaths', function()
    return {
      config = M.stdpath('config'),
      data = M.stdpath('data'),
      cache = M.stdpath('cache'),
      state = M.stdpath('state'),
    }
  end)
end

--- Check if a path is a directory
--- @param path string Path to check
--- @return boolean True if path is a directory
function M.is_directory(path)
  return storage.memo('paths::is_directory', function(value)
    return vim.fn.isdirectory(value) == 1
  end, path)
end

--- Ensure a path is a directory
--- @param path string Path to ensure
--- @return string Path to the ensured directory
function M.ensure(path)
  return storage.memo('paths::ensure', function(value)
    if not M.is_directory(value) then
      vim.fn.mkdir(value, 'p')
    end
    return value
  end, path)
end

--- Get the path to the bin for a given name
--- @param name string Name of the bin
--- @return string Path to the bin
function M.bin_for(name)
  return M.join(M.homebrew_prefix, 'bin', name)
end

--- Get the current working directory of a buffer
--- @param bufnr number The buffer number
--- @return string The current working directory of the buffer
function M.bufcwd(bufnr)
  return storage.memo('bufcwd', function(value)
    return vim.fn.expand(('#%d:p:h'):format(value))
  end, bufnr)
end

--- Normalize a path
--- @param path string Path to normalize
--- @return string Normalized path
--- @example
--- ```lua
--- normalize('') -- => ""
--- normalize(nil) -- => ""
--- normalize('.') -- => "."
--- normalise([[C:\Users\jdoe]]) -- => "C:/Users/jdoe"
--- normalise("~/src/neovim") -- => "/home/jdoe/src/neovim"
--- normalise("$XDG_CONFIG_HOME/nvim/init.vim") -- => "/Users/jdoe/.config/nvim/init.vim"
--- normalise("~/src/nvim/api/../tui/./tui.c") -- => "/home/jdoe/src/nvim/tui/tui.c"
--- normalise("./foo/bar") -- => "foo/bar"
--- normalise("foo/../../../bar") -- => "../../bar"
--- normalise("/home/jdoe/../../../bar") -- => "/bar"
--- normalise("C:foo/../../baz") -- => "C:../baz"
--- normalise("C:/foo/../../baz") -- => "C:/baz"
--- normalise([[\\?\UNC\server\share\foo\..\..\..\bar]]) -- => "//?/UNC/server/share/bar"
--- ```
function M.normalize(path)
  return storage.memo('paths::normalize', vim.fs.normalize, path)
end

--- Get the real path of a given path
--- @param path string The path to get the real path of
--- @return string The real path of the given path
function M.realpath(path)
  return storage.memo('paths::realpath', function(value)
    return M.normalize(vim.uv.fs_realpath(value) or value)
  end, path)
end

--- Check if a command is executable
--- @param name string
--- @return boolean true if the command is executable
function M.is_executable(name)
  return storage.memo('paths::is_executable', function(value)
    return vim.fn.executable(value) == 1
  end, name)
end

--- Get the value of an environment variable
--- @param varname string The name of the environment variable
--- @return string The value of the environment variable
function M.getenv(varname)
  return storage.memo('paths::getenv', os.getenv, varname)
end

--- Get the path to the bin for python3 venv
--- @return string The path to the bin for python3 venv
function M.bin_for_python3_venv()
  return storage.memo('paths::bin_for_python3_venv', function(value)
    return M.getenv(value)
      or M.getenv('NEOVIM_PYTHON3_VENV_PATH')
      or M.stdpath('config', '.venv', 'bin', 'python3')
  end, 'VIRTUAL_ENV')
end

-- returns the root directory based on:
-- * lsp workspace folders
-- * lsp root_dir
-- * root pattern of filename of the current buffer
-- * root pattern of cwd
--- @param opts {normalize:boolean, buf:number}
--- @return string
--- @example
--- ```lua
--- get_root({ buf = 1, normalize = true }) -- => "/home/user/test"
--- get_root({ buf = 1, normalize = false }) -- => "~/test"
function M.root_path(opts)
  return storage.memo('paths::root_path', function(value)
    local roots = M.detect({ all = false, buf = opts.buf })
    if roots and roots[1] and roots[1].paths and roots[1].paths[1] then
      local root_path = roots[1].paths[1]
      if opts.normalize then
        return M.normalize(root_path)
      else
        return root_path
      end
    else
      return vim.uv.cwd()
    end
  end, opts.buf, opts.normalize and 'normalized' or 'unnormalized')
end

-- returns the root directory based on:
-- * lsp workspace folders
-- * lsp root_dir
-- * root pattern of filename of the current buffer
-- * root pattern of cwd
--- @param opts {normalize:boolean, buf:number}
--- @return string
function M.basename(opts)
  return storage.memo('paths::basename', function(value)
    local cwd = value[1]
    local root = M.root_path(opts)

    if root == cwd then
      return nil
    end

    return storage.memo('paths::basename', vim.fs.basename, root)
  end, vim.uv.cwd(), opts.buf, opts.normalize and 'normalized' or 'unnormalized')
end

M.stdpaths = {
  config = M.stdpath('config'),
  data = M.stdpath('data'),
  cache = M.stdpath('cache'),
  state = M.stdpath('state'),
  -- https://neovim.io/doc/user/options.html#'undodir'
  undodir = M.stdpath('state', 'undo'),
  --- Return the path to the snippets directory
  --- @return string The path to the snippets directory
  snippets = M.stdpath('config', 'snippets'),
  ensured = {
    undodir = function()
      M.ensure(M.stdpaths.undodir)
      return M.stdpaths.undodir
    end
  }
}

M.lua = {
  runtime = {
    path = {
      '?.lua',
      M.join('?', 'init.lua'),
      M.join('lua', '?.lua'),
      M.join('lua', '?', 'init.lua'),
      M.join(vim.env.VIMRUNTIME, 'lua', '?.lua'),
      M.join(vim.env.VIMRUNTIME, 'lua', '?', 'init.lua'),
      M.stdpath('config', '*', 'lua', '?.lua'),
      M.stdpath('config', '*', 'lua', '?', 'init.lua'),
      M.stdpath('data', 'lazy', '*', 'lua', '?.lua'),
      M.stdpath('data', 'lazy', '*', 'lua', '?', 'init.lua'),
      M.stdpath('data', 'mason', '*', 'lua', '?.lua'),
      M.stdpath('data', 'mason', '*', 'lua', '?', 'init.lua'),
      M.stdpath('data', 'blink', '*', 'lua', '?.lua'),
      M.stdpath('data', 'blink', '*', 'lua', '?', 'init.lua'),
      M.stdpath('data', 'scratch', '*', 'lua', '?.lua'),
      M.stdpath('data', 'scratch', '*', 'lua', '?', 'init.lua'),
      M.stdpath('data', 'snacks', '*', 'lua', '?.lua'),
      M.stdpath('data', 'snacks', '*', 'lua', '?', 'init.lua'),
    },
    special = {
      include = 'require',
      vim = 'require',
      ['vim.loop'] = 'require',
    },
  },
  workspace = {
    library = {
      M.join(vim.env.VIMRUNTIME, 'lua'),
      M.bin_for('lua-language-server'),
      M.stdpath('data', 'lazy', '*', 'lua'),
      M.stdpath('data', 'mason', '*', 'lua'),
      M.stdpath('data', 'blink', '*', 'lua'),
      M.stdpath('data', 'scratch', '*', 'lua'),
      M.stdpath('data', 'snacks', '*', 'lua'),
      '${3rd}/lfs/library',
      '${3rd}/luv/library',
      '${3rd}/busted/library',
      '${3rd}/luassert/library',
      M.stdpath('config', 'lua'),
    },
  },
}

M.lua_runtime_paths = {
  '?.lua',
  M.join('?', 'init.lua'),
  M.join('lua', '?.lua'),
  M.join('lua', '?', 'init.lua'),
  M.stdpath('config', 'lua', '?.lua'),
  M.stdpath('config', 'lua', '?', 'init.lua'),
  M.stdpath('data', 'lazy', '*', 'lua', '?.lua'),
  M.stdpath('data', 'lazy', '*', 'lua', '?', 'init.lua'),
  M.stdpath('data', 'mason', '*', 'lua', '?.lua'),
  M.stdpath('data', 'mason', '*', 'lua', '?', 'init.lua'),
  M.stdpath('data', 'blink', '*', 'lua', '?.lua'),
  M.stdpath('data', 'blink', '*', 'lua', '?', 'init.lua'),
  M.stdpath('data', 'scratch', '*', 'lua', '?.lua'),
  M.stdpath('data', 'scratch', '*', 'lua', '?', 'init.lua'),
  M.stdpath('data', 'snacks', '*', 'lua', '?.lua'),
  M.stdpath('data', 'snacks', '*', 'lua', '?', 'init.lua'),
  M.join(vim.env.VIMRUNTIME, 'lua', '?.lua'),
  M.join(vim.env.VIMRUNTIME, 'lua', '?', 'init.lua'),
  M.join(vim.env.VIMRUNTIME, '*', 'lua', '?.lua'),
  M.join(vim.env.VIMRUNTIME, '*', 'lua', '?', 'init.lua'),
}

function M.get_lua_runtime_paths_items()
  local rtp = M.lua_runtime_paths
  local items = {}

  for _, path in ipairs(rtp) do
    table.insert(items, {
      id = path,
      text = path,
      data = path,
      value = path,
    })
  end

  return items
end

function M.get_runtimepath_path_items()
  local rtp = vim.opt.runtimepath:get_root()
  local items = {}

  for _, path in ipairs(rtp) do
    -- Format display text
    local basename = M.basename(path)
    local display_text = string.format('%-25s %s', basename, path)

    table.insert(items, {
      id = path,
      text = display_text,
      data = path,
      value = path,
    })
  end

  return items
end

--- Get the XDG config home path for a given set of paths
--- @param ... string|string[] Path to XDG_CONFIG_HOME
--- @return string path to XDG_CONFIG_HOME
function M.xdg_config_home(...)
  local xdg_config_home = vim.env.XDG_CONFIG_HOME or M.join(vim.env.HOME, '.config')
  local paths = unpack({ ... }) or {}
  if #paths == 0 then
    return xdg_config_home
  end
  return M.join(xdg_config_home, paths)
end

M.xdg = {
  config_home = M.xdg_config_home,
  config = {
    path = M.xdg_config_home(),
    path_for = function(...) return M.xdg_config_home(...) end,
  }
}


--- Check if a command is available
--- @param name string The name of the command to check
--- @return function True if the command is available, false otherwise
function M.has(name)
  return function()
    return vim.fn.executable(name) == 1
  end
end

return M
