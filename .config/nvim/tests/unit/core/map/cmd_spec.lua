local CmdFactory = require('core/map/cmd').CmdFactory
local cmd = require('core/map/cmd').cmd
local exec = require('core/map/cmd').exec
local newCmd = require('core/map/cmd').newCmd
local esc = require('core/map/cmd').esc
local gv = require('core/map/cmd').gv

local scenarios = {
  cmd = { {
    when = ':CommentToggle',
    expected = '<Cmd>:CommentToggle<Cr>'
  } },
  esc_cmd = { {
    when = ':CommentToggle',
    expected = '<Esc><Cmd>:CommentToggle<Cr>'
  } },
  run = { {
    when = ':CommentToggle',
    expected = ':CommentToggle<Cr>'
  } },
  newCmd = { {
    when = '',
    expected = CmdFactory:new()
  } },
  esc = { {
    when = ':NvimTreeToggle',
    expected = '<Esc>:NvimTreeToggle'
  } },
  gv = { {
    when = ":m '<-2<CR>gv-",
    expected = ":m '<-2<CR>gv-gv"
  } },
  exec = { {
    when = ":echo 'foo'",
    expected = ":echo 'foo'<Cr>"
  } }
}

describe("CmdFactory", function()
  describe("#cmd()", function()
    for _, scenario in ipairs(scenarios.cmd) do
      it("builds a command", function()
        assert.are.same(scenario.expected, cmd(scenario.when))
      end)
    end
  end)

  describe("#exec()", function()
    for _, scenario in ipairs(scenarios.exec) do
      it("builds a command", function()
        assert.are.same(scenario.expected, exec(scenario.when))
      end)
    end
  end)

  describe("#newCmd()", function()
    for _, scenario in ipairs(scenarios.newCmd) do
      it("builds a command", function()
        assert.are.same(scenario.expected, newCmd())
      end)
    end
  end)

  describe("#esc()", function()
    for _, scenario in ipairs(scenarios.esc) do
      it("builds a command", function()
        assert.are.same(scenario.expected, esc(scenario.when))
      end)
    end
  end)

  describe("#gv()", function()
    for _, scenario in ipairs(scenarios.gv) do
      it("builds a command", function()
        assert.are.same(scenario.expected, gv(scenario.when))
      end)
    end
  end)
end)
