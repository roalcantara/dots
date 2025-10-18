local user_command = require('core/vi/maps/user_command')

local VIM_NORMAL_MODE = 'n'

--- Extract options from a table
--- @param values table The table to extract options from
--- @return table The extracted options
local function extract_opts(values)
  local options = {}
  if values and values.range then
    options.range = true
  end
  if values and values.expr then
    options.expr = true
  end
  return options
end

--- Convert key combination to readable format with symbols
--- @param key string The key combination string
--- @return string The formatted key combination with symbols
local function format_key_combination(key)
  -- Ensure key is a string
  if type(key) ~= 'string' then
    return tostring(key)
  end

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

--- Set a keymap
--- @param mode string|table Keymap mode(s)
--- @param lhs string Keymap left hand side
--- @param rhs string|function Keymap right hand side
--- @param desc string Keymap description
--- @param opts table|nil Keymap option
local function keymap_set(mode, lhs, rhs, desc, opts)
  local defaults_opts = {
    desc = desc,    -- Mapping Description
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

  local success_keymap = pcall(keymap_set, mode, lhs, rhs, desc, opts)
  if not success_keymap then
    vim.notify('Failed to set keymap: ' .. tostring(lhs) .. ' for command: ' .. tostring(rhs), vim.log.levels.ERROR)
  end
end

--- Setup a user command
--- @param name string Command name
--- @param action string|function Command action
--- @param desc string Command description
--- @return nil User command is created
local function setup_user_command(name, action, desc)
  local success, err = pcall(user_command, name, action, desc)
  if not success then
    vim.notify(
      "Failed to create user cmd='" .. name .. "', command='" .. tostring(action) .. "': " .. tostring(err),
      vim.log.levels.ERROR
    )
  end
end

--- Extract the command and options from a mapping
--- @param command string|table Command to extract from
--- @param options table Options
--- @param key string Key
--- @param mode string Mode
--- @param desc string Description
--- @return table Result table with actual_command, opts, full_desc, vim_command
local function extract_command_and_opts(command, options, key, mode, desc)
  local full_desc = string.format('[%s] [%s] %s', mode:upper(), format_key_combination(key), desc)
  local actual_command = command
  local vim_command = nil
  local mode_opts = {}
  if type(command) == 'table' then
    -- Handle complex command structure like { callback = func, opts = { expr = true } }
    if command.callback then
      actual_command = command.callback
      mode_opts = command.opts or {}
    elseif command.opts then
      -- Handle { command, opts = { expr = true } } structure
      actual_command = command[1] or command.command
      mode_opts = command.opts or {}
    elseif command.cmd then
      vim_command = command.cmd
      mode_opts = command.opts or {}
    else
      -- Handle simple table structure
      actual_command = command[1] or command.command
      mode_opts = command[2] or command.opts or {}
    end
  end
  local opts = vim.tbl_deep_extend('force', mode_opts, extract_opts(options))
  return {
    actual_command = actual_command,
    opts = opts,
    full_desc = full_desc,
    vim_command = vim_command,
  }
end

--- Setup a keymap and user command
--- @param mode string|table Keymap mode(s)
--- @param key string Keymap left hand side
--- @param action string|function|table Keymap right hand side
--- @param desc string Keymap description
--- @param opts table|nil Keymap option
local function setup_key_combination_and_user_command(mode, key, action, desc, opts)
  local result = extract_command_and_opts(action, opts, key, mode, desc)
  local vim_command = result.vim_command
  if vim_command then
    vim.cmd(vim_command)
  else
    local final_opts = extract_opts(result.opts)
    keymap(mode, key, result.actual_command, result.full_desc, final_opts)
  end
  if opts and opts.cmd then
    setup_user_command(opts.cmd, result.actual_command, result.full_desc)
  end
end

--- Destructure a value from a mapping
--- @param value table Value to destructure
--- @return string Action
--- @return string Description
--- @return table Options
local function destructuring_value(value)
  return value[1], value[2] or '', value[3] or {}
end

--- Parses the mappings table and creates keymaps
--- @param maps table Keymap table
--- @return nil Keymaps are created
return function(maps)
  for key, value in pairs(maps) do
    local action, desc, options = destructuring_value(value)

    if type(action) == 'table' then
      -- Handle mode-specific mappings
      for mode, command in pairs(action) do
        setup_key_combination_and_user_command(mode, key, command, desc, options)
      end
    else
      setup_key_combination_and_user_command(VIM_NORMAL_MODE, key, action, desc, options)
    end
  end
end
