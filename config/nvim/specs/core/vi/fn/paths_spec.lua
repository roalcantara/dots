--- @diagnostic disable: duplicate-set-field
local subject = require('core/vi/paths')

describe('#core.vi.paths', function()
  describe('is_executable()', function()
    it('calls vim.fn.executable with the command name and returns true when executable', function()
      -- Create a spy to track calls to vim.fn.executable
      local spy_calls = {}
      local original_executable = vim.fn.executable
      vim.fn.executable = function(name)
        table.insert(spy_calls, name)
        return 1
      end

      local result = subject.is_executable('git')

      -- Verify the function was called with the correct parameter
      assert.equal(1, #spy_calls)
      assert.equal('git', spy_calls[1])
      assert.is_true(result)

      -- Restore original function
      vim.fn.executable = original_executable
    end)

    it('calls vim.fn.executable with the command name and returns false when not executable', function()
      -- Create a spy to track calls to vim.fn.executable
      local spy_calls = {}
      local original_executable = vim.fn.executable
      vim.fn.executable = function(name)
        table.insert(spy_calls, name)
        return 0
      end

      local result = subject.is_executable('nonexistent')

      -- Verify the function was called with the correct parameter
      assert.equal(1, #spy_calls)
      assert.equal('nonexistent', spy_calls[1])
      assert.is_false(result)

      -- Restore original function
      vim.fn.executable = original_executable
    end)
  end)
end)
