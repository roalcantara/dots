local is_table
is_table = function(value)
  return type(value) == 'table'
end
return is_table
