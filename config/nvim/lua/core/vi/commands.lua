-- Command and keymap utilities
local M = {}

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
function M.cmd(command, opts)
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
function M.set_keymap(mode, lhs, rhs, desc, opts)
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
function M.keymap(mode, lhs, rhs, desc, opts)
  if not opts then
    opts = {}
  end

  local success_keymap = pcall(M.set_keymap, mode, lhs, rhs, desc, opts)
  if not success_keymap then
    vim.notify('Failed to set keymap: ' .. lhs .. ' for command: ' .. tostring(rhs), vim.log.levels.ERROR)
  end
end

--- Convert key combination to readable format with symbols
--- @param key string The key combination string
--- @return string The formatted key combination with symbols
function M.format_key_combination(key)
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
function M.format(args)
  local range = nil
  if args.count ~= -1 then
    local end_line = vim.api.nvim_buf_get_lines(0, args.line2 - 1, args.line2, true)[1]
    range = {
      start = { args.line1, 0 },
      ['end'] = { args.line2, end_line and #end_line or 0 },
    }
  end
  require('conform').format({ async = true, lsp_fallback = true, range = range })
end

--- Execute a function when Escape is pressed
--- @param fn function Function to execute
--- @return function Function that executes on Escape
function M.execute_on_esc(fn)
  return function()
    local key = vim.fn.getchar()
    if key == 27 then -- Escape key
      fn()
    end
  end
end

-- Import the rest of the keymap functions from the original set_keymaps.lua
-- This is a simplified version - you may want to copy the full content
local set_keymaps = require('core/vi/maps/set_keymaps')

-- Export the keymap functions
M.set_keymaps = set_keymaps

return M
