entries = require 'neo/lib/tables/entries'

---Sets a global (g:) variable (vim.api.nvim_set_var)
---var.set('some_global_variable', { key1 = 'value', key2 = 300 })
---https://neovim.io/doc/user/api.html#nvim_set_var()
---@param name string | table  @ Variable name or table of variables
---@param value string | number | boolean | table | nil @ New variable value
set = (name, value)->
  if type(name) == 'table'
    for k, v in pairs(name)
      set(k, v)
  else
    vim.g[name] = value

---Gets a global (g:) variable (vim.api.nvim_get_var)
---print(var.get('some_global_variable'))
---https://neovim.io/doc/user/api.html#nvim_get_var()
---@param name string  @ Variable name
---@return table | string result @ Variable value
get = (name)-> vim.api.nvim_get_var(name)

---Removes a global (g:) variable (vim.api.nvim_del_var)
---print(var.del('some_global_variable'))
---https://neovim.io/doc/user/api.html#nvim_del_var()
---@param name string  @ Variable name
del = (name)-> vim.api.nvim_del_var(name)

return {:set, :get, :del}
