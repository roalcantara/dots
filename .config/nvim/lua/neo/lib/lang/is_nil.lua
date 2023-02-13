local is_nil
is_nil = function(value)
  return type(value) == 'nil'
end
return is_nil
