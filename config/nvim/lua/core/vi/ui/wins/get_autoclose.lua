return function(ft_autoclose, ft_autoclose_ignore)
  local autoclose = ft_autoclose or {}
  local autoclose_ignore = ft_autoclose_ignore or {}
  if type(ft_autoclose) ~= "table" then
    autoclose = { ft_autoclose }
  end
  if type(ft_autoclose_ignore) ~= "table" then
    autoclose_ignore = { ft_autoclose_ignore }
  end
  return autoclose, autoclose_ignore
end
