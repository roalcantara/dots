-- Navigate codes like a breeze🎐. Exploring LSP and 🌲Treesitter symbols a piece of 🍰. Take control like a boss 🦍.
-- https://github.com/ray-x/navigator.lua
require('neo/lib/functions/imports') 'navigator', (plugin) ->
  path = require 'core/paths/path'
  plugin.setup({
    debug: false, -- log output, set to true and log path: ~/.cache/nvim/gh.log
    width: 0.75, -- max width ratio (number of cols for the floating window) / (window width)
    height: 0.3, -- max list window height, 0.3 by default
    preview_height: 0.35, -- max height of preview windows
    border: {'╭', '─', '╮', '│', '╯', '─', '╰', '│'}, -- border style, can be one of 'none', 'single', 'double',
    on_attach: (client, bufnr) ->
    default_mapping: true, -- set to false if you will remap every key
    keymaps: {{key: 'gK', func: 'declaration()'}}, -- a list of key maps
    treesitter_analysis: true, -- treesitter variable context
    transparency: 50, -- 0 ~ 100 blur the main window, 100: fully transparent, 0: opaque,  set to nil or 100 to disable it
    lsp_signature_help: true, -- if you would like to hook ray-x/lsp_signature plugin in navigator
    -- setup here. if it is nil, navigator will not init signature help
    signature_help_cfg: nil, -- if you would like to init ray-x/lsp_signature plugin in navigator, and pass in your own config to signature help
    icons: {
      -- Code action
      code_action_icon: '🏏',
      -- Diagnostics
      diagnostic_head: '🐛',
      diagnostic_head_severity_1: '🈲'
      -- refer to lua/navigator.lua for more icons setups
    },
    lsp_installer: false, -- set to true if you would like use the lsp installed by williamboman/nvim-lsp-installer
    lsp: {
      code_action: {enable: true, sign: true, sign_priority: 40, virtual_text: true},
      code_lens_action: {enable: true, sign: true, sign_priority: 40, virtual_text: true},
      format_on_save: true, -- set to false to disable lsp code format on save (if you are using prettier/efm/formater etc)
      disable_format_cap: {'sqls', 'sumneko_lua', 'gopls'}, -- a list of lsp disable format capacity (e.g. if you using efm or vim-codeformat etc), empty {} by default
      disable_lsp: {'pylsd', 'sqlls'}, -- a list of lsp server disabled for your project, e.g. denols and tsserver you may
      -- only want to enable one lsp server
      -- to disable all default config and use your own lsp setup set
      -- disable_lsp = 'all'
      -- Default {}
      diagnostic: {
        underline: true,
        virtual_text: true, -- show virtual for diagnostic message
        update_in_insert: false -- update diagnostic message in insert mode
      },

      diagnostic_scrollbar_sign: {'▃', '▆', '█'}, -- experimental:  diagnostic status in scroll bar area; set to false to disable the diagnostic sign,
      -- for other style, set to {'╍', 'ﮆ'} or {'-', '='}
      diagnostic_virtual_text: true, -- show virtual for diagnostic message
      diagnostic_update_in_insert: false, -- update diagnostic message in insert mode
      disply_diagnostic_qf: true, -- always show quickfix if there are diagnostic errors, set to false if you  want to
      -- ignore it
      tsserver: {
        filetypes: {'typescript'} -- disable javascript etc,
        -- set to {} to disable the lspclient for all filetypes
      },
      gopls: { -- gopls setting
        on_attach: (client, _bufnr) -> -- on_attach for gopls
          -- your special on attach here
          -- e.g. disable gopls format because a known issue https://github.com/golang/go/issues/45732
          print('i am a hook, I will disable document format')
          client.server_capabilities.document_formatting = false,
        settings: {
          gopls: {gofumpt: false} -- disable gofumpt etc,
        }
      },
      sumneko_lua: {
        sumneko_root_path: path.lsp('sumneko_lua'),
        sumneko_binary: path.lsp('sumneko_lua/extension/server/bin/lua-language-server')
      },
      servers: {} -- by default empty, and it should load all LSP clients avalible based on filetype
      -- but if you whant navigator load  e.g. `cmake` and `ltex` for you , you
      -- can put them in the `servers` list and navigator will auto load them.
      -- you could still specify the custom config  like this
      -- cmake = {filetypes = {'cmake', 'makefile'}, single_file_support = false},
    }
  })
