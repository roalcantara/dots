local is_git_repo = require('core/etc/git').is_git_repo
local snacks_filetypes = require('core/ui/snacks/pickers/filetypes')
local snacks_scratch = require('core/ui/snacks/scratch')
local snacks_lua_path_items = require('core/ui/snacks/pickers/lua_path_items')
local snacks_runtimepath_items = require('core/ui/snacks/pickers/runtimepath_items')
local snacks_options = require('core/ui/snacks/pickers/options')
local snacks_move_buffer_split = require('core/ui/snacks/pickers/move_buffer_split')
local get_valid_buffers = require('core/vi/buffers').get_valid_buffers
local parse_mappings = require('core/vi/maps/parse_mappings')

--- Create a command that can be used in keymaps
--- @param command string|function Command to execute
--- @param opts table|nil Options for the command
--- @return function keymap_cmd A function to execute the command
local function keymap_cmd(command, opts)
  if type(command) == 'function' then
    if opts then
      return function()
        return command(opts)
      end
    end
    return command
  end

  if type(command) == 'string' then
    return function()
      return vim.cmd(command)
    end
  end

  return command
end

--- Define a command to run async formatting
--- @see https://github.com/stevearc/conform.nvim/blob/master/doc/recipes.md#format-command
local function keymap_format(args)
  local range = nil
  if args.count ~= -1 then
    local end_line = vim.api.nvim_buf_get_lines(0, args.line2 - 1, args.line2, true)[1]
    range = {
      start = { args.line1, 0 },
      ['end'] = { args.line2, end_line:len() },
    }
  end
  require('conform').format({ async = true, lsp_format = 'fallback', range = range })
end

local function keymap_autoclose_on_last_buffer()
  local real_bufs = get_valid_buffers({
    'snacks_picker',
    'snacks_picker_list',
    'lazy',
    'mason',
    'help',
    'qf',
  })
  if #real_bufs == 0 then
    vim.keymap_cmd('quit')
  end
end

local function keymap_smart_buffer_close(opts)
  Snacks.bufdelete.delete(opts)
  vim.schedule(keymap_autoclose_on_last_buffer)
end

-- Terminal state management
local terminal_state = {
  buf = nil,
  win = nil,
  is_open = false,
}

--- Parses the mappings table and creates keymaps
--- @param fn fun(buf: table, pick: table, toggle: table, lsp: table, ev: table, on: table, setup: table): table A function that returns a table of keymaps
--- @return nil Keymaps are created
local function set_keymaps(fn)
  local mappings = fn(
  -- buf
    {
      --- Delete buffers without disrupting window layout
      --- @see docs https://github.com/folke/snacks.nvim/blob/main/docs/bufdelete.md#snacksbufdeletedelete
      close = keymap_cmd(keymap_smart_buffer_close, { wipe = true }),

      --- Delete all buffers
      --- @see docs https://github.com/folke/snacks.nvim/blob/main/docs/bufdelete.md#snacksbufdeleteall
      close_all = keymap_cmd(Snacks.bufdelete.all, { wipe = true }),

      --- Delete all buffers except the current one
      --- @see docs https://github.com/folke/snacks.nvim/blob/main/docs/bufdelete.md#snacksbufdeleteother
      close_others = keymap_cmd(Snacks.bufdelete.other, { wipe = true }),

      --- Format the current buffer
      --- @see docs https://github.com/stevearc/conform.nvim/blob/main/doc/recipes.md#format-command
      format = keymap_cmd(keymap_format),
    },
    -- pick
    {
      --- Search and pick autocmds
      --- @see docs https://github.com/folke/snacks.nvim/blob/main/docs/picker.md#autocmds
      autocmds = keymap_cmd(Snacks.picker.autocmds),

      --- Search and pick for Neovim buffers
      --- @see docs https://github.com/folke/snacks.nvim/blob/main/docs/picker.md#buffers
      buffers = keymap_cmd(Snacks.picker.buffers),

      --- Search and pick for Neovim commands
      --- @see docs https://github.com/folke/snacks.nvim/blob/main/docs/picker.md#commands
      commands = keymap_cmd(Snacks.picker.commands),

      --- Search and pick for Neovim diagnostics
      --- @see docs https://github.com/folke/snacks.nvim/blob/main/docs/picker.md#diagnostics
      diagnostics = keymap_cmd(Snacks.picker.diagnostics, { focus = true, layout = { preset = 'ivy' } }),

      --- Search and pick for Neovim buffer diagnostics
      --- @see docs https://github.com/folke/snacks.nvim/blob/main/docs/picker.md#diagnostics_buffer
      diagnostics_buffer = keymap_cmd(Snacks.picker.diagnostics_buffer, { focus = true, layout = { preset = 'ivy' } }),

      --- A file explorer for snacks
      --- @see docs https://github.com/folke/snacks.nvim/blob/main/docs/explorer.md
      explorer = keymap_cmd(Snacks.picker.explorer),

      --- Returns files on the current buffer path or git_files if a git repo
      --- @see docs https://github.com/folke/snacks.nvim/blob/main/docs/picker.md#files
      --- @see docs https://github.com/folke/snacks.nvim/blob/main/docs/picker.md#git_files
      files = function()
        if is_git_repo() then
          return Snacks.picker.git_files({
            show_empty = true,
            untracked = true,
            submodules = false,
          })
        end

        return Snacks.picker.files({
          show_empty = true,
          hidden = true,
          ignored = false,
          follow = false,
          supports_live = true,
        })
      end,

      --- Search and pick for Neovim filetypes
      filetypes = snacks_filetypes,

      --- Search lines in the current buffer
      --- @see docs https://github.com/folke/snacks.nvim/blob/main/docs/picker.md#lines
      find = keymap_cmd(Snacks.picker.lines),

      --- Search and pick for in grep or git_giles
      --- @see docs https://github.com/folke/snacks.nvim/blob/main/docs/picker.md#lines
      --- @see docs https://github.com/folke/snacks.nvim/blob/main/docs/picker.md#git_grep
      grep = function()
        if is_git_repo() then
          return Snacks.picker.git_grep({
            finder = 'git_grep',
            format = 'file',
            untracked = true,
            need_search = true,
            submodules = false,
            show_empty = true,
            supports_live = true,
            live = true,
          })
        end

        return Snacks.picker.grep({
          finder = 'grep',
          regex = true,
          format = 'file',
          show_empty = true,
          live = true, -- live grep by default
          supports_live = true,
        })
      end,

      --- Search and pick for Neovim help tags
      --- @see docs https://github.com/folke/snacks.nvim/blob/main/docs/picker.md#help
      help = keymap_cmd(Snacks.picker.help),

      --- Search for highlights
      --- @see docs https://github.com/folke/snacks.nvim/blob/main/docs/picker.md#highlights
      highlights = keymap_cmd(Snacks.picker.highlights),

      --- Search and pick for jumps
      --- @see docs https://github.com/folke/snacks.nvim/blob/main/docs/picker.md#jumps
      jumps = keymap_cmd(Snacks.picker.jumps),

      --- Search and pick for keymaps
      --- @see docs https://github.com/folke/snacks.nvim/blob/main/docs/picker.md#keymaps
      keymaps = keymap_cmd(Snacks.picker.keymaps),

      --- Search and pick for Neovim lua_path_items
      lua_path_items = snacks_lua_path_items,

      --- Move current buffer to split to the left, right, top, or bottom
      move_buffer_split = snacks_move_buffer_split,

      --- Search and pick for notifications
      --- @see docs https://github.com/folke/snacks.nvim/blob/main/docs/picker.md#notifications
      notifications = keymap_cmd(Snacks.picker.notifications),

      --- Search and pick for Neovim options
      options = snacks_options,

      --- Search and pick for Neovim runtimepath_items
      runtimepath_items = snacks_runtimepath_items,

      --- Search smart for files, buffers, lines, etc
      --- @see docs https://github.com/folke/snacks.nvim/blob/main/docs/picker.md#smart
      smart = keymap_cmd(Snacks.picker.smart),
    },
    -- toggle
    {
      --- Search and pick for FzfLua menus
      --- @see docs https://github.com/ibhagwan/fzf-lua?tab=readme-ov-file#misc
      menus = { n = '<CMD>FzfLua menus<CR>', i = '<ESC><CMD>FzfLua menus<CR>', v = '<ESC><CMD>FzfLua menus<CR>' },

      --- Open new scratch buffer
      --- @see source https://github.com/folke/snacks.nvim/discussions/765#discussion-7880347
      new_scratch = snacks_scratch,

      --- Toggle Neovim news
      --- @see docs https://github.com/folke/snacks.nvim/blob/main/docs/win.md#-usage
      news = function()
        return Snacks.win({
          file = vim.api.nvim_get_runtime_file('doc/news.txt', false)[1],
          width = 0.6,
          height = 0.6,
          wo = {
            spell = false,
            wrap = false,
            signcolumn = 'yes',
            statuscolumn = ' ',
            conceallevel = 3,
          },
        })
      end,

      --- Toggle terminal
      term = function()
        if terminal_state.is_open and terminal_state.win and vim.api.nvim_win_is_valid(terminal_state.win) then
          -- Terminal is open, close it
          vim.api.nvim_win_hide(terminal_state.win)
          terminal_state.is_open = false
        else
          -- Terminal is closed or doesn't exist, open it
          if terminal_state.buf and vim.api.nvim_buf_is_valid(terminal_state.buf) then
            -- Reuse existing terminal buffer
            vim.keymap_cmd('botright split')
            vim.api.nvim_win_set_buf(0, terminal_state.buf)
            terminal_state.win = vim.api.nvim_get_current_win()
          else
            -- Create new terminal
            vim.keymap_cmd('botright split')
            vim.keymap_cmd.term()
            terminal_state.buf = vim.api.nvim_get_current_buf()
            terminal_state.win = vim.api.nvim_get_current_win()
          end
          -- Set terminal height
          vim.api.nvim_win_set_height(0, 10)
          -- Enter insert mode and focus the terminal
          vim.keymap_cmd.startinsert()
          terminal_state.is_open = true
        end
      end,

      --- Toggle Zen Mode
      --- @see docs https://github.com/folke/zen.nvim
      zen = function()
        return Snacks.zen()
      end,
    },
    -- lsp
    {
      --- Search and pick for
      --- @see docs http://github.com/folke/snacks.nvim/blob/main/docs/picker.md#lsp_config
      config = keymap_cmd(Snacks.picker.lsp_config),

      --- Search and pick for lsp_declarations
      --- @see docs http://github.com/folke/snacks.nvim/blob/main/docs/picker.md#lsp_declarations
      declarations = keymap_cmd(Snacks.picker.lsp_declarations),

      --- Search and pick for lsp_definitions
      --- @see docs http://github.com/folke/snacks.nvim/blob/main/docs/picker.md#lsp_definitions
      definitions = keymap_cmd(Snacks.picker.lsp_definitions),

      --- Search and pick for
      --- @see docs http://github.com/folke/snacks.nvim/blob/main/docs/picker.md#l
      implementations = keymap_cmd(Snacks.picker.lsp_implementations),

      --- Search and pick for lsp_references
      --- @see docs http://github.com/folke/snacks.nvim/blob/main/docs/picker.md#lsp_references
      references = keymap_cmd(Snacks.picker.lsp_references),

      --- Search and pick for lsp_symbols
      --- @see docs http://github.com/folke/snacks.nvim/blob/main/docs/picker.md#lsp_symbols
      symbols = keymap_cmd(Snacks.picker.lsp_symbols, { layout = 'dropdown', enter = true, focus = 'list' }),

      --- Search and pick for lsp_workspace_symbols
      --- @see docs http://github.com/folke/snacks.nvim/blob/main/docs/picker.md#lsp_workspace_symbols
      workspace_symbols = keymap_cmd(
        Snacks.picker.lsp_workspace_symbols,
        { layout = 'dropdown', enter = true, focus = 'list' }
      ),

      --- Search and pick for lsp_type_definitions
      --- @see docs http://github.com/folke/snacks.nvim/blob/main/docs/picker.md#lsp_type_definitions
      type_definitions = keymap_cmd(Snacks.picker.lsp_type_definitions),

      --- Show signature help
      --- @see docs http://github.com/folke/snacks.nvim/blob/main/docs/picker.md#lsp_signature_help
      signature_help = function()
        return vim.lsp.buf.signature_help({
          focusable = false,
          focus = false,
          close_events = {
            'CursorMoved',
            'InsertLeave',
            'BufHide',
            'BufLeave',
            'WinLeave',
            'FocusLost',
            'InsertCharPre',
          },
        })
      end,
    },
    -- ev
    {
      src_vimrc_file = function()
        vim.keymap_cmd('source $MYVIMRC')
        vim.keymap_cmd('source %')
      end,

      --- Completion handling and modern Neovim features on SHIFT+TAB
      --- @see docs https://github.com/hrsh7th/nvim-cmp/blob/main/lua/cmp/utils/smart_tab.lua
      smart_shift_tab_completion = function()
        -- If completion menu is visible, go to previous item
        if vim.fn.pumvisible() == 1 then
          return '<C-p>'
        end

        local line = vim.api.nvim_get_current_line()
        local col = vim.api.nvim_win_get_cursor(0)[2]
        local before_cursor = line:sub(1, col)

        -- Smart unindenting
        if before_cursor:match('^%s+$') then
          return '<C-d>'
        end

        return '<S-Tab>'
      end,
    },
    -- setup
    {
      map_toggles = function(mappings)
        for key, mapping in pairs(mappings) do
          if type(mapping) == 'table' then
            Snacks.toggle({
              name = mapping.desc,
              get = mapping.get,
              set = mapping.set,
            }):map(key)
          elseif type(mapping) == 'function' then
            mapping(key)
          end
        end
      end,
    }
  )

  return parse_mappings(mappings)
end

return set_keymaps
