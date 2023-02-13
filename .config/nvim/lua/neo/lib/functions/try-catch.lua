local tryCatch
tryCatch = function(func, catch_f)
  local status, err = pcall(func, { })
  if not (status) then
    return catch_f(err)
  end
end
return tryCatch
