local get_runtime_path
get_runtime_path = function()
  local runtime_path = vim.split(package.path, ';')
  table.insert(runtime_path, 'lua/?.lua')
  table.insert(runtime_path, 'lua/?/init.lua')
  return runtime_path
end
local build
build = function(on_attach, capabilities)
  local status, neodev = pcall(require, 'neodev')
  if status then
    neodev.setup()
  end
  return {
    on_attach = on_attach,
    capabilities = capabilities,
    settings = {
      Lua = {
        runtime = {
          version = 'LuaJIT',
          path = get_runtime_path()
        },
        completion = {
          enable = true,
          callSnippet = 'Both',
          keywordSnippet = 'Replace',
          displayContext = 1,
          requireSeparator = '/',
          showParams = true,
          showWord = 'Fallback',
          workspaceWord = true
        },
        diagnostics = {
          enable = true,
          globals = {
            'Color',
            'c',
            'Group',
            'g',
            's',
            'pcall',
            'package',
            'table',
            'require'
          },
          libraryFiles = 'Opened'
        },
        workspace = {
          library = vim.api.nvim_get_runtime_file('', true),
          maxPreload = 2000,
          preloadFileSize = 50000,
          checkThirdParty = false
        },
        format = {
          enable = true
        },
        telemetry = {
          enable = false
        },
        hint = {
          enable = true,
          await = true,
          paramName = 'All',
          paramType = true,
          semicolon = 'SameLine'
        }
      }
    }
  }
end
return build
