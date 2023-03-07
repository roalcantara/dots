has = require 'etc/fn/has'
is_table = require 'etc/lang/is_table'

set = (obj, args) ->
  obj = {} if obj == nil
  args = {} if args == nil
  if has(args, 'key')
    obj[args.key] = args.value if args.force or obj[args.key] == nil
  elseif is_table(args) then
    for k, v in ipairs(args) do
      obj = set(obj, {
        key: k
        value: v
      })
  return obj

return set
