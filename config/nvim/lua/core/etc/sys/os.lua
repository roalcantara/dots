--- System information utilities with lazy evaluation
local M = {
  -- Cache for expensive operations
  _cache = {},
  join = vim.fs.joinpath,
  normalize = vim.fs.normalize
}

--- Helper function to cache expensive operations
--- @param key string Cache key
--- @param default_fn function Function that computes the value
--- @return any Cached or computed value
local function get(key, default_fn)
  if M._cache[key] == nil then
    M._cache[key] = default_fn()
  end
  return M._cache[key]
end

--- Get uname information (cached)
--- @return table|nil uname information
local function get_uname()
  return get("uname", function()
    return vim.loop.os_uname()
  end)
end

--- Get uname release information (cached)
--- @return string|nil uname release string
local function get_uname_released()
  return get("uname_released", function()
    local uname = get_uname()
    if uname and uname.release then
      return uname.release
    else
      return false -- Cache negative result
    end
  end) or nil
end

--- Check if running on macOS (cached)
--- @return boolean True if macOS
local function is_macos()
  return get("is_macos", function()
    return vim.fn.has("mac") == 1 or vim.fn.has("macunix") == 1
  end)
end

--- Check if running on Windows (cached)
--- @return boolean True if Windows
local function is_windows()
  return get("is_windows", function()
    return vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1
  end)
end

--- Check if running on Linux (cached)
--- @return boolean True if Linux
local function is_linux()
  return get("is_linux", function()
    return vim.fn.has("unix") == 1 and not is_macos()
  end)
end

--- Check if running on FreeBSD (cached)
--- @return boolean True if FreeBSD
local function is_freebsd()
  return get("is_freebsd", function()
    local uname = get_uname()
    local sysname = uname and uname.sysname and uname.sysname:lower() or ""
    return is_linux() or sysname == 'freebsd' or sysname == 'bsd'
  end)
end

--- Check if the operating system is WSL (Windows Subsystem for Linux) (cached)
--- @return boolean true if the operating system is WSL, false otherwise
local function is_wsl()
  return get("is_wsl", function()
    if is_linux() then
      local uname_released = get_uname_released()
      return uname_released and uname_released:lower():match('microsoft') ~= nil
    end
    return false
  end)
end

-- Expose cached functions as properties
M.uname = get_uname()
M.uname_released = get_uname_released()
M.is_wsl = is_wsl()
M.is_windows = is_windows()
M.is_macos = is_macos()
M.is_linux = is_linux()
M.is_freebsd = is_freebsd()

--- Get OS name (cached)
--- @return string OS name
function M.get_name()
  return get("name", function()
    if is_wsl() then
      return "wsl"
    elseif is_windows() then
      return "windows"
    elseif is_macos() then
      return "macos"
    elseif is_linux() then
      return "linux"
    elseif is_freebsd() then
      return "freebsd"
    else
      return "unknown"
    end
  end)
end

--- @return string separator for file paths
function M.get_separator()
  return get("separator", function()
    return is_windows() and "\\" or "/"
  end)
end

function M.get_path_separator()
  return get("path_separator", function()
    return is_windows() and ";" or ":"
  end)
end

--- Get operating system information (cached)
--- @return table OS information with name, is_windows, is_macos, is_linux fields
function M.get_info()
  return get("info", function()
    return {
      name = M.get_name(),
      is_windows = is_windows(),
      is_macos = is_macos(),
      is_linux = is_linux(),
      is_freebsd = is_freebsd(),
      is_wsl = is_wsl(),
      separator = M.get_separator(),
      path_separator = M.get_path_separator(),
    }
  end)
end

--- Get system username (cached)
--- @return string Current username
function M.get_username()
  return get("username", function()
    return vim.fn.expand("$USER") or vim.fn.expand("$USERNAME") or "unknown"
  end)
end

--- Get hostname (cached)
--- @return string System hostname
function M.get_hostname()
  return get("hostname", function()
    return vim.fn.hostname()
  end)
end

--- Check if executable exists in PATH
--- @param cmd string Command name
--- @return boolean True if executable exists
function M.is_executable(cmd)
  -- Initialize executables cache if needed
  if not M._cache.executables then
    M._cache.executables = {}
  end

  -- Use cache_or_compute for individual executables
  if M._cache.executables[cmd] == nil then
    M._cache.executables[cmd] = vim.fn.executable(cmd) == 1
  end

  return M._cache.executables[cmd]
end

--- Clear all cached values (useful for testing or if system state changes)
function M.clear_cache()
  M._cache = {}
end

return M
