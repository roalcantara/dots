return {
  'neovim/nvim-lspconfig',
  dependencies = {
    "mason.nvim",
    { "mason-org/mason-lspconfig.nvim", config = function() end },
    {
      "mason-org/mason.nvim",
      opts = {
        ensure_installed = {
          "stylua",
          "shfmt",
        },
        automatic_installation = true, -- Automatically install missing servers
      }
    }
  },
  opts = function()
    ---@class PluginLspOpts
    local ret = {
      -- options for vim.diagnostic.config()
      ---@type vim.diagnostic.Opts
      diagnostics = {
        underline = true,
        update_in_insert = false,
        virtual_text = {
          spacing = 4,
          source = "if_many",
          prefix = "●",
          -- this will set set the prefix to a function that returns the diagnostics icon based on the severity
          -- this only works on a recent 0.10.0 build. Will be set to "●" when not supported
          -- prefix = "icons",
        },
        severity_sort = true,
        signs = {
          text = {
            [vim.diagnostic.severity.ERROR] = LazyVim.config.icons.diagnostics.Error,
            [vim.diagnostic.severity.WARN] = LazyVim.config.icons.diagnostics.Warn,
            [vim.diagnostic.severity.HINT] = LazyVim.config.icons.diagnostics.Hint,
            [vim.diagnostic.severity.INFO] = LazyVim.config.icons.diagnostics.Info,
          },
        },
      },
      -- Enable this to enable the builtin LSP inlay hints on Neovim >= 0.10.0
      -- Be aware that you also will need to properly configure your LSP server to
      -- provide the inlay hints.
      inlay_hints = {
        enabled = true,
        exclude = { "vue" }, -- filetypes for which you don't want to enable inlay hints
      },
      -- Enable this to enable the builtin LSP code lenses on Neovim >= 0.10.0
      -- Be aware that you also will need to properly configure your LSP server to
      -- provide the code lenses.
      codelens = {
        enabled = false,
      },
      -- add any global capabilities here
      capabilities = {
        workspace = {
          fileOperations = {
            didRename = true,
            willRename = true,
          },
        },
      },
      -- options for vim.lsp.buf.format
      -- `bufnr` and `filter` is handled by the LazyVim formatter,
      -- but can be also overridden when specified
      format = {
        formatting_options = nil,
        timeout_ms = nil,
      },
      servers = {
        lua_ls = {
          -- mason = false, -- set to false if you don't want this server to be installed with mason
          -- Use this to add any additional keymaps
          -- for specific lsp servers
          -- ---@type LazyKeysSpec[]
          -- keys = {},
          settings = {
            Lua = {
              workspace = {
                checkThirdParty = false,
              },
              codeLens = {
                enable = true,
              },
              completion = {
                callSnippet = "Replace",
              },
              doc = {
                privateName = { "^_" },
              },
              hint = {
                enable = true,
                setType = false,
                paramType = true,
                paramName = "Disable",
                semicolon = "Disable",
                arrayIndex = "Disable",
              },
            },
          },
        },
        gopls = {
          cmd = { "gopls" },                                          -- Command to start the language server
          filetypes = { "go", "gomod", "gowork", "gotmpl", "gosum" }, -- File types that this server will handle
          root_markers = { "go.mod", "go.work", ".git" },             -- Markers to identify the root of the project
          settings = {                                                -- Settings for the language server
            gopls = {
              gofumpt = true,
              codelenses = {
                gc_details = false,
                generate = true,
                regenerate_cgo = true,
                run_govulncheck = true,
                test = true,
                tidy = true,
                upgrade_dependency = true,
                vendor = true,
              },
              hints = {
                assignVariableTypes = true,
                compositeLiteralFields = true,
                compositeLiteralTypes = true,
                constantValues = true,
                functionTypeParameters = true,
                parameterNames = true,
                rangeVariableTypes = true,
              },
              analyses = {
                nilness = true,
                unusedparams = true,
                unusedwrite = true,
                useany = true,
              },
              usePlaceholders = true,
              completeUnimported = true,
              staticcheck = true,
              directoryFilters = { "-.git", "-.vscode", "-.idea", "-.vscode-test", "-node_modules" },
              semanticTokens = true,
            },
          },
        },
      },
      ---@type table<string, fun(server:string, opts:_.lspconfig.options):boolean?>
      setup = {
        -- example to setup with typescript.nvim
        -- tsserver = function(_, opts)
        --   require("typescript").setup({ server = opts })
        --   return true
        -- end,
        -- Specify * to use this function as a fallback for any server
        -- ["*"] = function(server, opts) end,
      },
    }

    LazyVim.lsp.on_attach(function(client, ev)
      vim.keymap.set('n', 'gd', vim.lsp.buf.definition, 'GoTo Definition')
      vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, 'Doc Symbols')
      vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, 'Dynamic Symbols')
      vim.keymap.set('n', 'gr', vim.lsp.buf.references, "GoTo References")
      vim.keymap.set('n', 'K', vim.lsp.buf.hover, 'Hover')
      vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, 'Signature Help')
      vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, 'Rename')
      vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, 'Code Actions')
      vim.keymap.set('n', '<leader>wf', function() vim.lsp.buf.format({ async = true }) end, 'Format')
    end)
  end
}
