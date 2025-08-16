local exec_cmd = require('core/etc/sys/exec_cmd')

local M = {
  config = {
    api_url = 'https://api.anthropic.com/v1/messages',
    model = 'claude-sonnet-4-20250514',
    max_tokens = 1024,
    api_version = '2023-06-01',
  }
}

--- Get the Anthropic API key
--- @return string|nil The API key or nil if not found
function M.get_api_key()
  return vim.env.ANTHROPIC_API_KEY or exec_cmd({ 'gopass', 'show', '-n', '--password', 'token/opencode.anthropic.com' })
end

local function get_request_body(content)
  if type(content) == 'table' then
    content = table.concat(content, "\n")
  end

  return vim.json.encode({
    model = M.config.model,
    max_tokens = M.config.max_tokens,
    messages = { { role = "user", content = content } }
  })
end

-- curl https://api.anthropic.com/v1/messages
-- -H "x-api-key: $(gopass show -n --password token/opencode.anthropic.com)"
-- -H "anthropic-version: 2023-06-01"
-- -H "content-type: application/json"
-- -d '{
--     "model": "claude-sonnet-4-20250514",
--     "max_tokens": 1024,
--     "messages": [ {"role": "user", "content": "Hello, world"} ]
-- }'

function M.messages(content)
  local api_key = M.get_api_key()
  if not api_key then
    return error('No API key found!')
  end

  local body = get_request_body(content)

  local ok, result = pcall(exec_cmd, { 'curl', '-s', M.config.api_url,
    '-H', 'Content-Type: application/json',
    '-H', 'x-api-key: ' .. api_key,
    '-H', 'anthropic-version: ' .. M.config.api_version,
    '-d', body })

  if not ok or (result and result.stderr) then
    return error(result and result.stderr or "Unknown error", result and result.code or 0)
  end

  local parsed_ok, response = pcall(vim.json.decode, result)
  if not parsed_ok or not response.content or not response.content[1] or not response.content[1].text then
    return error("Failed to parse API response: " .. result, 0)
  end

  return response.content[1].text
end

return M
