local has
has = function(obj, key)
  return vim.fn.has_key(obj, key) ~= 0
end
return has
