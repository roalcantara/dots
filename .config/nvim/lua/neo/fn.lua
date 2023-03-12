local M = {}

function M.get_buf_option(opt)
  local status_ok, buf_option = pcall(vim.api.nvim_buf_get_option, 0, opt)
  if not status_ok then
    return nil
  else
    return buf_option
  end
end

-- recursive Print (structure, limit, separator)
local function r_inspect_settings(structure, limit, separator)
  limit = limit or 100 -- default item limit
  separator = separator or '.' -- indent string
  if limit < 1 then
    print('ERROR: Item limit reached.')
    return limit - 1
  end
  if structure == nil then
    io.write('-- O', separator:sub(2), ' = nil\n')
    return limit - 1
  end
  local ts = type(structure)

  if ts == 'table' then
    for k, v in pairs(structure) do
      -- replace non alpha keys with ['key']
      if tostring(k):match('[^%a_]') then
        k = '["' .. tostring(k) .. '"]'
      end
      limit = r_inspect_settings(v, limit, separator .. '.' .. tostring(k))
      if limit < 0 then
        break
      end
    end
    return limit
  end

  if ts == 'string' then
    -- escape sequences
    structure = string.format('%q', structure)
  end
  separator = separator:gsub('%.%[', '%[')
  if type(structure) == 'function' then
    -- don't print functions
    io.write('-- lvim', separator:sub(2), ' = function ()\n')
  else
    io.write('lvim', separator:sub(2), ' = ', tostring(structure), '\n')
  end
  return limit - 1
end

function M.generate_settings()
  -- Opens a file in append mode
  local file = io.open('lv-settings.lua', 'w')

  -- sets the default output file as test.lua
  io.output(file)

  -- write all `lvim` related settings to `lv-settings.lua` file
  r_inspect_settings(lvim, 10000, '.')

  -- closes the open file
  io.close(file)
end

--- Returns a table with the default values that are missing.
--- either parameter can be empty.
--@param config (table) table containing entries that take priority over defaults
--@param default_config (table) table contatining default values if found
function M.apply_defaults(config, default_config)
  config = config or {}
  default_config = default_config or {}
  local new_config = vim.tbl_deep_extend('keep', vim.empty_dict(), config)
  new_config = vim.tbl_deep_extend('keep', new_config, default_config)
  return new_config
end

return M
