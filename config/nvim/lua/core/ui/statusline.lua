local icons = require('core/ui/icons/icons_list')
local paths = require('core/vi/paths')
local lsp_utils = require('core/vi/lsp/utils')
local storage = require('core/neo/storage')
local formatters = require('core/ui/formatters')
local auto_dismiss = require('core/ui/auto_dismiss')

local function get_noice()
  return storage.memo('statusline::noice_api', function()
    if not package.loaded['noice'] then
      return nil
    end
    return require('noice').api.status
  end)
end

local function get_color_by_name(color_name)
  return storage.memo('statusline::color', Snacks.util.color, color_name)
end

local function get_package(package_name)
  return storage.memo('statusline::package', function(name)
    if not package.loaded[name] then
      return nil
    end
    return require(name)
  end, package_name)
end

local function get_package_value(package_name, eval_fn)
  local package = get_package(package_name)
  if package then
    return eval_fn(package)
  end
  return false
end

local function get_noice_status_prop(component_name, prop_name)
  local noice = get_noice()
  if noice and noice[component_name] then
    local ok, result = pcall(noice[component_name][prop_name])
    if ok then return result end
  end
  return prop_name == 'get' and '' or false
end

-- Generic noice component factory
-- https://github.com/folke/noice.nvim?tab=readme-ov-file#-statusline-components
local function create_noice_component(component_name, color_name)
  return {
    function()
      return get_noice_status_prop(component_name, 'get')
    end,
    cond = function()
      return get_noice_status_prop(component_name, 'has')
    end,
    color = function()
      return { fg = get_color_by_name(color_name) }
    end,
  }
end

local function create_package_component(props)
  return {
    function()
      return get_package_value(props.package, props.eval_fn)
    end,
    icons_enabled = type(props.icon) ~= 'nil',
    icon = props.icon,
    cond = function()
      return get_package_value(props.package, props.cond_fn)
    end,
    color = function()
      return { fg = get_color_by_name(props.color or 'Statement') }
    end,
    on_click = props.on_click,
  }
end

local function refresh(scope, ...)
  local places = { ... }
  if #places == 0 then
    places = { 'statusline', 'winbar', 'tabline' }
  end

  return require('lualine').refresh({
    force = true,
    scope = scope,
    place = places,
  })
end

local M = {}

function M.status(icon, status)
  local colors = {
    ok = 'Special',
    error = 'DiagnosticError',
    pending = 'DiagnosticWarn',
  }
  return {
    function()
      return icon
    end,
    cond = function()
      return status() ~= nil
    end,
    color = function()
      return { fg = Snacks.util.color(colors[status()] or colors.ok) }
    end,
  }
end

M.sessions = {
  lualine_c = {
    root_basename = function()
      local basename = paths.basename({ buf = vim.api.nvim_get_current_buf(), normalize = true })

      return {
        function()
          return '󱉭 ' .. basename
        end,
        cond = function()
          return type(basename) == 'string'
        end,
        color = function()
          return { fg = get_color_by_name('Special') }
        end
      }
    end,
    diagnostics = {
      'diagnostics',
      symbols = storage.memo('statusline::diagnostics', function()
        return {
          error = icons.diagnostics.Error,
          warn = icons.diagnostics.Warn,
          info = icons.diagnostics.Info,
          hint = icons.diagnostics.Hint,
        }
      end, 'symbols'),
      on_click = function()
        vim.schedule(function()
          vim.cmd('LspToggleDiagnostics')
        end)
      end,
    }
  },
  lualine_x = {
    copilot = M.status(icons.kinds.Copilot, function()
      local clients = package.loaded['copilot']
        and lsp_utils.get_clients({ name = 'copilot', bufnr = 0 })
        or {}
      if #clients > 0 then
        local status = require('copilot.api').status.data.status
        return (status == 'InProgress' and 'pending') or (status == 'Warning' and 'error') or 'ok'
      end
    end),
    formatters = {
      formatters.create_lualine_component(),
      on_click = formatters.create_click_handler(),
    },
    message = auto_dismiss.create_noice_component_with_dismiss('message', 'Constant', 3000),  -- last line of the last message (event=show_msg) - auto-dismiss after 3s
    command = auto_dismiss.create_noice_component_with_dismiss('command', 'Statement', 2000), -- showcmd - auto-dismiss after 2s
    mode = auto_dismiss.create_noice_component_with_dismiss('mode', 'Constant', 1500),        -- showmode (@recording messages) - auto-dismiss after 1.5s
    search = auto_dismiss.create_noice_component_with_dismiss('search', 'Statement', 4000),   -- @search (for search count messages) - auto-dismiss after 4s
    dap = auto_dismiss.create_package_component_with_dismiss({
      package = 'dap',
      eval_fn = function(package) return package.status() end,
      cond_fn = function(package) return package.status() ~= '' end,
      color = 'Debug',
      icon = ''
    }, 5000), -- auto-dismiss after 5s
    lazy = create_package_component({
      package = 'lazy.status',
      eval_fn = function(lazy_package) return lazy_package.updates() end,
      cond_fn = function(lazy_package) return lazy_package.has_updates() end,
      on_click = function()
        vim.schedule(function()
          vim.cmd [[Lazy sync]]
          refresh('window', 'statusline')
        end)
      end,
      color = 'Special'
    }),
    diff = {
      'diff',
      symbols = storage.memo('statusline::diff', function()
        return {
          added = icons.git.added,
          modified = icons.git.modified,
          removed = icons.git.removed,
        }
      end, 'gitsigns'),
      source = function()
        local gitsigns = vim.b.gitsigns_status_dict
        if gitsigns then
          return {
            added = gitsigns.added,
            modified = gitsigns.changed,
            removed = gitsigns.removed,
          }
        end
      end,
    }
  },
  lualine_z = {
    time = {
      function()
        return storage.memo('statusline::time', function()
          return ' ' .. os.date('%R')
        end, os.date('%Y%m%d%H%M'))
      end,
    }
  }
}

return M
