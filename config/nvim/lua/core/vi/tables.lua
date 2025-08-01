-- General utilities
local M = {}

--- Convert array to map
--- @param arr table Array of keys
--- @param value any Value to assign to all keys
--- @return table Map with array elements as keys
function M.to_map(arr, value)
  local map = {}
  for i = 1, #arr do
    map[arr[i]] = value
  end
  return map
end

return M
