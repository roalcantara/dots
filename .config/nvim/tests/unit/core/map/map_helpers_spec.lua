local i = require('inspect')
local M = require('core/lang/vi-modes').MODES
local MapHelpers = require('core/map/map_helpers').MapHelpers
local function parser1(value) return "Parser 1 => " .. value end

local function parser2(value) return "Parser 2 => " .. value end

local function parser4(value) return function() return "Parser 4 => " .. value end end

local subject

describe("#MapHelpers", function()
  before_each(function()
    subject = MapHelpers:new()
  end)

  describe("#extract_value()", function()
    local given = {
      parsers = { [M.n] = parser1, [M.i] = parser2 },
      params = { n = 'vN', i = 'vI', v = 'vV', t = 'vT' },
    }
    context("Given parsers '" ..
      i(given.parsers) .. "' and params '" .. i(given.params) .. "'",
      function()
        local scenarios = {
          { when = { parser = parser1, mode = 'n' }, expected = { mode = 'n', value = 'Parser 1 => vN' } },
          { when = { parser = parser2, mode = 'n' }, expected = { mode = 'n', value = 'Parser 2 => vN' } },
          { when = { parser = parser1, mode = 'i' }, expected = { mode = 'i', value = 'Parser 1 => vI' } },
          { when = { parser = parser2, mode = 'i' }, expected = { mode = 'i', value = 'Parser 2 => vI' } },
          { when = { parser = parser1, mode = 'v' }, expected = { mode = 'v', value = 'Parser 1 => vV' } },
          { when = { parser = parser2, mode = 'v' }, expected = { mode = 'v', value = 'Parser 2 => vV' } },
          { when = { parser = parser1, mode = 'V ' }, expected = { mode = 'v', value = 'Parser 1 => vV' } },
          { when = { parser = parser1, mode = ' V ' }, expected = { mode = 'v', value = 'Parser 1 => vV' } },
          { when = { parser = parser1, mode = 'visual' }, expected = { mode = 'v', value = 'Parser 1 => vV' } },
          { when = { parser = parser2, mode = 'Insert' }, expected = { mode = 'i', value = 'Parser 2 => vI' } },
          { when = { parser = parser1, mode = 'normal' }, expected = { mode = 'n', value = 'Parser 1 => vN' } },
          { when = { parser = parser1, mode = 'x' }, expected = nil },
          { when = { parser = parser1, mode = '' }, expected = nil },
          { when = { parser = parser1, mode = nil }, expected = nil },
          { when = { parser = nil, mode = 'v' }, expected = nil },
          { when = { parser = '', mode = 'v' }, expected = nil }
        }

        for _, scenario in pairs(scenarios) do
          context("extracts value for mode '" ..
            i(scenario.when.mode) .. "' with parser '" .. i(scenario.when.parser) .. "'",
            function()
              it("returns '" .. i(scenario.expected) .. "'",
                function()
                  assert.are.same(scenario.expected,
                    subject:extract_value(scenario.when.mode, scenario.when.parser, given.params))
                end)
            end)
        end
      end)
  end)

  describe("#normalize()", function()
    local scenarios = {
      {
        when = {
          propagate = false,
          params = 'vN',
          modes = { M.n, M.i, M.v },
        },
        expected = { n = 'vN' }
      },
      {
        when = {
          propagate = false,
          params = { Insert = 'vI' },
          modes = { M.n, M.i, M.v },
        },
        expected = { i = 'vI' }
      },
      {
        when = {
          propagate = true,
          params = 'vI',
          modes = { M.n, M.i, M.v },
        },
        expected = { n = 'vI', i = 'vI', v = 'vI' }
      }
    }

    for _, scenario in pairs(scenarios) do
      context("Given '" .. i(scenario.params) .. "'", function()
        it("returns '" .. i(scenario.expected) .. "'", function()
          assert.are.same(scenario.expected,
            subject:normalize(scenario.when.propagate, scenario.when.modes, scenario.when.params))
        end)
      end)
    end
  end)

  describe("#extract()", function()
    local parsers = {
      [M.n] = parser1,
      [M.i] = parser2,
      [M.v] = parser4
    }
    local modes = { M.n, M.i, M.v }
    local scenarios = {
      {
        attrs = {
          propagate = false,
          parsers = parsers,
          modes = modes
        },
        params = 'vN',
        expected = { n = 'Parser 1 => vN' }
      },
      {
        attrs = {
          propagate = false,
          parsers = parsers,
          modes = modes
        },
        params = { n = 'vN', i = 'vI', },
        expected = { n = 'Parser 1 => vN', i = 'Parser 2 => vI' }
      },
      {
        attrs = {
          propagate = false,
          parsers = parsers,
          modes = modes
        },
        params = { n = 'vN', i = 'vI', t = 'vT' },
        expected = { n = 'Parser 1 => vN', i = 'Parser 2 => vI' }
      },
      {
        attrs = {
          propagate = false,
          parsers = parsers,
          modes = modes
        },
        params = { Normal = 'vN', insert = 'vI', t = 'vT' },
        expected = { n = 'Parser 1 => vN', i = 'Parser 2 => vI' }
      }
    }

    for _, scenario in pairs(scenarios) do
      context("Given parsers '" .. i(scenario.attrs.parsers) .. "'", function()
        it("returns '" .. i(scenario.expected) .. "'", function()
          assert.are.same(scenario.expected, subject:extract(scenario.attrs, scenario.params))
        end)
      end)
    end
  end)

  describe("#to_legendary()", function()
    local scenarios = {
      {
        when = {
          ["<C-1>"] = { {
            i = "<Esc><Cmd>BufferLineGoToBuffer 1<Cr>",
            n = "<Cmd>BufferLineGoToBuffer 1<Cr>",
            v = "<Esc><Cmd>BufferLineGoToBuffer 1<Cr>"
          },
            desc = " Go to buffer 1"
          },
          ["<A-.>"] = { {
            i = "<Esc><Cmd>Maps<Cr>",
            n = "<Cmd>Maps<Cr>",
            v = "<Esc><Cmd>Maps<Cr>"
          },
            desc = " Show mappings"
          },
          ["<A-Down>"] = { {
            i = ":m+<CR>==",
            n = ":m '>+1<CR>gv-gv",
            v = ":m+<CR>=="
          },
            desc = " Move line down"
          },
          ["<A-Left>"] = { {
            i = "<Esc>b<BS><Cr>",
            n = "b<BS>",
            v = "<Esc>b<BS><Cr>"
          },
            desc = " Go to after previous word"
          }
        },
        expected = {
          {
            '<A-.>',
            {
              i = "<Esc><Cmd>Maps<Cr>",
              n = "<Cmd>Maps<Cr>",
              v = "<Esc><Cmd>Maps<Cr>"
            },
            description = ' Show mappings',
            opts = { expr = false, noremap = true, silent = true }
          },
          {
            '<A-Down>',
            {
              i = ":m+<CR>==",
              n = ":m '>+1<CR>gv-gv",
              v = ":m+<CR>=="
            },
            description = ' Move line down',
            opts = { expr = false, noremap = true, silent = true }
          },
          {
            '<A-Left>',
            {
              i = "<Esc>b<BS><Cr>",
              n = "b<BS>",
              v = "<Esc>b<BS><Cr>"
            },
            description = ' Go to after previous word',
            opts = { expr = false, noremap = true, silent = true }
          },
          {
            '<C-1>',
            {
              i = "<Esc><Cmd>BufferLineGoToBuffer 1<Cr>",
              n = "<Cmd>BufferLineGoToBuffer 1<Cr>",
              v = "<Esc><Cmd>BufferLineGoToBuffer 1<Cr>"
            },
            description = ' Go to buffer 1',
            opts = { expr = false, noremap = true, silent = true }
          }
        }
      }
    }

    for _, scenario in pairs(scenarios) do
      context("Given the mappings '" .. i(scenario.when) .. "'", function()
        it("returns '" .. i(scenario.expected) .. "'", function()
          assert.are.same(scenario.expected, subject:to_legendary(scenario.when))
        end)
      end)
    end
  end)
end)
