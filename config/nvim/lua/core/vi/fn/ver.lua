local M = {}

local function puts(...)
  return print(vim.inspect(table.concat({ ... }, " ")))
end

--- Get the current Neovim version
--- @return string The current Neovim _VERSION
local get_nvim_version = function()
  puts("[get_nvim_version] 1..")
  local version = vim.version()
  puts("[get_nvim_version] 2.. => '" .. vim.inspect(version) .. "'")
  local full_version = version.major .. "." .. version.minor .. "." .. version.patch
  puts("[get_nvim_version] 3.. => '" .. full_version .. "'")
  return full_version
end

--- Get the current LazyVim version
--- @return string The current LazyVim version
local get_lazyvim_version = function()
  local is_loaded, plugin = pcall(require, 'lazy/core/config')
  if is_loaded then
    return plugin.version
  end
  return "No version found"
end


M.get_nvim_version_async = function(callback)
  puts("[get_nvim_version_async]() 1.. callback: " .. vim.inspect(callback))
  local version = get_nvim_version()
  puts("[get_nvim_version_async]() 2.. => '" .. version .. "'")
  if version then
    puts("[get_nvim_version_async]() 3.. => '" .. version .. "'")
    callback(version)
  else
    puts("[get_nvim_version_async]() 5..")
    callback("No version found")
  end
end

M.get_lazyvim_version_async = function(timeout)
  return function(callback)
    vim.defer_fn(function()
      local version = get_lazyvim_version()
      if version then
        callback(version)
      else
        callback("No version found")
      end
    end, timeout)
  end
end

return M
