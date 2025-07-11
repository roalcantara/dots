-- local function to_tb(fn, modes, cmd)
--   local result = {}
--   for _, mode in ipairs(modes) do
--     if fn ~= nil then
--       result[mode] = cmd(fn)
--     end
--   end
--   return result
-- end

-- return to_tb

local function to_map(arr, value)
  local map = {}
  for i = 1, #arr do
    map[arr[i]] = value
  end
  return map
end

return to_map
