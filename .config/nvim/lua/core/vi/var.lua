local entries = require('neo/lib/tables/entries')
local set
set = function(name, value)
  if type(name) == 'table' then
    for k, v in pairs(name) do
      set(k, v)
    end
  else
    vim.g[name] = value
  end
end
local get
get = function(name)
  return vim.api.nvim_get_var(name)
end
local del
del = function(name)
  return vim.api.nvim_del_var(name)
end
return {
  set = set,
  get = get,
  del = del
}
