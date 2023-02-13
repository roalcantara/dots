local path = require('core/paths/path')
local build
build = function(client, bufnr, _)
  return require('neo/lib/functions/imports')('lsp_signature', function(plugin)
    if client.server_capabilities.signature_help then
      return plugin.on_attach({
        debug = false,
        log_path = path.log('lsp_signature.log'),
        verbose = false,
        bind = true,
        doc_lines = 10,
        floating_window = true,
        floating_window_above_cur_line = true,
        fix_pos = false,
        hint_enable = true,
        hint_prefix = '🐼 ',
        hint_scheme = 'String',
        use_lspsaga = false,
        hi_parameter = 'LspSignatureActiveParameter',
        max_height = 12,
        max_width = 120,
        transpancy = nil,
        handler_opts = {
          border = 'single'
        },
        always_trigger = false,
        auto_close_after = nil,
        extra_trigger_chars = { },
        zindex = 200,
        padding = '',
        shadow_blend = 36,
        shadow_guibg = 'Black',
        timer_interval = 200,
        toggle_key = nil
      }, bufnr)
    end
  end)
end
return build
