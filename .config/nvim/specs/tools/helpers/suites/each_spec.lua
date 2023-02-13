local is_nil = require('neo/lib/lodash/lang/is_nil')
local inspect = require('inspect')

local function prepare(case)
  if case.before then
    case.stub = case.before()
  end

  return case
end

local function run(target, ...)
  local args = ...
  return function()
    if not is_nil(args) then
      return target(args)
    end

    return target()
  end
end

local function each(cases, fn)
  for _, case in pairs(cases.scenarios) do
    case = prepare(case)
    fn({
      case = case,
      expected = case.expected,
      when = inspect(case.when),
      run = run(cases.target, case.when)
    })
  end
end

return each
