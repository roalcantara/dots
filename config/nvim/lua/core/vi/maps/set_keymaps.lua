local user_command = require('core/vi/maps/user_command')
local is_git_repo = require('core/etc/git').is_git_repo
local snacks_filetypes = require('core/ui/snacks/pickers/filetypes')
local snacks_scratch = require('core/ui/snacks/scratch')
local snacks_lua_path_items = require('core/ui/snacks/pickers/lua_path_items')
local snacks_runtimepath_items = require('core/ui/snacks/pickers/runtimepath_items')
local snacks_options = require('core/ui/snacks/pickers/options')
local snacks_move_buffer_split = require('core/ui/snacks/pickers/move_buffer_split')
local get_valid_buffers = require('core/vi/buffers').get_valid_buffers

--- Create a command that can be used in keymaps
--- @param command string|function Command to execute
--- @param opts table|nil Options for the command
--- @return function cmd A function to execute the command
local function cmd(command, opts)
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

--- Set a keymap
--- @param mode string|table Keymap mode(s)
--- @param lhs string Keymap left hand side
--- @param rhs string|function Keymap right hand side
--- @param desc string Keymap description
--- @param opts table|nil Keymap option
local function set_keymap(mode, lhs, rhs, desc, opts)
  local defaults_opts = {
    desc = desc, -- Mapping Description
    noremap = true, -- Non-recursive mapping
    silent = false, -- Silent mapping
  }
  vim.keymap.set(mode, lhs, rhs, vim.list_extend(defaults_opts, opts or {}))
end

--- Set a keymap
--- @param mode string|table Keymap mode(s)
--- @param lhs string Keymap left hand side
--- @param rhs string|function Keymap right hand side
--- @param desc string Keymap description
--- @param opts table|nil Keymap option
local function keymap(mode, lhs, rhs, desc, opts)
  if not opts then
    opts = {}
  end

  local success_keymap = pcall(set_keymap, mode, lhs, rhs, desc, opts)
  if not success_keymap then
    vim.notify('Failed to set keymap: ' .. lhs .. ' for command: ' .. tostring(rhs), vim.log.levels.ERROR)
  end
end

--- Convert key combination to readable format with symbols
--- @param key string The key combination string
--- @return string The formatted key combination with symbols
local function format_key_combination(key)
  local result = key
  result = result:gsub('<D%-M%-', '⌘ ⌥ ') -- Command + Alt
  result = result:gsub('<D%-C%-', '⌘ ⌃ ') -- Command + Control
  result = result:gsub('<D%-S%-', '⌘ ⇧ ') -- Command + Shift
  result = result:gsub('<A%-S%-', '⌥ ⇧ ') -- Alt + Shift
  result = result:gsub('<C%-S%-', '⌃ ⇧ ') -- Control + Shift
  result = result:gsub('<M%-S%-', '⌥ ⇧ ') -- Meta + Shift
  result = result:gsub('<D%-', '⌘ ') -- Command
  result = result:gsub('<A%-', '⌥ ') -- Alt
  result = result:gsub('<C%-', '⌃ ') -- Control
  result = result:gsub('<S%-', '⇧ ') -- Shift
  result = result:gsub('<M%-', '⌥ ') -- Meta (Alt)
  result = result:gsub('Up>', '↑') -- Up arrow
  result = result:gsub('Down>', '↓') -- Down arrow
  result = result:gsub('Left>', '←') -- Left arrow
  result = result:gsub('Right>', '→') -- Right arrow
  result = result:gsub('Space>', '␣') -- Space
  result = result:gsub('CR>', '↵') -- Enter/Return
  result = result:gsub('Tab>', '⇥') -- Tab
  result = result:gsub('Enter>', '↵') -- Enter
  result = result:gsub('Return>', '↵') -- Return
  result = result:gsub('Esc>', '⎋') -- Escape
  result = result:gsub('>', '') -- Remove remaining >
  result = result:gsub('%-', ' ') -- Replace - with space
  return result
end

--- Define a command to run async formatting
--- @see https://github.com/stevearc/conform.nvim/blob/master/doc/recipes.md#format-command
local function format(args)
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

--- Run a formatter
--- @param run_fmt_cmd table The formatter command (e.g. { "formatter_command", "arg1", "arg2" })
--- @param run_fmt_cwd string The formatter cwd (e.g. "/path/to/cwd")
--- @param run_fmt_buffer_text? string|nil The formatter buffer text (only used for stdin formatters)
--- @return nil Result is printed to the console
--- @see docs https://github.com/stevearc/conform.nvim/blob/master/doc/debugging.md#testing-vimsystem
local function run_formatter(run_fmt_cmd, run_fmt_cwd, run_fmt_buffer_text)
  local function runner(fmt_cmd, cwd, buffer_text)
    local proc = vim.system(fmt_cmd, {
      cwd = cwd,
      stdin = buffer_text,
      text = true,
    })
    local ret = proc:wait()
    if ret.code == 0 then
      print('Success\n--------')
    else
      print('Failure\n--------')
    end
    print(ret.stdout)
    print(ret.stderr)
  end
  local function read_file(path)
    local file = assert(io.open(path, 'r'))
    local content = file:read('*a')
    file:close()
    return content
  end

  if run_fmt_buffer_text then -- Test a stdin formatter
    return runner(run_fmt_cmd, run_fmt_cwd, read_file(run_fmt_buffer_text))
  else
    -- Tst a non-stdin formatter
    return runner(run_fmt_cmd, run_fmt_cwd)
  end
end

--- Parses the mappings table and creates keymaps
--- @param maps table Keymap table
--- @return nil Keymaps are created
local function mappings(maps)
  for key, value in pairs(maps) do
    local action = value[1]
    local desc = value[2] or ''
    local opts = value[3] or {}

    -- Convert key combination to readable format
    local readable_key = format_key_combination(key)

    --- Extract options from a table
    --- @param values table The table to extract options from
    --- @return table The extracted options
    local extract_opts = function(values)
      local options = {}
      if values and values.range then
        options.range = true
      end
      if values and values.expr then
        options.expr = true
      end
      return options
    end

    if type(action) == 'table' then
      -- Handle mode-specific mappings
      for mode, command in pairs(action) do
        local mode_prefix = mode:upper()
        local full_desc = string.format('[%s] [%s] %s', mode_prefix, readable_key, desc)
        local options = extract_opts(opts)
        keymap(mode, key, command, full_desc, options)
        if opts and opts.cmd then
          -- If opts.cmd is provided, create a user command
          local success, err = pcall(user_command, opts.cmd, command, full_desc)
          if not success then
            vim.notify(
              "Failed to create user cmd='" .. opts.cmd .. "', command='" .. tostring(command) .. "': " .. tostring(err),
              vim.log.levels.ERROR
            )
          end
        end
      end
    else
      -- Handle single mapping (defaults to normal mode)
      local full_desc = string.format('[%s] %s', readable_key, desc)
      keymap('n', key, action, full_desc)
      if opts and opts.cmd then
        -- If opts.cmd is provided, create a user command
        user_command(opts.cmd, action, full_desc)
      end
    end
  end
end

--- Completion handling and modern Neovim features on TAB
--- @example vim.keymap.set("i", "<Tab>", clever_tab, { expr = true, desc = "Smart tab completion" })
local function clever_tab()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2]
  local before_cursor = line:sub(1, col)

  -- Only whitespace before cursor
  if before_cursor:match('^%s*$') then
    return '<Tab>'
  end

  -- Completion menu is visible
  if vim.fn.pumvisible() == 1 then
    return '<C-n>'
  end

  -- Check if LSP is available and can provide completion
  local clients = vim.lsp.get_clients({ bufnr = 0 })
  local has_lsp_completion = false

  for _, client in ipairs(clients) do
    if client.server_capabilities.completionProvider then
      has_lsp_completion = true
      break
    end
  end

  -- Trigger completion if after word character
  if before_cursor:match('%w$') then
    if has_lsp_completion then
      -- Trigger LSP completion
      vim.lsp.completion.get()
      return ''
    elseif vim.bo.omnifunc ~= '' then
      return '<C-x><C-o>'
    else
      return '<C-n>'
    end
  end

  return '<Tab>'
end

--- Completion handling and modern Neovim features on SHIFT+TAB
--- @example vim.keymap.set("i", "<S-Tab>", clever_shift_tab, { expr = true, desc = "Smart shift-tab completion" })
local function clever_shift_tab()
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
end

local function autoclose_on_last_buffer()
  local real_bufs = get_valid_buffers({
    'snacks_picker',
    'snacks_picker_list',
    'lazy',
    'mason',
    'help',
    'qf',
  })
  if #real_bufs == 0 then
    vim.cmd('quit')
  end
end

local function smart_buffer_close(opts)
  Snacks.bufdelete.delete(opts)
  vim.schedule(autoclose_on_last_buffer)
end

local function clear_all()
  vim.cmd('mapclear') -- Clear all keymaps
  vim.cmd('mapclear!') -- Clear all keymaps including those set by plugins
  vim.cmd('nmapclear') -- Clear normal mode keymaps
  vim.cmd('vmapclear') -- Clear visual mode keymaps
  vim.cmd('xmapclear') -- Clear visual block mode keymaps
  vim.cmd('smapclear') -- Clear select mode keymaps
  vim.cmd('omapclear') -- Clear operator-pending mode keymaps
  vim.cmd('imapclear') -- Clear insert mode keymaps
  vim.cmd('lmapclear') -- Clear language map keymaps
  vim.cmd('cmapclear') -- Clear command mode keymaps
  vim.cmd('tmapclear') -- Clear terminal mode keymaps
  vim.cmd('autocmd!') -- Clear all autocommands
  vim.cmd('comclear') -- Clear all user commands
  vim.cmd('highlight clear') -- Clear all highlights
  vim.cmd('set all&') -- Reset all options to their default values
  vim.cmd('filetype off') -- Disable filetype detection
  vim.cmd('syntax off') -- Disable syntax highlighting
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
  return mappings(fn(
    -- buf
    {
      --- Delete buffers without disrupting window layout
      --- @see docs https://github.com/folke/snacks.nvim/blob/main/docs/bufdelete.md#snacksbufdeletedelete
      close = cmd(smart_buffer_close, { wipe = true }),

      --- Delete all buffers
      --- @see docs https://github.com/folke/snacks.nvim/blob/main/docs/bufdelete.md#snacksbufdeleteall
      close_all = cmd(Snacks.bufdelete.all, { wipe = true }),

      --- Delete all buffers except the current one
      --- @see docs https://github.com/folke/snacks.nvim/blob/main/docs/bufdelete.md#snacksbufdeleteother
      close_others = cmd(Snacks.bufdelete.other, { wipe = true }),

      --- Format the current buffer
      --- @see docs https://github.com/stevearc/conform.nvim/blob/main/doc/recipes.md#format-command
      format = cmd(format),

      -- --- Search and pick for Neovim buffers
      -- --- @see docs https://github.com/folke/snacks.nvim/blob/main/docs/picker.md#buffers
      -- pick = cmd(Snacks.picker.buffers),

      -- --- Run a formatter
      -- --- @see docs https://github.com/stevearc/conform.nvim/blob/master/doc/debugging.md#testing-vimsystem
      -- run_formatter = cmd(run_formatter),
    },
    -- pick
    {
      --- Search and pick autocmds
      --- @see docs https://github.com/folke/snacks.nvim/blob/main/docs/picker.md#autocmds
      autocmds = cmd(Snacks.picker.autocmds),

      --- Search and pick for Neovim buffers
      --- @see docs https://github.com/folke/snacks.nvim/blob/main/docs/picker.md#buffers
      buffers = cmd(Snacks.picker.buffers),

      --- Search and pick for Neovim commands
      --- @see docs https://github.com/folke/snacks.nvim/blob/main/docs/picker.md#commands
      commands = cmd(Snacks.picker.commands),

      --- Search and pick for Neovim diagnostics
      --- @see docs https://github.com/folke/snacks.nvim/blob/main/docs/picker.md#diagnostics
      diagnostics = cmd(Snacks.picker.diagnostics, { focus = true, layout = { preset = 'ivy' } }),

      --- Search and pick for Neovim buffer diagnostics
      --- @see docs https://github.com/folke/snacks.nvim/blob/main/docs/picker.md#diagnostics_buffer
      diagnostics_buffer = cmd(Snacks.picker.diagnostics_buffer, { focus = true, layout = { preset = 'ivy' } }),

      --- A file explorer for snacks
      --- @see docs https://github.com/folke/snacks.nvim/blob/main/docs/explorer.md
      explorer = cmd(Snacks.picker.explorer),

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
      find = cmd(Snacks.picker.lines),

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
      help = cmd(Snacks.picker.help),

      --- Search for highlights
      --- @see docs https://github.com/folke/snacks.nvim/blob/main/docs/picker.md#highlights
      highlights = cmd(Snacks.picker.highlights),

      --- Search and pick for jumps
      --- @see docs https://github.com/folke/snacks.nvim/blob/main/docs/picker.md#jumps
      jumps = cmd(Snacks.picker.jumps),

      --- Search and pick for keymaps
      --- @see docs https://github.com/folke/snacks.nvim/blob/main/docs/picker.md#keymaps
      keymaps = cmd(Snacks.picker.keymaps),

      --- Search and pick for Neovim lua_path_items
      lua_path_items = snacks_lua_path_items,

      --- Move current buffer to split to the left, right, top, or bottom
      move_buffer_split = snacks_move_buffer_split,

      --- Search and pick for notifications
      --- @see docs https://github.com/folke/snacks.nvim/blob/main/docs/picker.md#notifications
      notifications = cmd(Snacks.picker.notifications),

      --- Search and pick for Neovim options
      options = snacks_options,

      --- Search and pick for Neovim runtimepath_items
      runtimepath_items = snacks_runtimepath_items,

      --- Search smart for files, buffers, lines, etc
      --- @see docs https://github.com/folke/snacks.nvim/blob/main/docs/picker.md#smart
      smart = cmd(Snacks.picker.smart),
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
            vim.cmd('botright split')
            vim.api.nvim_win_set_buf(0, terminal_state.buf)
            terminal_state.win = vim.api.nvim_get_current_win()
          else
            -- Create new terminal
            vim.cmd('botright split')
            vim.cmd.term()
            terminal_state.buf = vim.api.nvim_get_current_buf()
            terminal_state.win = vim.api.nvim_get_current_win()
          end
          -- Set terminal height
          vim.api.nvim_win_set_height(0, 10)
          -- Enter insert mode and focus the terminal
          vim.cmd.startinsert()
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
      config = cmd(Snacks.picker.lsp_config),

      --- Search and pick for lsp_declarations
      --- @see docs http://github.com/folke/snacks.nvim/blob/main/docs/picker.md#lsp_declarations
      declarations = cmd(Snacks.picker.lsp_declarations),

      --- Search and pick for lsp_definitions
      --- @see docs http://github.com/folke/snacks.nvim/blob/main/docs/picker.md#lsp_definitions
      definitions = cmd(Snacks.picker.lsp_definitions),

      --- Search and pick for
      --- @see docs http://github.com/folke/snacks.nvim/blob/main/docs/picker.md#l
      implementations = cmd(Snacks.picker.lsp_implementations),

      --- Search and pick for lsp_references
      --- @see docs http://github.com/folke/snacks.nvim/blob/main/docs/picker.md#lsp_references
      references = cmd(Snacks.picker.lsp_references),

      --- Search and pick for lsp_symbols
      --- @see docs http://github.com/folke/snacks.nvim/blob/main/docs/picker.md#lsp_symbols
      symbols = cmd(Snacks.picker.lsp_symbols, { layout = 'dropdown', enter = true, focus = 'list' }),

      --- Search and pick for lsp_workspace_symbols
      --- @see docs http://github.com/folke/snacks.nvim/blob/main/docs/picker.md#lsp_workspace_symbols
      workspace_symbols = cmd(
        Snacks.picker.lsp_workspace_symbols,
        { layout = 'dropdown', enter = true, focus = 'list' }
      ),

      --- Search and pick for lsp_type_definitions
      --- @see docs http://github.com/folke/snacks.nvim/blob/main/docs/picker.md#lsp_type_definitions
      type_definitions = cmd(Snacks.picker.lsp_type_definitions),

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
        vim.cmd('source $MYVIMRC')
        vim.cmd('source %')
      end,
    },
    -- setup
    {
      -- nvim 0.10.0 has builtin support for commenting (:h commenting)
      -- NATIVE COMMENTS (https://neovim.io/doc/user/various.html#commenting)
      -- But doesn't work when remapping with `vim.keymap.set` so we call directly...
      -- gc<motion> must to be used manually
      toggle_comments_mappings = function(key)
        vim.cmd('nmap ' .. key .. ' gcc')
        vim.cmd('imap ' .. key .. ' <C-O>gcc')
        vim.cmd('vmap ' .. key .. ' gc')
        vim.cmd('omap ' .. key .. ' gc')
        vim.cmd('xmap ' .. key .. ' gc')
      end,
    }
  ))
end

return set_keymaps
