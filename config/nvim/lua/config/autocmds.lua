-- [[ Basic Autocommands ]]
--  See `:help lua-guide-autocommands`

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.hl.on_yank()`
local lsp_features = require('core/vi/lsp/features')

-- Set up autocommands for handling several events asynchronously
-- https://neovim.io/doc/user/lua-guide.html#lua-guide-autocommand-create
-- https://neovim.io/doc/user/lua-guide.html#lua-guide-autocommands-group
-- https://lazyvim.org/configuration/general#auto-commands
require('core/vi/au').setup_autocommands_async({
  -- Only autocommands LazyVim does NOT already provide live here.
  -- checktime / highlight_yank / resize_splits / last_loc / man_unlisted /
  -- wrap_spell / json_conceal / auto_create_dir are all registered by
  -- lazyvim/config/autocmds.lua — do not re-add them.
  close_with_q_or_esc = {
    {
      event = 'FileType',
      opts = {
        pattern = {
          'aerial',
          'checkhealth',
          'dbout',
          'DressingSelect',
          'floaterm',
          'gitsigns-blame',
          'grug-far',
          'help',
          'Jaq',
          'lazy',
          'lir',
          'lsp-installer',
          'lspinfo',
          'LspsagaCodeAction',
          'LspsagaDiagnostic',
          'LspsagaFinder',
          'LspsagaFloaterm',
          'LspsagaHover',
          'LspsagaRename',
          'LspsagaSignatureHelp',
          'LspSignatureHelp',
          'man',
          'markdown',
          'neotest-output-panel',
          'neotest-output',
          'neotest-summary',
          'noice',
          'notify',
          'null-ls-info',
          'PlenaryTestPopup',
          'qf',
          'snacks_notif_history',
          'snacks_notif_log',
          'snacks_notif',
          'snacks_picker_list',
          'snacks_win',
          'spectre_panel',
          'startuptime',
          'trouble',
          'Trouble',
          'TroubleToggle',
          'tsplayground',
          'unix',
        },
        callback = function(event)
          vim.bo[event.buf].buflisted = false
          vim.keymap.set('n', 'q', function()
            vim.cmd('close')
            pcall(vim.api.nvim_buf_delete, event.buf, { force = true })
          end, {
            buffer = event.buf,
            desc = 'Quit buffer (q)',
          })
          vim.keymap.set('n', '<Esc>', function()
            vim.cmd('close')
            pcall(vim.api.nvim_buf_delete, event.buf, { force = true })
          end, {
            buffer = event.buf,
            desc = 'Quit buffer (<Esc>)',
          })
        end,
        desc = 'Close buffer with <Esc>',
      },
    },
  },
  on_open_term = {
    {
      event = 'TermOpen',
      opts = {
        callback = function()
          vim.opt.number = false
          vim.opt.relativenumber = false
          vim.cmd('startinsert')
        end,
      },
    },
  },
  on_lsp_attach = {
    {
      event = 'LspAttach',
      opts = {
        callback = function(ev)
          -- Handle LspAttach events emitted by LSP clients in a group whose name starts with "on_lsp_attach"
          -- When the LSP client starts Nvim sets various default options, mappings, and diagnostics
          -- https://neovim.io/doc/user/lsp.html#lsp-defaults | https://neovim.io/doc/user/diagnostic.html#diagnostic-defaults | https://gpanders.com/blog/whats-new-in-neovim-0-11
          local client = vim.lsp.get_client_by_id(ev.data.client_id)
          if client ~= nil and vim.api.nvim_buf_is_valid(ev.buf) then
            lsp_features.setup_capabilities(client, ev.buf, ev)
          end
        end,
        desc = 'LSP Attach: Setup LSP capabilities when an non-null client attaches to a valid buffer',
      },
    },
  },
  on_vim_enter_or_color_scheme = {
    {
      -- URL detection and opening functionality
      -- https://github.com/sontungexpt/url-open
      event = { 'VimEnter', 'ColorScheme' },
      opts = {
        callback = function()
          local colors = require('tokyonight.colors').setup()
          vim.api.nvim_set_hl(0, 'UrlOpenHighlight', {
            fg = colors.orange,
            underline = true,
            bold = true,
          })
        end,
        desc = 'Set up custom highlight group for URLs',
      },
    },
  },
})
