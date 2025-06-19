local M = {
  neovim = {
    -- Check for Neovim 0.11+ which includes native LSP configuration
    has_native_lsp_api = vim.fn.has('nvim-0.11') == 1 or vim.fn.has('nvim-0.10') == 1 or vim.fn.has('nvim-0.10.0') == 1,
    has_deprecated_sign_api = vim.fn.has('nvim-0.10.0') == 0,
    -- Specific check for 0.11+ features
    has_lsp_config_api = vim.fn.has('nvim-0.11') == 1,
  }
}

function M.get_gen_animation_none(modenae)
  local locaded, gen_animation_none = pcall(require(modenae))
  if not locaded then
    return function() return 0 end -- Default to no animation if module not found
  end
  return gen_animation_none()
end

---Set up default LSP configurations
---@describing Configuration defined for the '*' name. 2. Configuration from the result of merging all tables returned by lsp/<name>.lua files in 'runtimepath' for a server of name name. 3. Configurations defined anywhere else.
---@usage The merge semantics of configurations follow the behaviour of vim.tbl_deep_extend().
function M.setup_defaults()
  -- Set default LSP configurations
  vim.lsp.config('*', {
    capabilities = {
      textDocument = {
        semanticTokens = {
          multilineTokenSupport = true,
        }
      }
    },
    root_markers = { '.git' },
  })
end

---Enable each server using the native API
function M.enable_servers()
  -- Enable each server using the native API
  local configs = {}
  for _, v in ipairs(vim.api.nvim_get_runtime_file('lsp/*', true)) do
    local name = vim.fn.fnamemodify(v, ':t:r')
    configs[name] = true
  end

  -- Enable LSP features globally
  print('Enabling LSP servers: ' .. vim.inspect(vim.tbl_keys(configs)))
  vim.lsp.enable(vim.tbl_keys(configs))
end

--- Configure LSP features
function M.config_features()
  -- Enable inlay hints globally
  vim.api.nvim_create_autocmd('LspAttach', {
    callback = function(args)
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      if client and client.supports_method('textDocument/inlayHint') then
        vim.lsp.inlay_hint.enable(true, { bufnr = args.buf })
      end
    end,
  })
end

--- [STEP 4]: Set up diagnostic configuration on Neovim 0.11+
--- https://youtu.be/IZnhl121yo0
function M.setup_diagnostic_config()
  vim.diagnostic.config({
    virtual_text = true,
    underline = true,
    update_in_insert = false,
    severity_sort = true,
    float = {
      border = 'rounded',
      source = true,
    },
    signs = {
      text = {
        [vim.diagnostic.severity.ERROR] = 'E',
        [vim.diagnostic.severity.WARN] = 'W',
        [vim.diagnostic.severity.INFO] = 'I',
        [vim.diagnostic.severity.HINT] = 'H',
      },
      numhl = {
        [vim.diagnostic.severity.ERROR] = 'DiagnosticSignError',
        [vim.diagnostic.severity.WARN] = 'DiagnosticSignWarn',
        [vim.diagnostic.severity.INFO] = 'DiagnosticSignInfo',
        [vim.diagnostic.severity.HINT] = 'DiagnosticSignHint',
      },
    }
  })
end

--- [STEP 4]: Set up keymaps (optional - LazyVim usually handles this)
function M.on_lsp_buf_attach_setup_Keymaps()
  vim.api.nvim_create_autocmd('LspAttach', {
    group = vim.api.nvim_create_augroup('UserLspConfig', { clear = true }),
    callback = function(ev)
      local map = function(keys, func, desc)
        vim.keymap.set('n', keys, func, { buffer = ev.buf, desc = 'Lsp: ' .. desc })
      end
      -- Basic LSP keymaps
      map('gd', vim.lsp.buf.definition, 'GoTo Definition')
      map('gD', vim.lsp.buf.declaration, 'Doc Symbols')
      map('gi', vim.lsp.buf.implementation, 'Dynamic Symbols')
      map('gr', vim.lsp.buf.references, "GoTo References")
      map('K', vim.lsp.buf.hover, 'Hover')
      map('<C-k>', vim.lsp.buf.signature_help, 'Signature Help')
      map('<leader>rn', vim.lsp.buf.rename, 'Rename')
      map('<leader>ca', vim.lsp.buf.code_action, 'Code Actions')
      map('<leader>wf', vim.lsp.buf.format({ async = true }), 'Format')

      vim.keymap.set('v', '<leader>ca', vim.lsp.fuf.code_action, { buffer = ev.buf, desc = 'Lsp: Code Actions' })
    end,
  })
end

--- Set up autocompletions on LSP attach (using native Neovim 0.11+ completion)
function M.on_lsp_attach_setup_auto_completions()
  return vim.api.nvim_create_autocmd('LspAttach', {
    group = vim.api.nvim_create_augroup('LspCompletions', { clear = true }),
    callback = function(ev)
      local client = vim.lsp.get_client_by_id(ev.data.client_id)
      if client and client.supports_method('textDocument/completion') then
        -- Enable native Neovim 0.11+ completion
        if vim.lsp.completion and vim.lsp.completion.enable then
          vim.lsp.completion.enable(true, client.id, ev.buf, {
            autotrigger = true
          })
        end

        -- Set omnifunc for fallback
        vim.bo[ev.buf].omnifunc = 'v:lua.vim.lsp.omnifunc'

        -- Configure buffer-specific completion settings for VSCode-like behavior
        vim.api.nvim_buf_set_option(ev.buf, 'completeopt', 'menu,menuone,noselect')
        vim.b[ev.buf].completion = true

        -- Enhanced trigger characters for this buffer
        local capabilities = client.server_capabilities or {}
        if capabilities.completionProvider then
          local trigger_chars = capabilities.completionProvider.triggerCharacters or {}
          local common_triggers = { '.', ':', '->', '::', '#', '@' }
          for _, char in ipairs(common_triggers) do
            if not vim.tbl_contains(trigger_chars, char) then
              table.insert(trigger_chars, char)
            end
          end
          capabilities.completionProvider.triggerCharacters = trigger_chars
        end
      end
    end,
  })
end

--- Set up LSP servers using the native API - if available
function M.setup_servers()
  -- https://neovim.io/doc/user/news-0.11.html
  -- https://gpanders.com/blog/whats-new-in-neovim-0-11/
  if M.neovim.has_native_lsp_api then
    vim.lsp.enable({
      "gopls",
      "luaa_ls"
    })

    vim.diagnostic.config({
      virtual_text = true,
      underline = true,
      update_in_insert = false,
      severity_sort = true,
      float = {
        border = 'rounded',
        source = true,
      },
      signs = {
        text = {
          [vim.diagnostic.severity.ERROR] = 'E',
          [vim.diagnostic.severity.WARN] = 'W',
          [vim.diagnostic.severity.INFO] = 'I',
          [vim.diagnostic.severity.HINT] = 'H',
        },
        numhl = {
          [vim.diagnostic.severity.ERROR] = 'DiagnosticSignError',
          [vim.diagnostic.severity.WARN] = 'DiagnosticSignWarn',
          [vim.diagnostic.severity.INFO] = 'DiagnosticSignInfo',
          [vim.diagnostic.severity.HINT] = 'DiagnosticSignHint',
        },
      }
    })

    -- -- [STEP 0th] -- Enable LSP servers
    -- M.enable_servers()

    -- -- [STEP 1st] -- Set up default LSP configurations
    -- M.config_features()

    -- -- [STEP 3rd] -- Set up default LSP configurations
    -- M.setup_diagnostic_config()

    -- -- [STEP 4th] -- Set up keymaps (optional - LazyVim usually handles this)
    -- M.on_lsp_attach_setup_auto_completions()
  else
    print('Neovim version 0.11 or higher is required for native LSP support.')
    print('Please update Neovim to use the latest LSP features.')
    return
  end
end

return M
