local spec_helper = require("tools.spec_helper")

--# selene: DISABLE_GLOBALS

describe("hover_filter", function()
  local hover_filter

  before_each(function()
    -- Mock vim.treesitter.get_node
    _G.vim = {
      treesitter = {
        get_node = function()
          return {
            type = function() return "identifier" end,
            text = function() return "test_function" end
          }
        end,
        get_node_text = function(node, bufnr)
          return "test_function"
        end
      },
      bo = {
        filetype = "lua"
      },
      fn = {
        match = function(text, pattern)
          return string.match(text, pattern) and 0 or -1
        end
      }
    }

    hover_filter = require("core.vi.ui.lsp.hover_filter")
  end)

  after_each(function()
    _G.vim = nil
  end)

  describe("should_show_hover", function()
    it("should return true for valid identifier nodes", function()
      assert.is_true(hover_filter.should_show_hover())
    end)

    it("should return false for excluded node types", function()
      -- Mock a string node
      _G.vim.treesitter.get_node = function()
        return {
          type = function() return "string" end,
          text = function() return "test_string" end
        }
      end
      _G.vim.treesitter.get_node_text = function(node, bufnr)
        return '"test_string"'
      end

      assert.is_false(hover_filter.should_show_hover())
    end)

    it("should return false for punctuation characters", function()
      -- Mock a punctuation node
      _G.vim.treesitter.get_node = function()
        return {
          type = function() return "(" end,
          text = function() return "(" end
        }
      end
      _G.vim.treesitter.get_node_text = function(node, bufnr)
        return "("
      end

      assert.is_false(hover_filter.should_show_hover())
    end)

    it("should return false for string literals", function()
      -- Mock a string literal node
      _G.vim.treesitter.get_node = function()
        return {
          type = function() return "string_literal" end,
          text = function() return "test_string" end
        }
      end
      _G.vim.treesitter.get_node_text = function(node, bufnr)
        return '"test_string"'
      end

      assert.is_false(hover_filter.should_show_hover())
    end)

    it("should handle treesitter failures gracefully", function()
      -- Mock treesitter failure
      _G.vim.treesitter.get_node = function()
        error("treesitter error")
      end

      assert.is_true(hover_filter.should_show_hover())
    end)
  end)

  describe("debug_current_node", function()
    it("should return node information for valid nodes", function()
      local node_info = hover_filter.debug_current_node()

      assert.is_not_nil(node_info)
      assert.equals("identifier", node_info.type)
      assert.equals("test_function", node_info.text)
      assert.is_true(node_info.should_show_hover)
    end)

    it("should return nil for invalid nodes", function()
      -- Mock treesitter failure
      _G.vim.treesitter.get_node = function()
        error("treesitter error")
      end

      local node_info = hover_filter.debug_current_node()
      assert.is_nil(node_info)
    end)
  end)

  describe("filetype exclusions", function()
    it("should respect filetype-specific exclusions", function()
      -- Add a filetype exclusion
      hover_filter.filetype_exclusions.lua = { "local" }

      -- Mock a local node
      _G.vim.treesitter.get_node = function()
        return {
          type = function() return "local" end,
          text = function() return "local" end
        }
      end
      _G.vim.treesitter.get_node_text = function(node, bufnr)
        return "local"
      end

      assert.is_false(hover_filter.should_show_hover())
    end)
  end)
end)
