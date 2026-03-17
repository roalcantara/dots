-- curl https://api.openai.com/v1/responses
-- -H "Content-Type: application/json"
-- -H "Authorization: Bearer $(gopass show -n --password tokens/openai.com)"
-- -d '{ "model": "gpt-4.1", "input": "Tell me a three sentence bedtime story about a unicorn." }'

local exec_cmd = require('core/etc/sys/exec_cmd')
local handle_provider = require('core/opt/llm/commons/handle_provider')

local M = {
  config = {
    api_url = 'https://api.openai.com/v1/responses',
    model = 'gpt-4.1',
  },
}

--- Get the OpenAI API key
--- @return string|nil The API key or nil if not found
function M.get_api_key()
  return vim.env.OPENAI_API_KEY or exec_cmd({ 'gopass', 'show', '-n', '--password', 'tokens/openai.com' })
end

local function get_request_opts()
  return {
    api_url = M.config.api_url,
    get_api_key = M.get_api_key,
    build_body = function(normalized_input)
      return vim.json.encode({
        model = M.config.model,
        input = normalized_input,
      })
    end,
    build_headers = function(api_key)
      return { 'Authorization: Bearer ' .. api_key }
    end,
    parse_response = function(response)
      if response.output and response.output[1] and response.output[1].content and response.output[1].content[1] and response.output[1].content[1].text then
        return response.output[1].content[1].text
      end
      return nil
    end,
  }
end

function M.responses(input)
  return handle_provider.request(get_request_opts(), input)
end

function M.get_request_opts()
  return get_request_opts()
end

return M
