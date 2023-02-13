local is_type
is_type = function(type_name, value)
  if type_name == 'list' then
    return type(value) == 'table' and vim.tbl_islist(value)
  end
  if type_name == 'map' then
    return type(value) == 'table' and not vim.tbl_islist(value)
  end
  return type(value) == type_name
end
return is_type
