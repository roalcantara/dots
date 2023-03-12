local build_modes = require('core/map/map_modes').build_modes
local build_cmd_modes = require('core/map/map_modes').build_cmd_modes
local build_exec_modes = require('core/map/map_modes').build_exec_modes
local build_run_modes = require('core/map/map_modes').build_run_modes

local scenarios = {
  build_modes = { {
    when = { n = ':m-2<CR>==', i = '<Esc>:m-2<CR>==gi', v = ":m '<-2<CR>gv-gv" },
    expected = {
      n = ':m-2<CR>==',
      i = '<Esc>:m-2<CR>==gi',
      v = ":m '<-2<CR>gv-gv"
    }
  } },
  build_cmd_modes = { {
    when = ':CommentToggle',
    expected = {
      n = '<Cmd>:CommentToggle<Cr>',
      i = '<Esc><Cmd>:CommentToggle<Cr>',
      v = '<Esc><Cmd>:CommentToggle<Cr>'
    }
  } },
  build_exec_modes = { {
    when = 'write',
    expected = {
      n = 'write<Cr>',
      i = '<Esc>write<Cr>',
      v = '<Esc>write<Cr>'
    }
  } },
  build_run_modes = { {
    when = 'b<BS>',
    expected = {
      n = 'b<BS>',
      i = '<Esc>b<BS><Cr>',
      v = '<Esc>b<BS><Cr>'
    }
  } }
}

describe("MapModeFactory", function()
  describe("#build_modes()", function()
    for _, scenario in ipairs(scenarios.build_modes) do
      it("builds modes", function()
        assert.are.same(scenario.expected, build_modes(scenario.when))
      end)
    end
  end)

  describe("#build_cmd_modes()", function()
    for _, scenario in ipairs(scenarios.build_cmd_modes) do
      it("builds cmd modes", function()
        assert.are.same(scenario.expected, build_cmd_modes(scenario.when))
      end)
    end
  end)

  describe("#build_exec_modes()", function()
    for _, scenario in ipairs(scenarios.build_exec_modes) do
      it("builds exec modes", function()
        assert.are.same(scenario.expected, build_exec_modes(scenario.when))
      end)
    end
  end)

  describe("#build_run_modes()", function()
    for _, scenario in ipairs(scenarios.build_run_modes) do
      it("builds run modes", function()
        assert.are.same(scenario.expected, build_run_modes(scenario.when))
      end)
    end
  end)
end)
