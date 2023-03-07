return _G.imports('null-ls', function(plugin)
  local formatting = plugin.builtins.formatting
  local diagnostics = plugin.builtins.diagnostics
  local augroup = vim.api.nvim_create_augroup('LspFormatting', { })
  local nixfmt = {
    method = plugin.methods.FORMATTING,
    filetypes = {
      'nix'
    },
    generator = plugin.formatter({
      command = 'nixfmt',
      to_stdin = true
    })
  }
  local statixfmt = {
    method = plugin.methods.FORMATTING,
    filetypes = {
      'nix'
    },
    generator = plugin.formatter({
      command = 'statix',
      args = {
        'fix',
        '--stdin'
      },
      to_stdin = true
    })
  }
  local jsonfmt = {
    method = plugin.methods.FORMATTING,
    filetypes = {
      'json'
    },
    generator = plugin.formatter({
      command = 'jq',
      to_stdin = true
    })
  }
  local nixlinter = {
    method = plugin.methods.DIAGNOSTICS,
    filetypes = {
      'nix'
    },
    generator = plugin.generator({
      command = 'nix-linter',
      args = {
        '--json',
        '-'
      },
      to_stdin = true,
      from_stderr = true,
      format = 'json',
      check_exit_code = function(code)
        return code <= 1
      end,
      on_output = function(params)
        local diags = { }
        for _, d in ipairs(params.output) do
          table.insert(diags, {
            row = d.pos.spanBegin.sourceLine,
            col = d.pos.spanBegin.sourceColumn,
            end_col = d.pos.spanEnd.sourceColumn,
            code = d.offending,
            message = d.description,
            severity = 1
          })
        end
        return diags
      end
    })
  }
  local async_formatting
  async_formatting = function(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    return vim.lsp.buf_request(bufnr, 'textDocument/formatting', {
      textDocument = {
        uri = vim.uri_from_bufnr(bufnr)
      }
    }, function(err, res, ctx)
      if err then
        local err_msg = type(err) == 'string' and err or err.message
        vim.notify('formatting: ' .. err_msg, vim.log.levels.WARN)
        return 
      end
      if not vim.api.nvim_buf_is_loaded(bufnr) or vim.api.nvim_buf_get_option(bufnr, 'modified') then
        return 
      end
      if res then
        local client = vim.lsp.get_client_by_id(ctx.client_id)
        vim.lsp.util.apply_text_edits(res, bufnr, client and client.offset_encoding or 'utf-16')
        return vim.api.nvim_buf_call(bufnr, function()
          return vim.cmd('silent noautocmd update')
        end)
      end
    end)
  end
  return plugin.setup({
    debug = true,
    debounce = 150,
    sources = {
      nixfmt,
      statixfmt,
      jsonfmt,
      nixlinter,
      formatting.prettier,
      formatting.stylua,
      diagnostics.shellcheck,
      formatting.shfmt,
      formatting.rustfmt,
      formatting.black,
      diagnostics.pylint,
      diagnostics.hadolint,
      diagnostics.vint,
      diagnostics.statix
    },
    on_attach = function(client, bufnr)
      if client.server_capabilities.document_formatting then
        vim.api.nvim_clear_autocmds({
          group = augroup,
          buffer = bufnr
        })
        return vim.api.nvim_create_autocmd('BufWritePost', {
          group = augroup,
          buffer = bufnr,
          callback = function()
            return async_formatting(bufnr)
          end
        })
      end
    end
  })
end)
