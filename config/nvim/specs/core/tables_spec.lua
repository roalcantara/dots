--- @diagnostic disable: duplicate-set-field, need-check-nil

local tables = require('core/vi/tables')

describe('#core.vi.tables', function()
  describe('prepare_to_concat()', function()
    it('returns the value if it is a table', function()
      local args = { 1, 2, 3 }
      local result = tables.prepare_to_concat(args)
      assert.are.same(result, args)
    end)

    it('returns an empty table if the value is nil', function()
      local result = tables.prepare_to_concat(nil)
      assert.are.same(result, {})
    end)

    it('returns an empty table if the value is an empty table', function()
      local result = tables.prepare_to_concat({})
      assert.are.same(result, {})
    end)

    it('returns a table with a single value if the value is a single value', function()
      local result = tables.prepare_to_concat(1)
      assert.are.same(result, { 1 })
    end)

    it('returns a table with multiple values if the value is a list of values', function()
      local result = tables.prepare_to_concat(1, 2, 3)
      assert.are.same(result, { 1, 2, 3 })
    end)
  end)
end)
