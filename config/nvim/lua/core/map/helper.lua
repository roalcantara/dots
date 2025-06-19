local snk = require('core/ui/snacks_helper')

local M = {
  cmd_available_keys = {
    'b',
    'd',
    'e',
    'f',
    'g',
    'i',
    'j',
    'k',
    'l',
    'n',
    'o',
    'p',
    'q',
    'r',
    's',
    't',
    'u',
    'w',
    'y',
    '0',
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '-',
    '=',
    '[',
    ']',
    ';',
    '.',
    'Down',
    'Up',
    'Left',
    'Right',
    'Enter',
    'Bslash',
    'S-a',
    'S-b',
    'S-c',
    'S-d',
    'S-e',
    'S-f',
    'S-g',
    'S-h',
    'S-i',
    'S-j',
    'S-k',
    'S-l',
    'S-m',
    'S-n',
    'S-o',
    'S-p',
    'S-r',
    'S-s',
    'S-t',
    'S-u',
    'S-v',
    'S-w',
    'S-x',
    'S-y',
    'S-z',
    'S-0',
    'S-1',
    'S-2',
    'S-7',
    'S-8',
    'S-9',
    'S--',
    'S-=',
    'S-[',
    'S-]',
    'S-;',
    'S-.',
    'S-Down',
    'S-Up',
    'S-Left',
    'S-Right',
    'S-Backspace',
    'S-Enter',
    'S-Bslash',
    'M-a',
    'M-b',
    'M-c',
    'M-d',
    'M-e',
    'M-f',
    'M-i',
    'M-j',
    'M-k',
    'M-l',
    'M-n',
    'M-o',
    'M-p',
    'M-q',
    'M-r',
    'M-s',
    'M-t',
    'M-u',
    'M-v',
    'M-w',
    'M-x',
    'M-y',
    'M-z',
    'M-0',
    'M-1',
    'M-2',
    'M-3',
    'M-4',
    'M-5',
    'M-6',
    'M-7',
    'M-8',
    'M-9',
    'M--',
    'M-=',
    'M-[',
    'M-]',
    'M-;',
    'M-.',
    'M-Down',
    'M-Up',
    'M-Left',
    'M-Right',
    'M-Backspace',
    'M-Enter',
    'M-Bslash',
    'C-a',
    'C-b',
    'C-c',
    'C-e',
    'C-g',
    'C-h',
    'C-i',
    'C-j',
    'C-k',
    'C-l',
    'C-m',
    'C-n',
    'C-o',
    'C-p',
    'C-r',
    'C-s',
    'C-t',
    'C-u',
    'C-v',
    'C-w',
    'C-x',
    'C-y',
    'C-z',
    'C-0',
    'C-1',
    'C-2',
    'C-3',
    'C-4',
    'C-5',
    'C-6',
    'C-7',
    'C-8',
    'C-9',
    'C--',
    'C-=',
    'C-[',
    'C-]',
    'C-;',
    'C-.',
    'C-Down',
    'C-Up',
    'C-Left',
    'C-Right',
    'C-Backspace',
    'C-Enter',
    'C-Bslash',
    'C-M-a',
    'C-M-b',
    'C-M-c',
    'C-M-d',
    'C-M-e',
    'C-M-f',
    'C-M-g',
    'C-M-h',
    'C-M-i',
    'C-M-j',
    'C-M-k',
    'C-M-l',
    'C-M-m',
    'C-M-n',
    'C-M-o',
    'C-M-p',
    'C-M-r',
    'C-M-s',
    'C-M-t',
    'C-M-u',
    'C-M-v',
    'C-M-w',
    'C-M-x',
    'C-M-y',
    'C-M-z',
    'C-M-0',
    'C-M-1',
    'C-M-2',
    'C-M-3',
    'C-M-4',
    'C-M-5',
    'C-M-7',
    'C-M-8',
    'C-M-9',
    'C-M--',
    'C-M-=',
    'C-M-[',
    'C-M-]',
    'C-M-;',
    'C-M-.',
    'C-M-Down',
    'C-M-Up',
    'C-M-Left',
    'C-M-Right',
    'C-M-Enter',
    'C-M-Bslash',
  },
}

--- Helpers
local helpers = {
  --- Execute a vim command
  ---@param command string|function vim command
  ---@return function
  cmd = function(command)
    if type(command) == 'function' then
      return function()
        command()
      end
    end
    return function()
      return vim.cmd(command)
    end
  end,

  add_user_cmd = function(name, cmd, desc, opts)
    local defaults_opts = {
      desc = desc,  -- Command description
      force = true, -- Override existing command if it exists
    }
    return vim.api.nvim_create_user_command(name, cmd, vim.list_extend(defaults_opts, opts or {}))
  end,
  saves_based_on_mode = function()
    local mode = vim.fn.mode()
    if mode == 'n' then
      return ':w<CR>'
    elseif mode == 'i' then
      return '<C-o>:w<CR>'
    elseif mode:match('^[vV\22]') then
      return '<Esc>:w<CR>gv'
    end
  end,
  --- Set a keymap
  ---@param mode string|table Keymap mode(s)
  ---@param lhs string Keymap left hand side
  ---@param rhs string|function Keymap right hand side
  ---@param desc string Keymap description
  ---@param opts table|nil Keymap option
  set_keymap = function(mode, lhs, rhs, desc, opts)
    local defaults_opts = {
      desc = desc,    -- Mapping Description
      noremap = true, -- Non-recursive mapping
      silent = false, -- Silent mapping
    }
    vim.keymap.set(mode, lhs, rhs, vim.list_extend(defaults_opts, opts or {}))
  end,
}

--- Helper Functions
M.helpers = {
  --- Navigation
  go_to = {
    BoL = helpers.cmd('normal 0'),
    EoL = helpers.cmd('normal $'),
    BoF = helpers.cmd('gg'),
    EoF = helpers.cmd('normal G'),
    buf = {
      prev = helpers.cmd('BufferLineCyclePrev'),
      next = helpers.cmd('BufferLineCycleNext'),
    },
  },

  --- Search and Pickers
  pick = snk.pick,

  --- Buffers
  buf = snk.buf,

  --- Edit
  edit = {
    cut = helpers.cmd('normal x'),
    copy = helpers.cmd('normal y'),
    paste = helpers.cmd('normal P'),
    undo = helpers.cmd('normal U'),
    save = helpers.saves_based_on_mode,
    redo = helpers.cmd('normal <C-r>'),
    new = helpers.cmd('ene | startinsert'),
    select_all = helpers.cmd('normal ggVG'),
    replace_all = helpers.cmd('normal %s///g'),
    rename_file = snk.edit.rename_file,
    -- LINE OPERATIONS
    ln = {
      mv_up = helpers.cmd('normal <C-u>'),
      mv_down = helpers.cmd('normal <C-d>'),
    },
    --- Indent Line Right or Insert Spaces (vim.opt.shiftwidth)
    indent = function()
      if vim.api.nvim_get_current_line():match('^%s*$') then
        return string.rep(' ', vim.opt.shiftwidth:get()) -- Use shiftwidth spaces for empty lines
      else
        return '<Esc>>>i'                                -- Regular indentation for non-empty lines
      end
    end,
  },

  -- UI
  ui = {
    fold = helpers.cmd('normal ['),
    unfold = helpers.cmd('normal ]'),
    fold_all = helpers.cmd('normal zR'),
    unfold_all = helpers.cmd('normal zR'),
  },

  toggle = {
    -- Open a scratch buffer with the given options. If a window is already open with the same buffer, it will be closed instea
    comments = helpers.cmd('gcc'),
    comments_line = helpers.cmd('gc'),
    sidebar_left = snk.pick.explorer,
    diagnostics = snk.pick.diagnostics_buffer,
    diagnostics_in_wks = snk.pick.diagnostics,
    zen_mode = snk.toggle.zen_mode,
    scratch = snk.toggle.scratch,
    news = snk.toggle.news,
    menus = helpers.cmd('FZFLua menus'),
  },

  -- Lsp
  lsp = {
    format = function() return LazyVim.format({ force = true }) end,
    definitions = snk.pick.lsp_definitions,
    declarations = snk.pick.lsp_declarations,
    implementations = snk.pick.lsp_implementations,
    type_definitions = snk.pick.lsp_type_definitions,
    references = snk.pick.lsp_references,
    syms_in_wks = snk.pick.lsp_workspace_symbols,
    syms = snk.pick.lsp_symbols,
    hover_docs = helpers.cmd(vim.lsp.buf.hover),
    code_actions = helpers.cmd(vim.lsp.buf.code_action),
    rename = helpers.cmd('call feedkeys(" cr")<CR>'),
  },

  -- Debug
  debug = {
    pressed_keys = function()
      local keys = vim.fn.getchar()
      print(vim.fn.nr2char(keys))
    end,
  },
}

--- Set a keymap
---@param mode string|table Keymap mode(s)
---@param lhs string Keymap left hand side
---@param rhs string|function Keymap right hand side
---@param desc string Keymap description
---@param opts table|nil Keymap option
function M.map(mode, lhs, rhs, desc, opts)
  if not opts then opts = {} end

  local success_keymap = pcall(helpers.set_keymap, mode, lhs, helpers.cmd(opts.name), desc, opts)
  if not success_keymap then
    vim.notify("Failed to set keymap: " .. lhs .. " for command: " .. opts.name, vim.log.levels.ERROR)
  end
end

--- Set a keymap
---@param name string User command name
---@param cmd string|function User command or function to be executed
---@param desc string User command description
---@param opts table|nil User command options
function M.user_cmd(name, cmd, desc, opts)
  local success_cmd = pcall(helpers.add_user_cmd, name, cmd, desc, opts)
  if not success_cmd then
    vim.notify("Failed to create user command: " .. name, vim.log.levels.ERROR)
    return
  end
end

--- Add user command and keymap at once
--- @param name string User command name
--- @param cmd string|function User command or function to be executed
--- @param mode string|table<"'n'" | "'i'" | "'v'" | table> Keymap mode(s)
--- @param lhs string Keymap left hand side
--- @param desc string Keymap description
--- @param opts table|nil Keymap options
function M.cmd_and_map(name, cmd, mode, lhs, desc, opts)
  helpers.add_user_cmd(name, cmd, desc, opts)
  helpers.set_keymap(mode, lhs, helpers.cmd(name), desc, opts)
end

-- Create a function to safely delete keymaps without errors if they don't exist
local function del(mode, lhs)
  pcall(vim.keymap.del, mode, lhs)
end

--- Disable keymaps
--- @param maps table|nil Keymap table
function M.disable_keymaps(maps)
  maps = maps or {}
  for _, map in ipairs(maps) do
    del(map.mode, map.lhs)
  end
end

return M
