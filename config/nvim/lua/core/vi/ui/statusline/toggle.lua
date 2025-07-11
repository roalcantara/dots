---@diagnostic disable: name-style-check
local ICONS = LazyVim.config.icons
-- local refresh = require('core/vi/ui/statusline/refresh')
-- local CONCEAL_LEVEL = 2
-- local function get_conceal_level_or_default()
--   return vim.o.conceallevel > 0 and vim.o.conceallevel or CONCEAL_LEVEL
-- end

-- local h = {
--   toggle_conceal_level = function()
--     Snacks.toggle.option("conceallevel",
--       {
--         off = 0,
--         on = check_conceal_level,
--         name = "Conceal Level"
--       })
--   end,
--   toggle_format = function() return LazyVim.format.snacks_toggle() end,
--   toggle_diagnostics = function() return Snacks.toggle.diagnostics() end,
--   check_relativenumber = function() return vim.o.relativenumber end,
--   check_spell = function() return vim.o.spell end,
--   check_linebreak = function() return vim.o.linebreak end,
--   check_wrap = function() return vim.o.wrap end,
-- }

local function toggle(option, opts)
  return {
    function()
      return opts.icon
    end,
    color = function()
      return { fg = opts.state() and "bg2" or "gray" }
    end,
    on_click = function()
      if opts.on_click then
        return opts.on_click()
      end
      return Snacks.toggle.option(option, { name = option })
    end,
  }
end

return {
  wrap = toggle("wrap", {
    icon = ICONS.misc.wrap,
    state = function()
      return vim.o.wrap
    end,
  }),
  linebreak = toggle("linebreak", {
    icon = ICONS.misc.arrow_left_bottom,
    state = function()
      return vim.o.linebreak
    end,
  }),
  spell = toggle("spell", {
    icon = ICONS.misc.spell,
    state = function()
      return vim.o.spell
    end,
  }),
  relativenumber = toggle("relativenumber", {
    icon = ICONS.misc.numbers,
    state = function()
      return vim.o.relativenumber
    end,
  }),
  conceallevel = toggle("conceallevel", {
    icon = ICONS.misc.eye,
    state = function()
      return vim.o.conceallevel
    end,
  }),
  autoformat = toggle("autoformat", {
    icon = ICONS.misc.wand,
    state = function()
      return vim.g.autoformat
    end,
    on_click = function()
      vim.g.autoformat = not vim.g.autoformat
      return vim.g.autoformat
    end,
  }),
  diagnostics = toggle("diagnostics", {
    icon = ICONS.misc.diagnostic,
    state = function()
      return Snacks.toggle.diagnostics()
    end,
    on_click = function() return Snacks.toggle.diagnostics() end,
  }),
}
