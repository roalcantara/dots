local is_nil = require('etc/lang/is_nil')
local is_str = require('etc/lang/is_str')
local is_bool = require('etc/lang/is_bool')
local is_num = require('etc/lang/is_num')
local is_func = require('etc/lang/is_func')
local is_table = require('etc/lang/is_table')
local push = require('etc/tables/push')
local to_table = require('etc/lang/to_table')
local tryCatch = require('etc/fn/try-catch')
local extract_values
extract_values = function(val)
  if is_str(val) or is_num(val) or is_bool(val) or is_nil(val) then
    return val
  end
  if is_func(val) then
    return extract_values(val())
  end
  if is_table(val) then
    local result = { }
    for key, value in ipairs(val) do
      local extracted = extract_values(value)
      if is_num(key) then
        push(result, extracted)
      else
        result[key] = extracted
      end
    end
    return result
  end
end
local extract
extract = function(...)
  local args
  if is_table(...) then
    args = ...
  else
    args = to_table(...)
  end
  return tryCatch(function()
    return extract_values(args), function(e)
      return error("error: args: '" .. tostring(vim.inspect(args)) .. " '" .. tostring(vim.inspect(e)))
    end
  end)
end
return extract
