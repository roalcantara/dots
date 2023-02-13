return require('neo/lib/functions/imports')('navigator', function(plugin)
  local path = require('core/paths/path')
  return plugin.setup({
    debug = false,
    width = 0.75,
    height = 0.3,
    preview_height = 0.35,
    border = {
      '╭',
      '─',
      '╮',
      '│',
      '╯',
      '─',
      '╰',
      '│'
    },
    on_attach = function(client, bufnr) end,
    default_mapping = true,
    keymaps = {
      {
        key = 'gK',
        func = 'declaration()'
      }
    },
    treesitter_analysis = true,
    transparency = 50,
    lsp_signature_help = true,
    signature_help_cfg = nil,
    icons = {
      code_action_icon = '🏏',
      diagnostic_head = '🐛',
      diagnostic_head_severity_1 = '🈲'
    },
    lsp_installer = false,
    lsp = {
      code_action = {
        enable = true,
        sign = true,
        sign_priority = 40,
        virtual_text = true
      },
      code_lens_action = {
        enable = true,
        sign = true,
        sign_priority = 40,
        virtual_text = true
      },
      format_on_save = true,
      disable_format_cap = {
        'sqls',
        'sumneko_lua',
        'gopls'
      },
      disable_lsp = {
        'pylsd',
        'sqlls'
      },
      diagnostic = {
        underline = true,
        virtual_text = true,
        update_in_insert = false
      },
      diagnostic_scrollbar_sign = {
        '▃',
        '▆',
        '█'
      },
      diagnostic_virtual_text = true,
      diagnostic_update_in_insert = false,
      disply_diagnostic_qf = true,
      tsserver = {
        filetypes = {
          'typescript'
        }
      },
      gopls = {
        on_attach = function(client, _bufnr)
          print('i am a hook, I will disable document format')
          client.server_capabilities.document_formatting = false
        end,
        settings = {
          gopls = {
            gofumpt = false
          }
        }
      },
      sumneko_lua = {
        sumneko_root_path = path.lsp('sumneko_lua'),
        sumneko_binary = path.lsp('sumneko_lua/extension/server/bin/lua-language-server')
      },
      servers = { }
    }
  })
end)
