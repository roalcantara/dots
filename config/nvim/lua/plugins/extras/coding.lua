-- vim.api.nvim_create_augroup wrapper
local autocmd = vim.api.nvim_create_autocmd

-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")
local function augroup(name, opts)
  opts = opts or { clear = true }
  return vim.api.nvim_create_augroup('lazyvim_custom_' .. name, opts)
end

--- Setup LSP Keymaps to LSP BufRead
-- https://neovim.io/doc/user/news-0.11.html#_defaults
local function on_lsp_attach_setup_auto_completions(lsp)
  LazyVim.lsp.on_attach(function(client, buffer)
    if vim.bo[buffer].filetype == "helm" then
      vim.schedule(function()
        vim.cmd("LspStop ++force yamlls")
      end)
    end
  end, lsp)

  LazyVim.lsp.on_attach(function(client, ev)
    if not client.server_capabilities.semanticTokensProvider then
      local semantic = client.config.capabilities.textDocument.semanticTokens
      client.server_capabilities.semanticTokensProvider = {
        full = true,
        legend = {
          tokenTypes = semantic.tokenTypes,
          tokenModifiers = semantic.tokenModifiers,
        },
        range = true,
      }
    end
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
    map('<leader>wf', function() vim.lsp.buf.format({ async = true }) end, 'Format')

    local function client_support_method(client, method, bufnr)
      if vim.fn.has "nvim-0.11" == 1 then
        return client:supports_method(method, bufnr)
      else
        return client.supports_method(method, { bufnr = bufnr })
      end
    end

    local client = vim.lsp.get_client_by_id(client.client_id)
    if client and client_support_method(client, vim.lsp.Methods.textDocument.documentHighlight, ev.buf) then
      local hl_augroup = augroup('LspDocumentHighlight', { clear = false })
      -- When cursor stops moving: highlight all the instances of the symbol under the cursor
      -- When cursor moves: clear the highlights
      autocmd({ 'CursorHold', 'CursorHoldI' }, {
        buffer = ev.buf,
        group = hl_augroup,
        callback = vim.lsp.buf.document_highlight,
        desc = 'Lsp: Highlight symbol under cursor',
      })
      autocmd({ 'CursorMoved', 'CursorMovedI' }, {
        buffer = ev.buf,
        group = hl_augroup,
        callback = vim.lsp.buf.clear_references,
        desc = 'Lsp: Clear symbol highlights',
      })
    end
    -- When LSP is attached: Clear their highlights
    autocmd('LspDetach', {
      buffer = ev.buf,
      group = augroup('LspDocumentDetach'),
      callback = function()
        vim.lsp.buf.clear_references()
        vim.api.nvim_clear_autocmds({ group = 'LspDocumentHighlight', buffer = ev.buf })
      end,
      desc = 'Lsp: Clear highlights on LSP detach',
    })
  end, lsp)
end

require('/core/lsp/init').helpers.setup_servers()

return {
  -- NOICE | A fancy UI for the Neovim command line, messages and notifications
  -- https://github.com/folke/noice.nvim
  {
    'folke/noice.nvim',
    opts = {
      lsp = {
        override = {
          ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
          ["vim.lsp.util.stylize_markdown"] = true,
          ["cmp.entry.get_documentation"] = true,
        },
      },
      routes = {
        {
          filter = {
            event = "msg_show",
            any = {
              { find = "%d+L, %d+B" },
              { find = "; after #%d+" },
              { find = "; before #%d+" },
            },
          },
          view = "mini",
        },
      },
      presets = {
        bottom_search = true,
        command_palette = true,
        long_message_to_split = true,
      },
    },
  },

  {
    "folke/lazydev.nvim",
    ft = "lua", -- only load on lua files
    opts = {
      library = { path = "${3rd}/luv/library", words = { "vim%.uv" } },
      { path = "LazyVim",     words = { "LazyVim" } },
      { path = "snacks.nvim", words = { "Snacks" } },
      { path = "lazy.nvim",   words = { "LazyVim" } },
    },
  },
  {
    "saghen/blink.cmp",
    opts = {
      sources = {
        -- add lazydev to your completion providers
        default = { "lazydev", "lsp", "path", "snippets", "buffer" },
        providers = {
          lazydev = {
            name = "LazyDev",
            module = "lazydev.integrations.blink",
            -- make lazydev completions top priority (see `:h blink.cmp`)
            score_offset = 100,
          },
        },
      },
    },
  },

  {
    "stevearc/conform.nvim",
    dependencies = {
      {
        "mason-org/mason.nvim",
        opts = { ensure_installed = { "goimports", "gofumpt", "gomodifytags", "impl", "delve" } }
      },
      {
        "leoluz/nvim-dap-go", opts = {},
      },
      {
        "echasnovski/mini.icons",
        opts = {
          file = {
            [".go-version"] = { glyph = "", hl = "MiniIconsBlue" },
          },
          filetype = {
            gotmpl = { glyph = "󰟓", hl = "MiniIconsGrey" },
          },
        },
      }
    },
    optional = true,
    opts = {
      formatters_by_ft = {
        lua = { "stylua" },
        go = { "goimports", "gofumpt" },
      }
    }
  },

  -- NVIM-HIGHLIGHT-COLORS | Highlight colors for neovim (VSCode-like color highlighting)
  -- https://github.com/brenoprata10/nvim-highlight-colors
  {
    'brenoprata10/nvim-highlight-colors',
    -- https://github.com/brenoprata10/nvim-highlight-colors?tab=readme-ov-file#options
    -- https://github.com/brenoprata10/nvim-highlight-colors?tab=readme-ov-file#blinkcmp-integration
    opts = {
      render = 'background',
      enable_named_colors = true,
      enable_tailwind = false,
    },
  },

  -- NVIM-MULTI-CURSOR | Modern multi-cursor for Neovim (Commenting out shortcuts that conflict with VSCode schema)
  -- https://github.com/jake-stewart/multicursor.nvim
  {
    'jake-stewart/multicursor.nvim',
    branch = '1.0',
    config = function()
      local loaded, plugin = pcall(require, 'multicursor-nvim')
      if loaded then
        plugin.setup()
        -- =============================================================================
        -- MULTI-CURSOR SHORTCUTS - COMMENTED OUT DUE TO SCHEMA CONFLICTS
        -- =============================================================================

        -- The schema uses ⌘ d for "Toggle Problems", not multi-cursor
        -- These shortcuts can be re-enabled with different key combinations if needed:

        -- Add cursors above/below the main cursor
        vim.keymap.set({ 'n', 'v' }, '<S-D-Up>', function() plugin.addCursor('k') end, { desc = 'Add cursor above' })
        vim.keymap.set({ 'n', 'v' }, '<S-D-Down>', function() plugin.addCursor('j') end, { desc = 'Add cursor below' })

        -- Add cursor at current position
        vim.keymap.set({ 'n', 'v' }, '<D-C-S-i>', plugin.addCursor, { desc = 'Add cursor' })

        -- Delete cursor at current position
        vim.keymap.set({ 'n', 'v' }, '<D-C-S-x>', plugin.deleteCursor, { desc = 'Delete cursor' })

        -- Add and jump to next match (conflicts with ⌘ d for problems)
        vim.keymap.set({ 'n', 'v' }, '<D-C-d>', plugin.matchAddCursor, { desc = 'Add cursor and jump to next match' })

        -- =============================================================================
        -- ALL MULTI-CURSOR SHORTCUTS COMMENTED OUT TO FOLLOW SCHEMA STRICTLY
        -- =============================================================================

        -- These can be re-enabled with different key combinations if needed:

        -- Jump to next match (conflicts with ⌘ d for problems)
        -- vim.keymap.set({ 'n', 'v' }, '<D-C-d>', mc.matchSkipCursor, { desc = 'Skip current and jump to next match' })

        -- You can also add cursors with a regex
        -- vim.keymap.set({ 'n', 'v' }, '<D-C-S-r>', function() mc.matchCursors(1) end, { desc = 'Add cursors with regex' })

        -- Rotate the main cursor
        -- vim.keymap.set({ 'n', 'v' }, '<D-C-S-h>', mc.nextCursor, { desc = 'Next cursor' })
        -- vim.keymap.set({ 'n', 'v' }, '<D-C-S-l>', mc.prevCursor, { desc = 'Previous cursor' })

        -- Clear all cursors (keeping ESC functionality as it doesn't conflict)
        vim.keymap.set('n', '<Esc>', function()
          if not plugin.cursorsEnabled() then
            plugin.enableCursors()
          elseif plugin.hasCursors() then
            plugin.clearCursors()
          else
            -- Do normal escape functionality
          end
        end, { desc = 'Clear cursors' })

        -- Align cursor columns (not in schema)
        -- vim.keymap.set('v', '<D-C-S-a>', mc.alignCursors, { desc = 'Align cursors' })

        -- Split visual selections by regex (not in schema)
        -- vim.keymap.set('v', '<D-S-s>', mc.splitCursors, { desc = 'Split visual selections by regex' })

        -- Append/insert for each line of visual selections (not in schema)
        -- vim.keymap.set('v', 'I', mc.insertVisual, { desc = 'Insert for each line' })
        -- vim.keymap.set('v', 'A', mc.appendVisual, { desc = 'Append for each line' })

        -- Match new cursors within visual selections by regex (not in schema)
        -- vim.keymap.set('v', 'M', mc.matchCursors, { desc = 'Match cursors by regex' })

        -- Customize how cursors look
        vim.api.nvim_set_hl(0, 'MultiCursorCursor', { link = 'Cursor' })
        vim.api.nvim_set_hl(0, 'MultiCursorVisual', { link = 'Visual' })
        vim.api.nvim_set_hl(0, 'MultiCursorSign', { link = 'SignColumn' })
        vim.api.nvim_set_hl(0, 'MultiCursorDisabledCursor', { link = 'Visual' })
        vim.api.nvim_set_hl(0, 'MultiCursorDisabledVisual', { link = 'Visual' })
        vim.api.nvim_set_hl(0, 'MultiCursorDisabledSign', { link = 'SignColumn' })
      end
    end,
  },

  -- NVIM-NAVIC | Simple winbar/statusline plugin that shows your current code context (VSCode-like breadcrumbs)
  -- https://github.com/SmiteshP/nvim-navic
  {
    'SmiteshP/nvim-navic',
    opts = {
      icons = {
        File          = "󰈙 ",
        Module        = " ",
        Namespace     = "󰌗 ",
        Package       = " ",
        Class         = "󰌗 ",
        Method        = "󰆧 ",
        Property      = " ",
        Field         = " ",
        Constructor   = " ",
        Enum          = "󰕘",
        Interface     = "󰕘",
        Function      = "󰊕 ",
        Variable      = "󰆧 ",
        Constant      = "󰏿 ",
        String        = "󰀬 ",
        Number        = "󰎠 ",
        Boolean       = "◩ ",
        Array         = "󰅪 ",
        Object        = "󰅩 ",
        Key           = "󰌋 ",
        Null          = "󰟢 ",
        EnumMember    = " ",
        Struct        = "󰌗 ",
        Event         = " ",
        Operator      = "󰆕 ",
        TypeParameter = "󰊄 ",
      },
      lsp = {
        auto_attach = true,
        preference = nil,
      },
      highlight = false,
      separator = " > ",
      depth_limit = 0,
      depth_limit_indicator = "..",
      safe_output = true,
      lazy_update_context = false,
      click = false,
      format_text = function(text)
        return text
      end,
    },
  },

  -- NVIM-UFO | Ultra fold in Neovim (VSCode-like code folding)
  -- https://github.com/kevinhwang91/nvim-ufo
  {
    'kevinhwang91/nvim-ufo',
    dependencies = 'kevinhwang91/promise-async',
    config = function()
      vim.o.foldcolumn = '1'
      vim.o.foldlevel = 99
      vim.o.foldlevelstart = 99
      vim.o.foldenable = true

      -- Using ufo provider need remap `zR` and `zM`
      vim.keymap.set('n', 'zR', require('ufo').openAllFolds)
      vim.keymap.set('n', 'zM', require('ufo').closeAllFolds)
      vim.keymap.set('n', 'zr', require('ufo').openFoldsExceptKinds)
      vim.keymap.set('n', 'zm', require('ufo').closeFoldsWith)

      -- VSCode-like fold keymaps
      vim.keymap.set('n', '<D-[>', 'za', { desc = 'Toggle fold' })
      vim.keymap.set('n', '<D-]>', 'zA', { desc = 'Toggle all folds at cursor' })
      vim.keymap.set('n', '<D-S-[>', require('ufo').closeAllFolds, { desc = 'Close all folds' })
      vim.keymap.set('n', '<D-S-]>', require('ufo').openAllFolds, { desc = 'Open all folds' })

      require('ufo').setup({
        provider_selector = function(bufnr, filetype, buftype)
          return { 'treesitter', 'indent' }
        end,
        fold_virt_text_handler = function(virtText, lnum, endLnum, width, truncate)
          local newVirtText = {}
          local suffix = (' 󰁂 %d '):format(endLnum - lnum)
          local sufWidth = vim.fn.strdisplaywidth(suffix)
          local targetWidth = width - sufWidth
          local curWidth = 0
          for _, chunk in ipairs(virtText) do
            local chunkText = chunk[1]
            local chunkWidth = vim.fn.strdisplaywidth(chunkText)
            if targetWidth > curWidth + chunkWidth then
              table.insert(newVirtText, chunk)
            else
              chunkText = truncate(chunkText, targetWidth - curWidth)
              local hlGroup = chunk[2]
              table.insert(newVirtText, { chunkText, hlGroup })
              chunkWidth = vim.fn.strdisplaywidth(chunkText)
              if curWidth + chunkWidth < targetWidth then
                suffix = suffix .. (' '):rep(targetWidth - curWidth - chunkWidth)
              end
              break
            end
            curWidth = curWidth + chunkWidth
          end
          table.insert(newVirtText, { suffix, 'MoreMsg' })
          return newVirtText
        end,
      })
    end,
  },

  -- AERIAL | Neovim plugin for a code outline window (Alternative to symbols-outline with more features / better than flash.nvim)
  -- https://github.com/stevearc/aerial.nvim
  {
    'stevearc/aerial.nvim',
    opts = {
      backends = { "lsp", "treesitter", "markdown", "man" },
      layout = {
        max_width = { 40, 0.2 },
        width = nil,
        min_width = 10,
        win_opts = {},
        default_direction = "prefer_right",
        placement = "window",
      },
      attach_mode = "window",
      close_automatic_events = {},
      keymaps = {
        ["?"] = "actions.show_help",
        ["g?"] = "actions.show_help",
        ["<CR>"] = "actions.jump",
        ["<2-LeftMouse>"] = "actions.jump",
        ["<C-v>"] = "actions.jump_vsplit",
        ["<C-s>"] = "actions.jump_split",
        ["p"] = "actions.scroll",
        ["<C-j>"] = "actions.down_and_scroll",
        ["<C-k>"] = "actions.up_and_scroll",
        ["{"] = "actions.prev",
        ["}"] = "actions.next",
        ["[["] = "actions.prev_up",
        ["]]"] = "actions.next_up",
        ["q"] = "actions.close",
        ["o"] = "actions.tree_toggle",
        ["za"] = "actions.tree_toggle",
        ["O"] = "actions.tree_toggle_recursive",
        ["zA"] = "actions.tree_toggle_recursive",
        ["l"] = "actions.tree_open",
        ["zo"] = "actions.tree_open",
        ["L"] = "actions.tree_open_recursive",
        ["zO"] = "actions.tree_open_recursive",
        ["h"] = "actions.tree_close",
        ["zc"] = "actions.tree_close",
        ["H"] = "actions.tree_close_recursive",
        ["zC"] = "actions.tree_close_recursive",
        ["zr"] = "actions.tree_increase_fold_level",
        ["zR"] = "actions.tree_open_all",
        ["zm"] = "actions.tree_decrease_fold_level",
        ["zM"] = "actions.tree_close_all",
        ["zx"] = "actions.tree_sync_folds",
        ["zX"] = "actions.tree_sync_folds",
      },
      lazy_load = true,
      disable_max_lines = 10000,
      disable_max_size = 2000000,
      filter_kind = {
        "Class",
        "Constructor",
        "Enum",
        "Function",
        "Interface",
        "Module",
        "Method",
        "Struct",
      },
      highlight_mode = "split_width",
      highlight_closest = true,
      highlight_on_hover = false,
      highlight_on_jump = 300,
      icons = {},
      ignore = {
        unlisted_buffers = true,
        filetypes = {},
        buftypes = "special",
        wintypes = "special",
      },
      manage_folds = false,
      link_folds_to_tree = false,
      link_tree_to_folds = true,
      nerd_font = "auto",
      on_attach = function(bufnr)
        vim.keymap.set("n", "{", "<cmd>AerialPrev<CR>", { buffer = bufnr })
        vim.keymap.set("n", "}", "<cmd>AerialNext<CR>", { buffer = bufnr })
      end,
      on_first_symbols = function(bufnr) end,
      open_automatic = false,
      post_jump_cmd = "normal! zz",
      close_on_select = false,
      show_guides = false,
      float = {
        border = "rounded",
        relative = "cursor",
        max_height = 0.9,
        height = nil,
        min_height = { 8, 0.1 },
        override = function(conf, source_winid)
          return conf
        end,
      },
      lsp = {
        diagnostics_trigger_update = true,
        update_when_errors = true,
        update_delay = 300,
      },
      treesitter = {
        update_delay = 300,
      },
      markdown = {
        update_delay = 300,
      },
      man = {
        update_delay = 300,
      },
    },
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "echasnovski/mini.icons" -- modern icon provider, replaces nvim-web-devicons
    },
  },

  -- NVIM-LIGHTBULB | VSCode 💡 for neovim's built-in LSP (VSCode-like code action indicator)
  -- https://github.com/kosayoda/nvim-lightbulb
  {
    'kosayoda/nvim-lightbulb',
    opts = {
      priority = 10,
      hide_in_unfocused_buffer = true,
      link_highlights = true,
      validate_config = "auto",
      action_kinds = nil,
      sign = {
        enabled = true,
        text = "💡",
        hl = "LightBulbSign",
      },
      virtual_text = {
        enabled = false,
        text = "💡",
        pos = "eol",
        hl = "LightBulbVirtualText",
        hl_mode = "combine",
      },
      float = {
        enabled = false,
        text = "💡",
        hl = "LightBulbFloatWin",
        win_opts = {},
      },
      status_text = {
        enabled = false,
        text = "💡",
        text_unavailable = ""
      },
      number = {
        enabled = false,
        hl = "LightBulbNumber",
      },
      line = {
        enabled = false,
        hl = "LightBulbLine",
      },
      autocmd = {
        enabled = true,
        updatetime = 200,
        events = { "CursorHold", "CursorHoldI" },
        pattern = { "*" },
      },
      ignore = {
        clients = {},
        ft = {},
        actions_without_kind = false,
      },
    },
  },

  -- NVIM-LASTPLACE | Intelligently reopen files at your last edit position (VSCode-like "remember cursor position")
  -- https://github.com/ethanholz/nvim-lastplace
  {
    'ethanholz/nvim-lastplace',
    opts = {
      lastplace_ignore_buftype = { "quickfix", "nofile", "help" },
      lastplace_ignore_filetype = {
        "gitcommit", "gitrebase", "svn", "hgcommit"
      },
      lastplace_open_folds = true
    },
  },

  -- SMART-SPLITS | A plugin for Neovim that enables better split management > Think about splits in terms of "up/down/left/right" (VSCode-like window management)
  -- https://github.com/mrjones2014/smart-splits.nvim
  {
    'mrjones2014/smart-splits.nvim',
    config = function()
      require('smart-splits').setup({
        ignored_filetypes = { 'nofile', 'quickfix', 'qf', 'prompt' },
        ignored_buftypes = { 'nofile' },
        default_amount = 3,
        at_edge = 'wrap',
        move_cursor_same_row = false,
        cursor_follows_swapped_bufs = false,
        resize_mode = {
          quit_key = '<ESC>',
          resize_keys = { 'h', 'j', 'k', 'l' },
          silent = false,
          hooks = {
            on_enter = nil,
            on_leave = nil,
          },
        },
        ignored_events = {
          'BufEnter',
          'WinEnter',
        },
      })

      -- VSCode-like window navigation
      vim.keymap.set('n', '<C-h>', require('smart-splits').move_cursor_left)
      vim.keymap.set('n', '<C-j>', require('smart-splits').move_cursor_down)
      vim.keymap.set('n', '<C-k>', require('smart-splits').move_cursor_up)
      vim.keymap.set('n', '<C-l>', require('smart-splits').move_cursor_right)
      vim.keymap.set('n', '<C-\\>', require('smart-splits').move_cursor_previous)

      -- Resizing splits
      vim.keymap.set('n', '<A-h>', require('smart-splits').resize_left)
      vim.keymap.set('n', '<A-j>', require('smart-splits').resize_down)
      vim.keymap.set('n', '<A-k>', require('smart-splits').resize_up)
      vim.keymap.set('n', '<A-l>', require('smart-splits').resize_right)

      -- Swapping buffers between windows
      vim.keymap.set('n', '<leader><leader>h', require('smart-splits').swap_buf_left)
      vim.keymap.set('n', '<leader><leader>j', require('smart-splits').swap_buf_down)
      vim.keymap.set('n', '<leader><leader>k', require('smart-splits').swap_buf_up)
      vim.keymap.set('n', '<leader><leader>l', require('smart-splits').swap_buf_right)
    end,
  },

  -- TOGGLETERM | A neovim lua plugin to help easily manage multiple terminal windows (VSCode-like integrated terminal with mini.pairs for consistency with mini ecosystem)
  -- https://github.com/akinsho/toggleterm.nvim?tab=readme-ov-file#installation
  {
    'akinsho/toggleterm.nvim',
    version = "*",
    opts = {
      size = 20,
      open_mapping = [[<C-\>]],
      hide_numbers = true,
      shade_filetypes = {},
      shade_terminals = true,
      shading_factor = 2,
      start_in_insert = true,
      insert_mappings = true,
      persist_size = true,
      direction = "float",
      close_on_exit = true,
      shell = vim.o.shell,
      float_opts = {
        border = "curved",
        winblend = 0,
        highlights = {
          border = "Normal",
          background = "Normal",
        },
      },
    },
  },

  -- NVIM-TS-CONTEXT-COMMENTSTRING | Neovim treesitter plugin for setting the commentstring based on the cursor location
  -- https://github.com/JoosepAlviste/nvim-ts-context-commentstring/wiki/Integrations#native-commenting-in-neovim-010
  {
    'JoosepAlviste/nvim-ts-context-commentstring',
    opts = {
      -- Native commenting in Neovim 0.10
      enable_autocmd = vim.fn.has("nvim-0.10.0") == 0,
    },
  },

  -- FLASH | Navigate your code with search labels, enhanced character motions and Treesitter integration (VSCode-like quick jump/search)
  -- https://github.com/folke/flash.nvim
  {
    'folke/flash.nvim',
    event = 'VeryLazy',
    opts = {
      labels = "asdfghjklqwertyuiopzxcvbnm",
      search = {
        multi_window = true,
        forward = true,
        wrap = true,
        mode = "exact",
        incremental = false,
        exclude = {
          "notify",
          "cmp_menu",
          "noice",
          "flash_prompt",
          function(win)
            return vim.api.nvim_win_get_config(win).zindex ~= nil
          end,
        },
      },
      jump = {
        jumplist = true,
        pos = "start",
        history = false,
        register = false,
        nohlsearch = false,
        autojump = false,
      },
      label = {
        uppercase = true,
        exclude = "",
        current = true,
        after = true,
        before = false,
        style = "overlay",
        reuse = "lowercase",
        distance = true,
        min_pattern_length = 0,
        rainbow = {
          enabled = false,
          shade = 5,
        },
        format = function(opts)
          return { { opts.match.label, opts.hl_group } }
        end,
      },
      highlight = {
        backdrop = true,
        matches = true,
        priority = 5000,
        groups = {
          match = "FlashMatch",
          current = "FlashCurrent",
          backdrop = "FlashBackdrop",
          label = "FlashLabel",
        },
      },
      modes = {
        search = {
          enabled = true,
          highlight = { backdrop = false },
          jump = { history = true, register = true, nohlsearch = true },
          search = {
            mode = "search",
            max_length = false,
            exclude = {
              function(win)
                return vim.api.nvim_win_get_config(win).zindex ~= nil
              end,
            },
          },
        },
        char = {
          enabled = true,
          config = function(opts)
            opts.autohide = opts.autohide == nil and (vim.fn.mode(true):find("no") and vim.v.operator == "y")
            opts.jump_labels = opts.jump_labels == nil and
                (vim.v.count == 0 and vim.fn.reg_executing() == "" and vim.fn.reg_recording() == "")
          end,
          autohide = false,
          jump_labels = false,
          multi_line = true,
          label = { exclude = "hjkliardc" },
          keys = { "f", "F", "t", "T", ";", "," },
          char_actions = function(motion)
            return {
              [";"] = "next",
              [","] = "prev",
              [motion:lower()] = "next",
              [motion:upper()] = "prev",
            }
          end,
          search = { wrap = false },
          highlight = { backdrop = true },
          jump = { register = false },
        },
        treesitter = {
          labels = "abcdefghijklmnopqrstuvwxyz",
          jump = { pos = "range" },
          search = { incremental = false },
          label = { before = true, after = true, style = "inline" },
          highlight = {
            backdrop = false,
            matches = false,
          },
        },
        treesitter_search = {
          jump = { pos = "range" },
          search = { multi_window = true, wrap = true, incremental = false },
          remote_op = { restore = true },
          label = { before = true, after = true, style = "inline" },
        },
        remote = {
          remote_op = { restore = true, motion = true },
        },
      },
      prompt = {
        enabled = true,
        prefix = { { "⚡", "FlashPromptIcon" } },
        win_config = {
          relative = "editor",
          width = 1,
          height = 1,
          row = -1,
          col = 0,
          zindex = 1000,
        },
      },
      remote_op = {
        restore = false,
        motion = false,
      },
    },
    keys = {
      { "s",     mode = { "n", "x", "o" }, function() require("flash").jump() end,              desc = "Flash" },
      { "S",     mode = { "n", "x", "o" }, function() require("flash").treesitter() end,        desc = "Flash Treesitter" },
      { "r",     mode = "o",               function() require("flash").remote() end,            desc = "Remote Flash" },
      { "R",     mode = { "o", "x" },      function() require("flash").treesitter_search() end, desc = "Treesitter Search" },
      { "<c-s>", mode = { "c" },           function() require("flash").toggle() end,            desc = "Toggle Flash Search" },
    },
  },

  -- WHICH-KEY | Create key bindings that stick (VSCode-like command palette)
  -- https://github.com/folke/which-key.nvim?tab=readme-ov-file#lazynvim
  {
    'folke/which-key.nvim',
    opts = {
      preset = "modern",
      delay = function(ctx)
        return ctx.plugin and 0 or 200
      end,
      spec = {
        { "<leader>b", group = "buffer" },
        { "<leader>c", group = "code" },
        { "<leader>f", group = "find/file" },
        { "<leader>g", group = "git" },
        { "<leader>h", group = "hunks" },
        { "<leader>q", group = "quit/session" },
        { "<leader>s", group = "search" },
        { "<leader>t", group = "toggle" },
        { "<leader>w", group = "windows" },
        { "<leader>x", group = "diagnostics/quickfix" },
        { "[",         group = "prev" },
        { "]",         group = "next" },
        { "g",         group = "goto" },
        { "gs",        group = "surround" },
        { "z",         group = "fold" },
      },
    },
  },

  -- TROUBLE | A pretty diagnostics, references, telescope results, quickfix and location list (VSCode-like problems panel)
  -- https://github.com/folke/trouble.nvim?tab=readme-ov-file#lazynvim
  {
    'folke/trouble.nvim',
    enabled = false,
    opts = {
      modes = {
        preview_float = {
          mode = "diagnostics",
          preview = {
            type = "float",
            relative = "editor",
            border = "rounded",
            title = "Preview",
            title_pos = "center",
            position = { 0, -2 },
            size = { width = 0.3, height = 0.3 },
            zindex = 200,
          },
        },
      },
      use_diagnostic_signs = true,
    },
  },

  -- TODO-COMMENTS | Highlight and search for todo comments like TODO, HACK, BUG in your code base | Neovim >= 0.8.0 (VSCode-like todo highlighting)
  -- https://github.com/folke/todo-comments.nvim?tab=readme-ov-file#lazynvim
  {
    'folke/todo-comments.nvim',
    opts = {
      signs = true,
      sign_priority = 8,
      keywords = {
        FIX = { icon = " ", color = "error", alt = { "FIXME", "BUG", "FIXIT", "ISSUE" } },
        TODO = { icon = " ", color = "info" },
        HACK = { icon = " ", color = "warning" },
        WARN = { icon = " ", color = "warning", alt = { "WARNING", "XXX" } },
        PERF = { icon = " ", alt = { "OPTIM", "PERFORMANCE", "OPTIMIZE" } },
        NOTE = { icon = " ", color = "hint", alt = { "INFO" } },
        TEST = { icon = "⏲ ", color = "test", alt = { "TESTING", "PASSED", "FAILED" } },
      },
      gui_style = {
        fg = "NONE",
        bg = "BOLD",
      },
      merge_keywords = true,
      highlight = {
        multiline = true,
        multiline_pattern = "^.",
        multiline_context = 10,
        before = "",
        keyword = "wide",
        after = "fg",
        pattern = [[.*<(KEYWORDS)\s*:]],
        comments_only = true,
        max_line_len = 400,
        exclude = {},
      },
    },
  },

  -- TS-COMMENTS | Tiny plugin to enhance Neovim's native comments
  -- https://github.com/folke/ts-comments.nvim?tab=readme-ov-file#-installation
  {
    'folke/ts-comments.nvim',
    event = "VeryLazy",
    opts = {},
  },

  -- ZEN-MODE | Distraction-free coding for Neovim (VSCode-like Zen mode)
  -- https://github.com/folke/zen-mode.nvim
  {
    'folke/zen-mode.nvim',
    opts = {
      window = {
        backdrop = 0.95,
        width = 120,
        height = 1,
        options = {
          signcolumn = "no",
          number = false,
          relativenumber = false,
          cursorline = false,
          cursorcolumn = false,
          foldcolumn = "0",
          list = false,
        },
      },
      plugins = {
        options = {
          enabled = true,
          ruler = false,
          showcmd = false,
        },
        twilight = { enabled = true },
        gitsigns = { enabled = false },
        tmux = { enabled = false },
        kitty = {
          enabled = false,
          font = "+4",
        },
        alacritty = {
          enabled = false,
          font = "14",
        },
        wezterm = {
          enabled = false,
          font = "+4",
        },
      },
    },
  }
}
