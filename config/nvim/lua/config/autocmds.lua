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
  -- LazyVim's `lazyvim_close_with_q` group already binds `q` (with
  -- vim.schedule + silent) for its own filetype list. We only add the
  -- filetypes it does not cover, and the extra <Esc> binding.
  close_with_esc = {
    {
      event = 'FileType',
      opts = {
        pattern = {
          'aerial',
          'DressingSelect',
          'floaterm',
          'help',
          'Jaq',
          'lazy',
          'lir',
          'lsp-installer',
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
          'noice',
          'null-ls-info',
          'snacks_notif_history',
          'snacks_notif_log',
          'snacks_notif',
          'snacks_picker_list',
          'snacks_win',
          'Trouble',
          'trouble',
          'TroubleToggle',
          'unix',
        },
        callback = function(event)
          vim.bo[event.buf].buflisted = false
          vim.schedule(function()
            for _, lhs in ipairs({ 'q', '<Esc>' }) do
              vim.keymap.set('n', lhs, function()
                vim.cmd('close')
                pcall(vim.api.nvim_buf_delete, event.buf, { force = true })
              end, {
                buffer = event.buf,
                silent = true,
                desc = 'Quit buffer',
              })
            end
          end)
        end,
        desc = 'Close extra filetypes with q or <Esc>',
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
})
