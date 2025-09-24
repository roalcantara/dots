local exec_cmd = require('core/etc/sys/exec_cmd')

-- curl https://api.openai.com/v1/responses
-- -H "Content-Type: application/json"
-- -H "Authorization: Bearer $(gopass show -n --password tokens/openai.com)"
-- -d '{ "model": "gpt-4.1", "input": "Tell me a three sentence bedtime story about a unicorn." }'

local M = {
  config = {
    api_url = 'https://api.openai.com/v1/responses',
    model = 'gpt-4.1'
  },
}

--- Get the OpenAI API key
--- @return string|nil The API key or nil if not found
function M.get_api_key()
  return vim.env.OPENAI_API_KEY or exec_cmd({ 'gopass', 'show', '-n', '--password', 'tokens/openai.com' })
end

local function get_request_body(input)
  if type(input) == 'table' then
    input = table.concat(input, '\n')
  end

  return vim.json.encode({
    model = M.config.model,
    input = input,
  })
end

function M.responses(input)
  local api_key = M.get_api_key()
  if not api_key then
    return error('No API key found!')
  end

  local body = get_request_body(input)

  local ok, result = pcall(
    exec_cmd,
    {
      'curl',
      '-s',
      M.config.api_url,
      '-H',
      'Content-Type: application/json',
      '-H',
      'Authorization: Bearer ' .. api_key,
      '-d',
      body,
    }
  )

  if not ok or (result and result.stderr) then
    return error(result and result.stderr or 'Unknown error', result and result.code or 0)
  end

  local parsed_ok, response = pcall(vim.json.decode, result)
  if not parsed_ok or not response.output or not response.output[1] or not response.output[1].content or not response.output[1].content[1] or not response.output[1].content[1].text then
    return error('Failed to parse API response: ' .. result, 0)
  end

  return response.output[1].content[1].text
end

return M
