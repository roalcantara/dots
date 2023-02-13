local has = require('neo/lib/functions/has')
local is_table = require('neo/lib/lang/is_table')
local set
set = function(obj, args)
  if obj == nil then
    obj = { }
  end
  if args == nil then
    args = { }
  end
  if has(args, 'key') then
    if args.force or obj[args.key] == nil then
      obj[args.key] = args.value
    end
  elseif is_table(args) then
    for k, v in ipairs(args) do
      obj = set(obj, {
        key = k,
        value = v
      })
    end
  end
  return obj
end
return set
