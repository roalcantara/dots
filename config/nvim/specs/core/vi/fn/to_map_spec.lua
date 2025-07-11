local subject = require("core/vi/fn/to_map")

local function foo() return "foo" end

describe("fn#to_map()", function()
  local test_scenarios = {
    {
      name = "joins single string part",
      arr = { "n", "i", "v" },
      value = foo,
      expected = { n = foo, i = foo, v = foo },
    },
    {
      name = "joins single string part",
      arr = { "n", "i" },
      value = foo,
      expected = { n = foo, i = foo }
    }
  }

  for _, scenario in ipairs(test_scenarios) do
    it(scenario.name, function()
      local result = subject(scenario.arr, scenario.value)
      assert.same(scenario.expected, result)
    end)
  end
end)
