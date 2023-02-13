local isNullOrEmpty = require('neo/lib/lang/is_null')
local is_table = require('neo/lib/lang/is_table')
local to_table = require('neo/lib/lang/to_table')
local props = {
  g = vim.g,
  b = vim.b,
  w = vim.w,
  t = vim.t,
  v = vim.v,
  env = vim.env,
  o = vim.o,
  bo = vim.bo,
  wo = vim.wo,
  go = vim.go,
  opt_global = vim.opt_global,
  opt = vim.opt,
  opt_local = vim.opt_local
}
local get
get = function(key)
  return vim[key]
end
local cmd
cmd = function(command)
  return vim.cmd(command)
end
local append
append = function(key, value)
  if not (is_table(key)) then
    vim[key] = vim[key] + value
  end
  if is_table(key) then
    for k, v in pairs(key) do
      append(k, v)
    end
  end
end
local prepend
prepend = function(key, value)
  if not (is_table(key)) then
    vim[key] = tostring(value) .. tostring(vim[key])
  end
  if is_table(key) then
    for k, v in pairs(key) do
      prepend(k, v)
    end
  end
end
local set_opt_or_var
set_opt_or_var = function(ctx, key, value)
  if isNullOrEmpty(key) then
    return print('[W] [LOAD/#{ctx}] (${key}=${value}) skipped! key: "${key}"..')
  else
    props[ctx][key] = value
    if (ctx == 'bo' or ctx == 'wo') then
      props['go'][key] = value
    end
  end
end
local set_cmd
set_cmd = function(value)
  if isNullOrEmpty(value) then
    return print('[W] [cmd] skipped! Value: "${value}"..')
  else
    return cmd(value)
  end
end
local vi = {
  sysname = function()
    return tostring(vim.loop.os_uname.sysname)
  end,
  is_darwin = function()
    return vim.loop.os_uname.sysname == 'Darwin'
  end,
  set_var_g = function(key, value)
    return set_opt_or_var('g', key, value)
  end,
  set_var_b = function(key, value)
    return set_opt_or_var('b', key, value)
  end,
  set_var_w = function(key, value)
    return set_opt_or_var('w', key, value)
  end,
  set_var_t = function(key, value)
    return set_opt_or_var('t', key, value)
  end,
  set_var_v = function(key, value)
    return set_opt_or_var('v', key, value)
  end,
  set_envar_env = function(key, value)
    return set_opt_or_var('env', key, value)
  end,
  set_go = function(key, value)
    return set_opt_or_var('go', key, value)
  end,
  set_bo = function(key, value)
    return set_opt_or_var('bo', key, value)
  end,
  set_wo = function(key, value)
    return set_opt_or_var('wo', key, value)
  end,
  set_opt = function(key, value)
    return set_opt_or_var('opt', key, value)
  end,
  set_opt_global = function(key, value)
    return set_opt_or_var('opt_global', key, value)
  end,
  set_opt_local = function(key, value)
    return set_opt_or_var('opt_local', key, value)
  end,
  set = function(...)
    local settings
    if is_table(...) then
      settings = ...
    else
      settings = to_table(...)
    end
    for ctx, values in pairs(settings) do
      for key, value in pairs(values) do
        set_opt_or_var(ctx, key, value)
      end
    end
  end,
  cmd = function(...)
    local settings
    if is_table(...) then
      settings = ...
    else
      settings = to_table(...)
    end
    for _, value in pairs(settings) do
      set_cmd(value)
    end
  end,
  put = require('core/vi/put'),
  sys = require('core/vi/system'),
  setup = {
    global_variables = require('core/vi/options/global_variables'),
    opts = require('core/vi/options/opts')
  }
}
return vi
