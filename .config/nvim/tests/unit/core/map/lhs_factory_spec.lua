local factory = require('core/map/lhs_factory')
local niv_cmds = factory.niv_cmds
local niv_runs = factory.niv_runs
local niv_execs = factory.niv_execs
local niv = factory.niv
local scenarios = {
  cmds = { {
    when = {
      lhs = ':CommentToggle',
      desc = 'CommentToggle Description'
    },
    expected = {
      {
        n = '<Cmd>:CommentToggle<Cr>',
        i = '<Esc><Cmd>:CommentToggle<Cr>',
        v = '<Esc><Cmd>:CommentToggle<Cr>'
      },
      desc = 'CommentToggle Description'
    }
  } },
  runs = { {
    when = {
      lhs = ':CommentToggle',
      desc = 'CommentToggle Description'
    },
    expected = {
      {
        n = ':CommentToggle',
        i = '<Esc>:CommentToggle<Cr>',
        v = '<Esc>:CommentToggle<Cr>'
      },
      desc = 'CommentToggle Description'
    }
  },
    {
      when = {
        lhs = 'b<BS>',
        desc = ' Go to after previous word'
      },
      expected = {
        {
          n = 'b<BS>',
          i = '<Esc>b<BS><Cr>',
          v = '<Esc>b<BS><Cr>'
        },
        desc = ' Go to after previous word'
      }
    }
  },
  execs = { {
    when = {
      lhs = ':CommentToggle',
      desc = 'CommentToggle Description'
    },
    expected = {
      {
        n = ':CommentToggle<Cr>',
        i = '<Esc>:CommentToggle<Cr>',
        v = '<Esc>:CommentToggle<Cr>'
      },
      desc = 'CommentToggle Description'
    }
  } },
  niv = { {
    when = {
      lhs = { 'CommentToggle', 'CommentToggle', 'CommentToggle' },
      desc = 'CommentToggle Description'
    },
    expected = {
      {
        n = 'CommentToggle',
        i = 'CommentToggle',
        v = 'CommentToggle'
      },
      desc = 'CommentToggle Description'
    }
  } }
}

describe("#LHSFactory", function()
  describe("#niv_cmds()", function()
    for _, scenario in ipairs(scenarios.cmds) do
      it("builds a command", function()
        assert.are.same(scenario.expected, niv_cmds(scenario.when.lhs, scenario.when.desc))
      end)
    end
  end)

  describe("#niv_runs()", function()
    for _, scenario in ipairs(scenarios.runs) do
      it("builds a command", function()
        assert.are.same(scenario.expected, niv_runs(scenario.when.lhs, scenario.when.desc))
      end)
    end
  end)

  describe("#niv_execs()", function()
    for _, scenario in ipairs(scenarios.execs) do
      it("builds a command", function()
        assert.are.same(scenario.expected, niv_execs(scenario.when.lhs, scenario.when.desc))
      end)
    end
  end)

  describe("#niv()", function()
    for _, scenario in ipairs(scenarios.niv) do
      it("builds a command", function()
        assert.are.same(scenario.expected, niv(scenario.when.lhs, scenario.when.desc))
      end)
    end
  end)
end)
