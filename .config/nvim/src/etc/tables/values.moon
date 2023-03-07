--Creates an array of the own enumerable property values of object.
--@usage _.print(_.values('test'))
-----> {'t', 'e', 's', 't'}
---_.print(_.values({a=1, b=2, c=3}))
-----> {1, 3, 2}
--
---@param object table The object to query. (table|string)
---@return table properties the array of property values.
values = (...) ->
  params = if require('etc/lang/is_table')(...) then ... else require('etc/lang/to_table')(...)
  t = {}
  for slug in *params
    t[#t+1] = slug
  t

return values
