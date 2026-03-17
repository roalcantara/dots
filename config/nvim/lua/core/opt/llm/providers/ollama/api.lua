-- curl http://localhost:11434/v1/chat/completions
-- -H "Content-Type: application/json"
-- -d '{ "model": "devstral:24b", "messages": [ {"role": "user", "content": "Hello"} ] }'

local exec_cmd = require('core/etc/sys/exec_cmd')
local handle_provider = require('core/opt/llm/commons/handle_provider')

local M = {
  config = {
    api_url = 'http://localhost:11434/v1/chat/completions',
    model = 'devstral:24b',
    max_tokens = 1024,
  },
}

--- Get the API key (optional for local Ollama).
--- @return string|nil
function M.get_api_key()
  if vim.env.OLLAMA_API_KEY and vim.env.OLLAMA_API_KEY ~= '' then
    return vim.env.OLLAMA_API_KEY
  end
  local ok, key = pcall(exec_cmd, { 'gopass', 'show', '-n', '--password', 'tokens/ollama.com' })
  return (ok and key and key ~= '') and key or nil
end

local function get_request_opts()
  return {
    api_url = M.config.api_url,
    get_api_key = M.get_api_key,
    optional_credentials = true,
    build_body = function(normalized_input)
      return vim.json.encode({
        model = M.config.model,
        max_tokens = M.config.max_tokens,
        messages = { { role = 'user', content = normalized_input } },
      })
    end,
    build_headers = function(api_key)
      if api_key and api_key ~= '' then
        return { 'Authorization: Bearer ' .. api_key }
      end
      return {}
    end,
    parse_response = function(response)
      if response.message and response.message.content then
        return response.message.content
      end
      if response.choices and response.choices[1] and response.choices[1].message and response.choices[1].message.content then
        return response.choices[1].message.content
      end
      return nil
    end,
  }
end

function M.messages(content)
  return handle_provider.request(get_request_opts(), content)
end

function M.get_request_opts()
  return get_request_opts()
end

return M
