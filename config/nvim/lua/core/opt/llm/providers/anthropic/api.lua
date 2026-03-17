-- curl https://api.anthropic.com/v1/messages
-- -H "x-api-key: $(gopass show -n --password token/opencode.anthropic.com)"
-- -H "anthropic-version: 2023-06-01"
-- -H "content-type: application/json"
-- -d '{ "model": "claude-sonnet-4-20250514", "max_tokens": 1024, "messages": [ {"role": "user", "content": "Hello, world"} ] }'

local exec_cmd = require('core/etc/sys/exec_cmd')
local handle_provider = require('core/opt/llm/commons/handle_provider')

local M = {
  config = {
    api_url = 'https://api.anthropic.com/v1/messages',
    model = 'claude-sonnet-4-20250514',
    max_tokens = 1024,
    api_version = '2023-06-01',
  },
}

--- Get the Anthropic API key
--- @return string|nil The API key or nil if not found
function M.get_api_key()
  return vim.env.ANTHROPIC_API_KEY or exec_cmd({ 'gopass', 'show', '-n', '--password', 'token/opencode.anthropic.com' })
end

local function get_request_opts()
  return {
    api_url = M.config.api_url,
    get_api_key = M.get_api_key,
    build_body = function(normalized_input)
      return vim.json.encode({
        model = M.config.model,
        max_tokens = M.config.max_tokens,
        messages = { { role = 'user', content = normalized_input } },
      })
    end,
    build_headers = function(api_key)
      return {
        'x-api-key: ' .. api_key,
        'anthropic-version: ' .. M.config.api_version,
      }
    end,
    parse_response = function(response)
      if response.content and response.content[1] and response.content[1].text then
        return response.content[1].text
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
