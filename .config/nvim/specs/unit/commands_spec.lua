local entries = require('neo/lib/lodash/tables/entries')
local get_legendary = require('commands').get_legendary
local to_legendary = require('commands').to_legendary

local scenarios = {
  command = {
    {
      [{ History = { ':FzfLua oldfiles', ' Show Recent opened files' } }] =
      { ':History', ':FzfLua oldfiles', description = ' Show Recent opened files' }
    },
    {
      [{ Q = { ':q<bang>', 'Quit' } }] = { ':Q', ':q<bang>', description = 'Quit' }
    }
  },
  commands = {
    when = {
      History = { ':FzfLua oldfiles', ' Show Recent opened files' },
      Q = { ':q<bang>', 'Quit' },
      W = { ':w<bang>', 'Write' },
      MoveUp = { ':m .-2<CR>==', 'Move Selection Up' },
    },
    expected = {
      { ':History', ':FzfLua oldfiles', description = ' Show Recent opened files' },
      { ':MoveUp', ':m .-2<CR>==', description = 'Move Selection Up' },
      { ':Q', ':q<bang>', description = 'Quit' },
      { ':W', ':w<bang>', description = 'Write' },
    }
  }
}

describe("Commands", function()
  describe("#get_legendary()", function()
    describe("with one command", function()
      entries(scenarios.command, function(cmd, value)
        it("returns legendary command ", function()
          entries(cmd, function(key, props)
            assert.are.same(value, get_legendary(key, props))
          end)
        end)
      end)
    end)
  end)

  describe("#to_legendary()", function()
    it("returns legendary command ", function()
      assert.are.same(
        scenarios.commands.expected, to_legendary(scenarios.commands.when)
      )
    end)
  end)
end)
