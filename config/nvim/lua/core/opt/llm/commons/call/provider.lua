--- Entry point to call LLM providers.
--- Routes requests to a single provider (anthropic, openai, ollama) or races all and returns the first valid response.

local handle_provider = require('core/opt/llm/commons/handle_provider')

local PROVIDER_NAMES = { 'anthropic', 'openai', 'ollama' }

--- Load provider API module by name.
--- @param name string One of: anthropic, openai, ollama
--- @return table|nil api module or nil if unknown
local function get_provider_api(name)
  if name == 'openai' then
    return (require('core/opt/llm/providers/openai/api'))
  end
  if name == 'anthropic' then
    return (require('core/opt/llm/providers/anthropic/api'))
  end
  if name == 'ollama' then
    return (require('core/opt/llm/providers/ollama/api'))
  end
  return nil
end

--- Call a single provider and return a normalized result.
--- @param provider_name string One of: anthropic, openai, ollama
--- @param input string|table User input
--- @return table { provider = string, response = string, raw = table|nil, error = string|nil }
local function call_one(provider_name, input)
  local api = get_provider_api(provider_name)
  if not api then
    return { provider = provider_name, response = nil, raw = nil, error = 'Unknown provider: ' .. provider_name }
  end

  local ok, result = pcall(function()
    if provider_name == 'openai' then
      return api.responses(input)
    end
    return api.messages(input)
  end)

  if not ok then
    return {
      provider = provider_name,
      response = nil,
      raw = nil,
      error = tostring(result),
    }
  end

  return {
    provider = provider_name,
    response = result,
    raw = nil,
    error = nil,
  }
end

--- Content string to send to providers: use .user (and optional .system) when input is a table.
--- @param input string|table User input (string or table with user/system keys)
--- @return string
local function content_for_request(input)
  if type(input) == 'table' then
    if input.user then
      local user_str = type(input.user) == 'table' and table.concat(input.user, '\n') or input.user
      local system_str = input.system and (type(input.system) == 'table' and table.concat(input.system, '\n') or input.system) or nil
      return system_str and (system_str .. '\n\n' .. user_str) or user_str
    end
    return handle_provider.normalize_input(input)
  end
  return input
end

--- Race all providers: start all, return first valid response and stop the others.
--- @param input string|table User input (string, or table with user/system keys)
--- @param opts table|nil Optional: timeout_ms (number, default 60000)
--- @return table { provider = string, response = string, raw = table, error = nil } or { error = string } if all fail
local function call_all(input, opts)
  opts = opts or {}
  local timeout_ms = opts.timeout_ms or 60000

  local content = content_for_request(input)
  if not content or content == '' then
    return { error = 'No content to send (empty user input)' }
  end

  local providers = {}
  local argv_per_provider = {}
  for _, name in ipairs(PROVIDER_NAMES) do
    local api = get_provider_api(name)
    if api and api.get_request_opts then
      local opts_req = api.get_request_opts()
      local ok_argv, argv = pcall(handle_provider.build_argv, opts_req, content)
      if ok_argv and argv then
        providers[name] = { api = api, opts = opts_req }
        argv_per_provider[name] = argv
      end
    end
  end

  if vim.tbl_count(providers) == 0 then
    return { error = 'No providers available (missing get_request_opts or build_argv failed)' }
  end

  local state = {
    winner = nil,
    pending = {},
    stdout = {},
    errors = {},
  }

  local tried = vim.tbl_keys(argv_per_provider)
  vim.notify(
    ('Generating commit message: trying %s…'):format(table.concat(tried, ', ')),
    vim.log.levels.INFO,
    { title = 'LLM' }
  )

  for provider_name, argv in pairs(argv_per_provider) do
    local job_id = vim.fn.jobstart(argv, {
      stdout_buffered = true,
      on_stdout = function(_, data, _)
        if not state.stdout[provider_name] then
          state.stdout[provider_name] = ''
        end
        state.stdout[provider_name] = state.stdout[provider_name] .. table.concat(data, '')
      end,
      on_exit = function(_, exit_code, _)
        state.pending[provider_name] = nil
        if state.winner then
          return
        end
        if exit_code ~= 0 then
          state.errors[provider_name] = 'exit code ' .. tostring(exit_code)
          return
        end
        local raw_out = state.stdout[provider_name] and vim.trim(state.stdout[provider_name]) or ''
        if raw_out == '' then
          state.errors[provider_name] = 'empty response'
          return
        end
        local decoded_ok, decoded = pcall(vim.json.decode, raw_out)
        if not decoded_ok or not decoded then
          state.errors[provider_name] = 'invalid JSON'
          return
        end
        local parse = providers[provider_name].opts.parse_response
        local text = parse and parse(decoded)
        if not text or text == '' then
          state.errors[provider_name] = 'could not extract text from response'
          return
        end
        state.winner = {
          provider = provider_name,
          response = handle_provider.strip_preamble(text),
          raw = decoded,
          error = nil,
        }
        vim.notify(
          ('Commit message ready (via %s).'):format(provider_name),
          vim.log.levels.INFO,
          { title = 'LLM' }
        )
        for other_name, _ in pairs(state.pending) do
          local other_job_id = state.pending[other_name]
          if other_job_id and type(other_job_id) == 'number' then
            pcall(vim.fn.jobstop, other_job_id)
          end
        end
      end,
    })
    if job_id and job_id > 0 then
      state.pending[provider_name] = job_id
    else
      state.errors[provider_name] = 'failed to start job'
    end
  end

  local poll_interval_ms = 50
  vim.wait(timeout_ms, function()
    return state.winner ~= nil or vim.tbl_count(state.pending) == 0
  end, poll_interval_ms)

  for _, job_id in pairs(state.pending) do
    if type(job_id) == 'number' then
      pcall(vim.fn.jobstop, job_id)
    end
  end

  if state.winner then
    return state.winner
  end

  local parts = {}
  for name, err in pairs(state.errors) do
    table.insert(parts, name .. ': ' .. tostring(err))
  end
  local detail = #parts > 0 and table.concat(parts, '; ') or 'no provider responded in time'
  local msg = 'All providers failed or timed out. ' .. detail
  vim.notify(msg, vim.log.levels.ERROR, { title = 'LLM' })
  return { error = msg }
end

local M = {}

--- Call the chosen LLM provider(s) with the given input.
--- @param provider string One of: "anthropic", "openai", "ollama", "all"
--- @param input string|table User input (string or table of lines)
--- @param opts table|nil Optional. For provider == "all": timeout_ms (number). Ignored for single provider.
--- @return table { provider = string, response = string, raw = table|nil, error = string|nil }
function M.call(provider, input, opts)
  if provider == 'all' then
    return call_all(input, opts)
  end
  return call_one(provider, input)
end

--- List of supported provider names (single + "all").
--- @return string[]
function M.provider_names()
  local names = vim.deepcopy(PROVIDER_NAMES)
  table.insert(names, 'all')
  return names
end

return M
