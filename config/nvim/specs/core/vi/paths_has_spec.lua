--- @diagnostic disable: duplicate-set-field, need-check-nil

local paths = require('core/vi/paths')

describe('#core.vi.paths', function()
  describe('has()', function()
    it('returns a callable for a known executable', function()
      local probe = paths.has('git')
      assert.are.equal('function', type(probe))
    end)

    it('reports true for an executable the mock knows about', function()
      -- spec_helper mocks vim.fn.executable to return 1 only for 'git'
      assert.is_true(paths.has('git')())
    end)

    it('reports false for an unknown executable', function()
      assert.is_false(paths.has('definitely-not-installed')())
    end)
  end)
end)
