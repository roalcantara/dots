local put
put = function(prop)
  return function(key, value)
    if type(value) == 'function' then
      value = value()
    end
    vim[prop][key] = value
    return vim[prop][key]
  end
end
return put
