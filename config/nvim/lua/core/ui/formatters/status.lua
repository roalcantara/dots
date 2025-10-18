local M = {}

-- Cache for formatter status per buffer/filetype
local cache = {}
local cache_timeout = 5000 -- 5 seconds
local last_update = {}

-- Get formatter status for current buffer
--- @param bufnr number|nil Buffer number (defaults to current)
--- @return table Formatter status information
function M.get_formatter_status(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local filetype = vim.api.nvim_buf_get_option(bufnr, 'filetype')

  -- Check cache first
  local cache_key = string.format('%d_%s', bufnr, filetype)
  local now = vim.loop.now()

  if cache[cache_key] and last_update[cache_key] and
    (now - last_update[cache_key]) < cache_timeout then
    return cache[cache_key]
  end

  -- Get formatters for this filetype
  local formatters = M.get_formatters_for_filetype(filetype)
  local status = {
    enabled = {},
    disabled = {},
    total = #formatters
  }

  -- Check each formatter's availability
  for _, formatter in ipairs(formatters) do
    local is_available = M.is_formatter_available(formatter, bufnr)
    if is_available then
      table.insert(status.enabled, formatter)
    else
      table.insert(status.disabled, formatter)
    end
  end

  -- Cache the result
  cache[cache_key] = status
  last_update[cache_key] = now

  return status
end

-- Get all formatters for a filetype
--- @param filetype string File type
--- @return table List of formatter names
function M.get_formatters_for_filetype(filetype)
  local conform = require('conform')

  -- Use the correct API function you provided
  local formatters_for_buffer = conform.list_formatters_for_buffer()

  -- This returns a simple list of formatter names like { "stylua" }
  return formatters_for_buffer
end

-- Check if a formatter is available/installed
--- @param formatter_name string Formatter name
--- @param bufnr number|nil Buffer number
--- @return boolean True if formatter is available
function M.is_formatter_available(formatter_name, bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  local conform = require('conform')

  -- Use the correct API function you provided
  local formatters_to_run = conform.list_formatters_to_run()

  -- Check if the formatter is in the list and available
  for _, formatter_info in ipairs(formatters_to_run) do
    if formatter_info.name == formatter_name then
      return formatter_info.available or false
    end
  end

  return false
end

-- Get detailed formatter information
--- @param formatter_name string Formatter name
--- @param bufnr number|nil Buffer number
--- @return table|nil Detailed formatter information
function M.get_formatter_details(formatter_name, bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  local conform = require('conform')
  local formatter_config = conform.get_formatter_config(formatter_name)

  if not formatter_config then
    return nil
  end

  local formatter_info = conform.get_formatter_info(formatter_name, bufnr)

  return {
    name = formatter_name,
    available = formatter_info and formatter_info.available or false,
    command = formatter_config.command,
    args = formatter_config.args or {},
    description = formatter_config.meta and formatter_config.meta.description or 'No description available',
    url = formatter_config.meta and formatter_config.meta.url or nil,
    stdin = formatter_config.stdin or false,
    cwd = formatter_config.cwd,
  }
end

-- Clear cache for a specific buffer or all buffers
--- @param bufnr number|nil Buffer number (nil clears all)
function M.clear_cache(bufnr)
  if bufnr then
    local filetype = vim.api.nvim_buf_get_option(bufnr, 'filetype')
    local cache_key = string.format('%d_%s', bufnr, filetype)
    cache[cache_key] = nil
    last_update[cache_key] = nil
  else
    cache = {}
    last_update = {}
  end
end

-- Async version that updates cache in background
--- @param bufnr number|nil Buffer number
--- @param callback function Callback function
function M.get_formatter_status_async(bufnr, callback)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  -- Return cached result immediately if available
  local cached_result = M.get_formatter_status(bufnr)
  if callback then
    callback(cached_result)
  end

  -- Update cache in background
  vim.schedule(function()
    M.clear_cache(bufnr)
    local fresh_result = M.get_formatter_status(bufnr)
    if callback then
      callback(fresh_result)
    end
  end)
end

return M
