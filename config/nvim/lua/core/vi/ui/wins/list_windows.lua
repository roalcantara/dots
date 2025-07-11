local get_autoclose = require("core/vi/ui/wins/get_autoclose")

--- List buffers that are not autocloseable, ignoreable or floatable
--- @param ft_autoclose string[]
--- @param ft_autoclose_ignore string[]
--- @return table[] valid_buffers
return function(ft_autoclose, ft_autoclose_ignore)
  local buf_ids = vim.api.nvim_list_bufs()
  local valid_buffers = {}
  for _, buf_id in ipairs(buf_ids) do
    local filetype = vim.api.nvim_get_option_value("filetype", { buf = buf_id })
    local is_autoclose = vim.tbl_contains(ft_autoclose, filetype)
    local is_autoclose_ignore = vim.tbl_contains(ft_autoclose_ignore, filetype)
    if not is_autoclose or is_autoclose_ignore then
      if vim.api.nvim_buf_is_loaded(buf_id) then
        table.insert(valid_buffers, {
          id = buf_id,
          filetype = filetype,
        })
      end
    end
  end
  return valid_buffers
end
-- local all, close, rest = vim.api.nvim_list_wins(), {}, {}
-- for _, win in ipairs(all) do
--   local config = vim.api.nvim_win_get_config(win)
--   local buf = vim.api.nvim_win_get_buf(win)
--   local wininfo = vim.fn.getwininfo(win)[1]
--   local is_ignoreable = vim.tbl_isempty(ft_autoclose_ignore) and false or
--       vim.iter(ft_autoclose_ignore):any(function(pat)
--         return string.match(vim.bo[buf].ft, pat)
--       end)
--   local is_autoclosable = vim.tbl_isempty(ft_autoclose) and true
--       or vim.iter(ft_autoclose):any(function(pat)
--         return string.match(vim.bo[buf].ft, pat)
--       end)
--   local is_float = config.relative ~= ""
--   local is_qf = wininfo.quickfix == 1 or wininfo.loclist == 1

--   if not is_ignoreable and (is_autoclosable or is_float or is_qf) then
--     table.insert(close, win)
--   else
--     table.insert(rest, win)
--   end
-- end

-- return all or {}, rest or {}, close or {}
-- end
