local M = {}

local function get_nvim_version(on_result)
  ---@async
  return coroutine.create(function()
    if vim and vim.version then
      on_result(' (v' .. vim.version.major .. '.' .. vim.version.minor .. '.' .. vim.version.patch .. ')')
      coroutine.yield()
    end
  end)
end

local function get_lazy_version(on_result)
  ---@async
  return coroutine.create(function()
    local ok, lazy_config = pcall(require, 'lazy/core/config')
    if ok and lazy_config and lazy_config.version and type(lazy_config.version) == 'string' then
      on_result(' (Lazy v' .. lazy_config.version .. ')')
      coroutine.yield()
    end
  end)
end

local function get_versions()
  local output = {}

  local on_result = function(value)
    table.insert(output, value)
  end
  local nvim_version_routine = get_nvim_version(on_result)
  local lazyvim_version_routine = get_lazy_version(on_result)

  coroutine.resume(nvim_version_routine)
  coroutine.resume(lazyvim_version_routine)

  while nvim_version_routine ~= 'dead' and lazyvim_version_routine ~= 'dead' do
    return table.concat(output, ' / ')
  end
end

M.header = function()
  return [[
      ███╗   ██╗ ██╗   ██╗ ██╗ ███╗   ███╗
      ████╗  ██║ ██║   ██║ ██║ ████╗ ████║
      ██╔██╗ ██║ ██║   ██║ ██║ ██╔████╔██║
      ██║╚██╗██║ ╚██╗ ██╔╝ ██║ ██║╚██╔╝██║
      ██║ ╚████║  ╚████╔╝  ██║ ██║ ╚═╝ ██║
      ╚═╝  ╚═══╝   ╚═══╝   ╚═╝ ╚═╝     ╚═╝
    ]] .. get_versions()
end

return M
