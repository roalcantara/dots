-- Use Neovim as a language server to inject LSP diagnostics, code actions, and more via Lua.
-- https://github.com/jose-elias-alvarez/null-ls.nvim
-- https://alpha2phi.medium.com/neovim-for-beginners-lsp-using-null-ls-nvim-bd954bf86b40
-- https://www.youtube.com/watch?v=ryxRpKpM9B4
require('neo/lib/functions/imports') 'null-ls', (plugin) ->
  formatting = plugin.builtins.formatting
  diagnostics = plugin.builtins.diagnostics
  augroup = vim.api.nvim_create_augroup('LspFormatting', {})

  nixfmt = {
    method: plugin.methods.FORMATTING,
    filetypes: {'nix'},
    generator: plugin.formatter{command: 'nixfmt', to_stdin: true}
  }

  statixfmt = {
    method: plugin.methods.FORMATTING,
    filetypes: {'nix'},
    generator: plugin.formatter{command: 'statix', args: {'fix', '--stdin'}, to_stdin: true}
  }

  jsonfmt = {
    method: plugin.methods.FORMATTING,
    filetypes: {'json'},
    generator: plugin.formatter{command: 'jq', to_stdin: true}
  }

  nixlinter = {
    method: plugin.methods.DIAGNOSTICS,
    filetypes: {'nix'},
    generator: plugin.generator{
      command: 'nix-linter',
      args: {'--json', '-'},
      to_stdin: true,
      from_stderr: true,
      format: 'json', -- choose an output format (raw, json, or line)
      check_exit_code: (code)-> code <= 1,
      on_output: (params) ->
        diags = {}
        for _, d in ipairs(params.output) do
          table.insert(diags, {
            row: d.pos.spanBegin.sourceLine,
            col: d.pos.spanBegin.sourceColumn,
            end_col: d.pos.spanEnd.sourceColumn,
            code: d.offending,
            message: d.description,
            severity: 1
          })
        diags
      -- on_output = h.diagnostics.from_pattern {
      --   {
      --     pattern = [[ (.*) at (\.\/.*):(\d+):(\d+)]],
      --     groups = { 'message', 'file', 'row', 'col' },
      --   },
      -- },
    }
  }

  async_formatting = (bufnr) ->
    bufnr = bufnr or vim.api.nvim_get_current_buf!
    vim.lsp.buf_request(bufnr, 'textDocument/formatting', {textDocument: {uri: vim.uri_from_bufnr(bufnr)}},
      (err, res, ctx) ->
        if err
          err_msg = type(err) == 'string' and err or err.message
          -- you can modify the log message / level (or ignore it completely)
          vim.notify('formatting: ' .. err_msg, vim.log.levels.WARN)
          return

        -- don't apply results if buffer is unloaded or has been modified
        return if not vim.api.nvim_buf_is_loaded(bufnr) or vim.api.nvim_buf_get_option(bufnr, 'modified')

        if res
          client = vim.lsp.get_client_by_id(ctx.client_id)
          vim.lsp.util.apply_text_edits(res, bufnr, client and client.offset_encoding or 'utf-16')
          vim.api.nvim_buf_call(bufnr, ()-> vim.cmd('silent noautocmd update'))
    )

  plugin.setup({
    debug: true,
    debounce: 150,
    sources: {
      -- formatting.gofmt,
      -- formatting.goimports,
      -- diagnostics.golint,
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
    on_attach: (client, bufnr) ->
      if client.server_capabilities.document_formatting
        vim.api.nvim_clear_autocmds({group: augroup, buffer: bufnr})
        vim.api.nvim_create_autocmd('BufWritePost', {group: augroup, buffer: bufnr, callback: ()-> async_formatting(bufnr)})
  })
