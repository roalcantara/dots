local is_func
is_func = function(value)
  return type(value) == 'function'
end
return is_func
