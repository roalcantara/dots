-- curl http://localhost:8000/v1/chat/completions
-- -H "Content-Type: application/json"
-- -d '{ "model": "gemma-4-E2B-it-oQ4e-mtp", "messages": [ {"role": "user", "content": "Hello"} ],
--       "chat_template_kwargs": { "enable_thinking": false } }'

local handle_provider = require('core/opt/llm/commons/handle_provider')

local M = {
  config = {
    api_url = 'http://localhost:8000/v1/chat/completions',
    -- Tried in order: oMLX refuses a model that does not fit its dynamic memory
    -- ceiling, so the smaller model covers the times the larger one cannot load.
    models = { 'gemma-4-E2B-it-oQ4e-mtp', 'Qwen3-4B-Instruct-2507-4bit' },
    max_tokens = 300,
    temperature = 0,
  },
}

--- Get the API key (optional while oMLX skips verification on localhost).
--- @return string|nil
function M.get_api_key()
  if vim.env.OMLX_API_KEY and vim.env.OMLX_API_KEY ~= '' then
    return vim.env.OMLX_API_KEY
  end
  return nil
end

--- @param model string oMLX model id
--- @param system string|nil Instructions sent as the system message
local function get_request_opts(model, system)
  return {
    api_url = M.config.api_url,
    get_api_key = M.get_api_key,
    optional_credentials = true,
    build_body = function(normalized_input)
      local messages = {}
      if system and system ~= '' then
        table.insert(messages, { role = 'system', content = system })
      end
      table.insert(messages, { role = 'user', content = normalized_input })
      return vim.json.encode({
        model = model,
        max_tokens = M.config.max_tokens,
        temperature = M.config.temperature,
        messages = messages,
        -- Gemma 4 / Qwen3.5 templates otherwise reason before answering.
        chat_template_kwargs = { enable_thinking = false },
      })
    end,
    build_headers = function(api_key)
      if api_key and api_key ~= '' then
        return { 'Authorization: Bearer ' .. api_key }
      end
      return {}
    end,
    parse_response = function(response)
      if
        response.choices
        and response.choices[1]
        and response.choices[1].message
        and response.choices[1].message.content
      then
        return response.choices[1].message.content
      end
      return nil
    end,
  }
end

--- Generate a response with the first oMLX model that can serve it.
--- @param input string|table User input (string, or table with user/system keys)
--- @return string Response text
function M.messages(input)
  local system, user = handle_provider.split_input(input)
  local errors = {}
  for _, model in ipairs(M.config.models) do
    local ok, result = pcall(handle_provider.request, get_request_opts(model, system), user)
    if ok then
      return result
    end
    table.insert(errors, model .. ': ' .. tostring(result))
  end
  error(table.concat(errors, '; '), 0)
end

return M
