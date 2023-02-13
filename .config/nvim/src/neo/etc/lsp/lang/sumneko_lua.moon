-- custom_schema = {
--   {
--     description = 'My Custom JSON schema',
--     fileMatch = { 'foobar.json', '.foobar.json' },
--     name = 'foobar.json',
--     url = 'https://example.com/schema/foobar.json',
--   },
-- }
-- custom_schemas = { custom_schema }
get_runtime_path = ()->
  runtime_path = vim.split(package.path, ';')
  table.insert(runtime_path, 'lua/?.lua')
  table.insert(runtime_path, 'lua/?/init.lua')
  runtime_path

-- Builds and returns the dev setup for init.lua and plugin development
-- with full signature help docs and completion for the nvim lua API
-- https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md#sumneko_lua
-- https://github.com/sumneko/lua-language-server
---@param on_attach function
---@param capabilities table
---@return table
build = (on_attach, capabilities)->
  status, neodev = pcall(require, 'neodev')
  neodev.setup! if status

  return {
    on_attach: on_attach,
    capabilities: capabilities,
    settings: {
      Lua: {
        runtime: {
          -- Tell the language server which version of Lua you're using (most likely LuaJIT in the case of Neovim)
          version: 'LuaJIT',
          -- Setup your lua path
          path: get_runtime_path!
        },
        completion: {
          -- Enable/disable completion. Completion works like any autocompletion
          -- you already know of. It helps you type less and get more done.
          enable: true,
          -- Whether to show call snippets or not. When disabled, only the
          -- function name will be completed. When enabled, a "more complete"
          -- snippet will be offered.
          callSnippet: 'Both',
          -- Whether to show a snippet for key words like if, while, etc.
          -- When disabled, only the keyword will be completed.
          -- When enabled, a "more complete" snippet will be offered.
          keywordSnippet: 'Replace',
          -- When a snippet is being suggested, this setting will set the amount
          -- of lines around the snippet to preview to help you better
          -- understand its usage.
          displayContext: 1,
          -- The separator to use when require-ing a file.
          requireSeparator: '/',
          -- Display a function's parameters in the list of completions. When a
          -- function has multiple definitions, they will be displayed
          -- separately.
          showParams: true,
          -- Show "contextual words" that have to do with Lua but are not
          -- suggested based on their usefulness in the current semantic
          -- context.
          showWord: 'Fallback',
          -- Words from other files in the workspace should be suggeste as "contextual words".
          workspaceWord: true
        },
        diagnostics: {
          -- Whether all diagnostics should be enabled or not.
          enable: true,
          -- Get the language server to recognize the `vim` global
          globals: { 'Color', 'c', 'Group', 'g', 's', 'pcall', 'package', 'table', 'require' }, -- Colorbuddy
          -- Set how files loaded with workspace.library are diagnosed.
          libraryFiles: 'Opened'
        },
        workspace: {
          -- Make the server aware of Neovim runtime files
          library: vim.api.nvim_get_runtime_file('', true),
          maxPreload: 2000,
          preloadFileSize: 50000,
          checkThirdParty: false
        },
        format: {
          -- Whether the built-in formatted should be enabled or not.
          enable: true
        },
        -- Do not send telemetry data containing a randomized but unique identifier
        telemetry: { enable: false },
        hint: {
          -- Whether inline hints should be enabled or not.
          enable: true,
          -- If a function has been defined as @async, display an await hint when it is being called.
          await: true,
          -- Whether parameter names should be hinted when typing out a function call.
          paramName: 'All',
          -- Show a hint for parameter types at a function definition. Requires @param
          paramType: true,
          -- Whether to show a hint to add a semicolon to the end of a statement.
          semicolon: 'SameLine'
        }
      }
    }
  }

return build
