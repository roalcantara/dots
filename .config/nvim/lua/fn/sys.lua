local api = vim.api
local fn = vim.fn
local M = {}

function M.key(key, fn)
  return fn('neo_' .. tostring(key))
end

function M.store(key, value)
  _G[key] = value
  return value
end

function M.read(key)
  return _G[key]
end

function M.get(k, orElse)
  return M.key(k, function(key)
    return M.read(key) or M.store(key, orElse())
  end)
end

function M.path_sep()
  return M.is_win() and '\\' or '/'
end

---Join path segments that were passed as input
---@return string
function M.join_paths(...)
  local result = table.concat({ ... }, M.path_sep())
  return result
end

function M.stdpath(standardpath)
  return M.get(standardpath, function()
    return vim.fn.stdpath(standardpath)
  end)
end

function M.buld_stdpath(standardpath, ...)
  local path = M.join_paths(...)
  return M.get(standardpath .. M.path_sep() .. path, function()
    return M.join_paths(M.stdpath(standardpath), path)
  end)
end

function M.config(...)
  return M.buld_stdpath('config', ...)
end

function M.data(...)
  return M.buld_stdpath('data', ...)
end

function M.cache(...)
  return M.buld_stdpath('cache', ...)
end

function M.log(...)
  return M.buld_stdpath('log', ...)
end

function M.debug(...)
  return M.cache('debug', ...)
end

function M.xdg_config(...)
  local path = M.join_paths(...)
  return M.get('xdg_config' .. M.path_sep() .. path, function()
    return M.join_paths(M.getenv('XDG_CONFIG_HOME'), path)
  end)
end

function M.getenv(name)
  return vim.fn.getenv(name)
end

function M.nvim_list_uis()
  return M.get('nvim_list_uis', function()
    return #vim.api.nvim_list_uis()
  end)
end

function M.is_headless()
  return M.nvim_list_uis() == 0
end

function M.sysname()
  return M.get('sysname', function()
    return vim.loop.os_uname().sysname
  end)
end

function M.is_win()
  return M.sysname():match('Windows')
end

function M.is_mac()
  return M.sysname():match('Darwin')
end

function M.fs_type_is(path, value)
  local stat = vim.loop.fs_stat(path)
  return stat and stat.type == value or false
end

--- Checks whether a given path exists and is a file.
--@param path (string) path to check
--@returns (bool)
function M.is_file(path)
  return M.fs_type_is(path, 'file')
end

--- Checks whether a given path exists and is a directory
--@param path (string) path to check
--@returns (bool)
function M.is_dir(path)
  return M.fs_type_is(path, 'directory')
end

function M.is_empty(value)
  return vim.fn.empty(value) == 1
end

function M.is_nil(value)
  return type(value) == 'nil'
end

function M.exists(path)
  return M.is_empty(vim.fn.glob(path)) == 0
end

---Write data to a file
---@param path string can be full or relative to `cwd`
---@param txt string|table text to be written, uses `vim.inspect` internally for tables
---@param flag string used to determine access mode, common flags: 'w' for `overwrite` or 'a' for `append`
function M.write_file(path, txt, flag)
  local data = type(txt) == 'string' and txt or vim.inspect(txt)
  vim.loop.fs_open(path, flag, 438, function(open_err, fd)
    assert(not open_err, open_err)
    vim.loop.fs_write(fd, data, -1, function(write_err)
      assert(not write_err, write_err)
      vim.loop.fs_close(fd, function(close_err)
        assert(not close_err, close_err)
      end)
    end)
  end)
end

---Copies a file or directory recursively
---@param source string
---@param destination string
function M.fs_copy(source, destination)
  local source_stats = assert(M.fs_stat(source))

  if source_stats.type == 'file' then
    assert(vim.loop.fs_copyfile(source, destination))
    return
  elseif source_stats.type == 'directory' then
    local handle = assert(vim.loop.fs_scandir(source))

    assert(vim.loop.fs_mkdir(destination, source_stats.mode))

    while true do
      local name = vim.loop.fs_scandir_next(handle)
      if not name then
        break
      end

      M.fs_copy(M.join_paths(source, name), M.join_paths(destination, name))
    end
  end
end

return M
