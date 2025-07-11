--- Create a user command wrapper
--- @param name string Command name
--- @param callback function Command callback
--- @param desc string Command description
--- @param opts? table Additional options
local function user_command(name, callback, desc, opts)
  opts = opts or {}
  opts.desc = desc
  vim.api.nvim_create_user_command(name, callback, opts)
end

return user_command
