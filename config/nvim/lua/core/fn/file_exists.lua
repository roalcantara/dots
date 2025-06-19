local is_file = require('core/fn/is_file')

--- Checks if a file/directpory exists
--- @param file string The file to be checked
--- @return boolean true if the file exists, false otherwise
local function file_exists(file)
  return function(root_dir)
    local raw = root_dir or vim.fn.getcwd() or ''
    if not raw or raw == '' then
      return false
    end
    local value = tostring(raw)
    local values = vim.iter({ value, file }):totable()
    local isfile = is_file(values, { normalize = true, expand = true })
    if isfile then
      print("LazyDev is disabled because a '" .. file .. "' file was found in '" .. raw .. "'")
      return false
    end
    return vim.g.lazydev_enabled == nil or vim.g.lazydev_enabled or false
  end
end

return file_exists
