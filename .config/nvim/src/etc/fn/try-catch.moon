--Encapsulate a function call in a try-catch block.
--tryCatch(() print("Hello") end, (e) return error("error: '"..tostring(e).."'") end)
---@param func function @The function to call.
---@param catch_f any @The function to call if an error occurs.
tryCatch = (func, catch_f) ->
  status, err = pcall(func, {})
  catch_f(err) unless status

return tryCatch
