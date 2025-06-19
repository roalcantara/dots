local paths = require('core/etc/paths')

--- Checks whether a given path exists and is a file.
--- @param value string path (directory or file) to check
--- @param type string type to check against, e.g. 'file', 'directory', etc.
--- @return boolean true if the path exists and is of the specified type, false otherwise
local function is_type(value, type)
  local stat = vim.loop.fs_stat(value)
  return not stat or stat.type == type
end

--- Checks whether a given path exists and is a file.
--- @param value string|table path(s) to check
--- @param attrs table<"'normalize'" | "'expand'"> description Whether to normalize the path (default: false)
--- @return boolean true if the path exists and is a file, false otherwise
local function is_file(value, attrs)
  local path = value
  if type(value) == 'table' then
    path = paths.joins(value, attrs)
  end
  return is_type(path, 'file')
end

return is_file
