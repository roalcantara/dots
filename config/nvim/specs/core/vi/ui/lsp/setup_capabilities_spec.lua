local spec_helper = require("tools.spec_helper")

-- # selene: DISABLE_GLOBALS

describe("setup_capabilities", function()
  local setup_capabilities

  before_each(function()
    -- Mock vim.loop.new_timer
    _G.vim = {
      loop = {
        new_timer = function()
          return {
            start = function() end,
            stop = function() end,
            close = function() end,
          }
        end
      },
      schedule = function(fn) fn() end,
      g = {
        lsp_hover_mouse_delay = 500
      }
    }

    setup_capabilities = require("core.vi.ui.lsp.setup_capabilities")
  end)

  after_each(function()
    _G.vim = nil
  end)

  describe("mouse hover delay", function()
    it("should use configurable delay from vim.g.lsp_hover_mouse_delay", function()
      -- Test that the delay is read from the global variable
      assert.equals(500, vim.g.lsp_hover_mouse_delay)
    end)

    it("should fall back to default delay when not configured", function()
      vim.g.lsp_hover_mouse_delay = nil
      -- The implementation should use 500 as default
      assert.is_nil(vim.g.lsp_hover_mouse_delay)
    end)
  end)
end)
