local lsp_features = require('core/vi/lsp/features')

-- Set up autocommands for handling several events asynchronously
-- https://neovim.io/doc/user/lua-guide.html#lua-guide-autocommand-create
-- https://neovim.io/doc/user/lua-guide.html#lua-guide-autocommands-group
-- https://lazyvim.org/configuration/general#auto-commands
require('core/vi/au').setup_autocommands_async({
  checktime = {
    {
      event = { 'FocusGained', 'TermClose', 'TermLeave' },
      opts = {
        callback = function()
          if vim.o.buftype ~= 'nofile' then
            vim.cmd('checktime')
          end
        end,
        desc = 'Check if we need to reload the file when it changed',
      },
    },
  },
  highlight_yank = {
    {
      event = 'TextYankPost',
      opts = {
        callback = function()
          (vim.hl or vim.highlight).on_yank()
        end,
        desc = 'Highlight on yank',
      },
    },
  },
  resize_splits = {
    {
      event = 'VimResized',
      opts = {
        callback = function()
          local current_tab = vim.fn.tabpagenr()
          vim.cmd('tabdo wincmd =')
          vim.cmd('tabnext ' .. current_tab)
        end,
        desc = 'Resize splits when window is resized',
      },
    },
  },
  last_loc = {
    {
      event = 'BufReadPost',
      opts = {
        callback = function(event)
          local exclude = { 'gitcommit' }
          local buf = event.buf
          if vim.tbl_contains(exclude, vim.bo[buf].filetype) or vim.b[buf].neovim_last_loc then
            return
          end
          vim.b[buf].neovim_last_loc = true
          local mark = vim.api.nvim_buf_get_mark(buf, "'")
          local lcount = vim.api.nvim_buf_line_count(buf)
          if mark[1] > 0 and mark[1] <= lcount then
            pcall(vim.api.nvim_win_set_cursor, 0, mark)
          end
        end,
        desc = 'Go to last location when opening a buffer',
      },
    },
  },
  man_unlisted = {
    {
      event = 'FileType',
      opts = {
        pattern = { 'man' },
        callback = function(event)
          vim.bo[event.buf].buflisted = false
        end,
        desc = 'Make it easier to close man-files when opened inline',
      },
    },
  },
  wrap_spell = {
    {
      event = 'FileType',
      opts = {
        pattern = { 'text', 'plaintex', 'typst', 'gitcommit', 'markdown' },
        callback = function(event)
          local buf = event.buf
          vim.opt_local.wrap = true
          vim.opt_local.spell = true
          Neo.debug(('wrap and spell enabled for %s'):format(vim.bo[buf].filetype), { title = 'Options' })
        end,
        desc = 'Enable wrap and check for spell in text filetypes',
      },
    },
  },
  json_conceal = {
    {
      event = 'FileType',
      opts = {
        pattern = { 'json', 'jsonc', 'json5' },
        callback = function()
          vim.opt_local.conceallevel = 0
        end,
        desc = 'Disable conceallevel for json files',
      },
    },
  },
  auto_create_dir = {
    {
      event = 'BufWritePre',
      opts = {
        callback = function(event)
          if event.match:match('^%w%w+:[\\/][\\/]') then
            return
          end
          local file = vim.uv.fs_realpath(event.match) or event.match
          vim.fn.mkdir(vim.fn.fnamemodify(file, ':p:h'), 'p')
        end,
        desc = 'Auto create directory when saving a file, in case some intermediate directory does not exist',
      },
    },
  },
  filetypedetect = {
    {
      event = { 'BufRead', 'BufNewFile' },
      opts = {
        pattern = { '*.yml' },
        command = 'set filetype=yaml',
        desc = 'Setup filetype=yaml for files ended with .yml',
      },
    },
  },
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
        callback = function(opts)
          -- Handle LspAttach events emitted by LSP clients in a group whose name starts with "on_lsp_attach"
          -- When the LSP client starts Nvim sets various default options, mappings, and diagnostics
          -- https://neovim.io/doc/user/lsp.html#lsp-defaults | https://neovim.io/doc/user/diagnostic.html#diagnostic-defaults | https://gpanders.com/blog/whats-new-in-neovim-0-11
          local client = vim.lsp.get_client_by_id(opts.data.client_id)
          if type(client) ~= nil and vim.api.nvim_buf_is_valid(opts.buf) then
            lsp_features.setup_capabilities(client, opts.buf, opts)
          end
        end,
        desc = 'LSP Attach: Setup LSP capabilities when an non-null client attaches to a valid buffer',
      },
    },
  },
  on_mason_tools_install = {
    {
      event = 'User',
      opts = {
        pattern = { 'MasonToolsStartingInstall' },
        callback = function()
          -- Handle user events emitted by mason in a group whose name starts with "on_on_mason_tools_trigger"
          -- https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim?tab=readme-ov-file#events
          -- Handles user event emitted prior installing the first package if there are packages to install.
          Snacks.debug.inspect(string.format("[%s] is starting..", 'mason-tool-installer'))
        end,
        desc = 'Mason: Warns when mason-tool-installer starts to install tools',
      }
    }
  },
  on_mason_tools_completes = {
    {
      event = 'User',
      opts = {
        pattern = { 'MasonToolsUpdateCompleted' },
        callback = function(e)
          -- Handle user events emitted by mason in a group whose name starts with "on_on_mason_tools_trigger"
          -- https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim?tab=readme-ov-file#events
          -- Handles user event emitted upon packages installation/update completes.
          if e.data then
            Snacks.debug.inspect(string.format("[%s] done! ===> %s", 'mason-tool-installer', vim.inspect(e.data)))
          end
        end,
        desc = 'Mason: Warns when mason-tool-installer is done installing/updating tools',
      }
    }
  }
})
