--- Safe require function
--- @param module string Module name
--- @param opts table|nil Options table with silent and default_return keys
--- @return any|nil Module or default_return value
local function safe_require(module, opts)
  opts = opts or {}
  local ok, result = pcall(require, module)
  if not ok then
    if not opts.silent then
      vim.notify("Failed to require: " .. module, vim.log.levels.ERROR)
    end
    return opts.default_return
  end
  return result
end

return safe_require
