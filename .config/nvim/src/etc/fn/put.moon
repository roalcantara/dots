put = (prop) -> (key, value) ->
  value = value! if type(value) == 'function'
  vim[prop][key] = value
  return vim[prop][key]

return put
