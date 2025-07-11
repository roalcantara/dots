local is_loaded_noice, noice_plugin = pcall(require, 'noice')
local is_loaded_copilot_api, copilot_api_plugin = pcall(require, 'copilot/api')
local is_loaded_lazy_status, lazy_status_plugin = pcall(require, 'lazy/status')
local has_active_clients = require 'core/vi/ui/lsp/has_active_clients'
local is_client_active = require 'core/vi/ui/lsp/is_client_active'
local refresh = require 'core/vi/ui/statusline/refresh'
local l_just = require 'core/vi/fn/l_just'
local r_just = require 'core/vi/fn/r_just'
local toggle = require 'core/vi/ui/statusline/toggle'
local ICONS = require('core/vi/ui/icons')()
local COLORS = {
  [''] = Snacks.util.color('Special'),
  ['Normal'] = Snacks.util.color('Special'),
  ['Warning'] = Snacks.util.color('DiagnosticError'),
  ['InProgress'] = Snacks.util.color('DiagnosticWarn'),
  ['Bar'] = '#e2b86b',
}

--- Shows cmd in the statusline
--- @see https://neovim.io/doc/user/options.html#'showcmd'
--- @see https://github.com/nvim-lualine/lualine.nvim/issues/949
---@return table
local function get_cmd()
  if is_loaded_noice and noice_plugin.api.status.command.get then
    return {
      -- showcmd
      is_loaded_noice and noice_plugin.api.status.command.get,
      cond = function()
        return is_loaded_noice and noice_plugin.api.status.command.has()
      end,
      color = Snacks.util.color('Statement'),
    }
  end

  return {
    '%S',
    color = { gui = 'bold', fg = 'cyan' },
  }
end

return {
  toggle_wrap = toggle.wrap,
  toggle_linebreak = toggle.linebreak,
  toggle_spell = toggle.spell,
  toggle_relativenumber = toggle.relativenumber,
  toggle_conceallevel = toggle.conceallevel,
  toggle_format_on_save = toggle.format_on_save,
  toggle_diagnostics = toggle.diagnostics,
  lsp_clients = {
    vim.lsp.get_clients(),
    icon = {
      r_just(ICONS.misc.active_lsp),
      align = 'left',
      color = function() return has_active_clients() and '@attribute' or '@comment' end,
    },
    color = function() return has_active_clients() and '@punctuation' or '@comment' end,
    on_click = function() vim.cmd [[LspInfo]] end,
  },
  copilot = {
    function()
      if is_loaded_copilot_api and copilot_api_plugin then
        local status = copilot_api_plugin.status.data
        return ICONS.kinds.Copilot .. (status.message or '')
      end
    end,
    cond = function() return is_client_active('copilot') end,
    color = function()
      if is_loaded_copilot_api and copilot_api_plugin then
        local status = copilot_api_plugin.status.data
        return COLORS[status.status] or COLORS['']
      end
    end,
  },
  separator = function() return '%=' end,
  branch = { 'branch', icon = { ICONS.git.branch, align = 'left', color = { gui = 'bold' } } },
  time = {
    function() return os.date '%R' end,
    icon = { r_just(ICONS.misc.clock), align = 'left', color = { gui = 'bold' } },
  },
  tabstop = {
    function() return ICONS.misc.tab .. ' ' .. vim.bo.shiftwidth end,
  },
  nvim_diagnostics = {
    'diagnostics',
    sources = { 'nvim_diagnostic' },
    diagnostics_color = {
      error = 'DiagnosticError',
      warn = 'DiagnosticWarn',
      info = 'DiagnosticInfo',
      hint = 'DiagnosticHint',
    },
    symbols = {
      error = r_just(ICONS.diagnostics.error),
      warn = r_just(ICONS.diagnostics.warn),
      info = r_just(ICONS.diagnostics.info),
      hint = r_just(ICONS.diagnostics.hint),
    },
    colored = true,
    on_click = function() vim.cmd 'Diagnostics' end,
    color = { fg = 'Normal', bg = 'NONE' },
  },
  lazy = {
    is_loaded_lazy_status and lazy_status_plugin.updates,
    cond = is_loaded_lazy_status and lazy_status_plugin.has_updates,
    color = '@constructor',
    on_click = function()
      vim.cmd [[Lazy sync]]
      refresh('window', 'statusline')
    end,
  },
  diff = {
    'diff',
    -- source = diff_source,
    symbols = {
      added = r_just(ICONS.git.added),
      modified = r_just(ICONS.git.modified),
      removed = r_just(ICONS.git.removed),
    },
    padding = { left = 2, right = 1 },
    diff_color = {
      added = { fg = 'green' },
      modified = { fg = 'yellow' },
      removed = { fg = 'red' },
    },
    cond = nil,
    color = { fg = 'Normal', bg = 'NONE' },
  },
  filetype = {
    'filetype',
    colored = true,
    icon_only = true,
    separator = '',
    padding = { left = 1, right = 0 },
    on_click = function() vim.cmd([[Ftypes]]) end,
    icon = function()
      if vim.bo.filetype == '' then return ICONS.misc.file_question_mark end
      return '' -- Let lualine handle filetype icons normally
    end,
  },
  filename = {
    'filename',
    path = 1,
    symbols = {
      modified = l_just(ICONS.misc.edit_circle),
      readonly = l_just(ICONS.misc.lock),
      unnamed = l_just(ICONS.misc.file_question_mark),
      newfile = '[New]',
    },
    color = { fg = 'Normal', bg = 'NONE' },
  },
  progress = { 'progress', separator = ' ', padding = { left = 1, right = 0 } },
  location = { 'location', padding = { left = 0, right = 1 } },
  message = {
    -- last line of the last message (`event=show_msg`)
    is_loaded_noice and noice_plugin.api.status.message.get_hl,
    cond = is_loaded_noice and noice_plugin.api.status.message.has,
    color = { fg = 'Constant', bg = 'Constant' },
  },
  search = {
    -- search count messages
    is_loaded_noice and noice_plugin.api.status.search.get,
    cond = is_loaded_noice and noice_plugin.api.status.search.has,
    color = { fg = 'Normal', bg = 'NONE' },
  },
  command = get_cmd(),
  mode = {
    -- showmode` (@recording messages)
    is_loaded_noice and noice_plugin.api.status.mode.get,
    cond = function() return is_loaded_noice and noice_plugin.api.status.mode.has() end,
    color = { fg = 'Constant', bg = 'NONE' },
  },
  scrollbar = {
    function()
      local current_line = vim.fn.line '.'
      local total_lines = vim.fn.line '$'
      local chars = ICONS.misc.bars
      local line_ratio = current_line / total_lines
      local index = math.ceil(line_ratio * #chars)
      return chars[index]
    end,
    padding = { left = 0, right = 0 },
    color = { fg = COLORS['Bar'] },
  },
  treesitter = {
    function() return ICONS.misc.tree end,
    color = function()
      local ts = vim.treesitter.highlighter.active[vim.api.nvim_get_current_buf()]
      return { fg = ts and not vim.tbl_isempty(ts) and 'green' or 'red' }
    end,
  },
  -- https://github.com/nvim-lualine/lualine.nvim/issues/949
  -- keylogger = {
  --   'keylogger',
  --   source = require('neo/fn/map').keylogger(),
  --   color = { gui = 'bold', fg = 'cyan' },
  -- },
}
