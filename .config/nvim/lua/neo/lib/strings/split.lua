local split
split = function(inputstr, sep, kwargs)
  if sep == nil then
    sep = ' '
  end
  if kwargs == nil then
    kwargs = true
  end
  return vim.split(inputstr, sep, kwargs)
end
return split
