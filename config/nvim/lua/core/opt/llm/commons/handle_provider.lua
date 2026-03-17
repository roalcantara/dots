--- Generic LLM provider request handler.
--- Shared logic: API key resolution, curl execution, JSON decode, and error handling.
--- Each provider supplies: api_url, get_api_key, build_body, build_headers, parse_response.

local exec_cmd = require('core/etc/sys/exec_cmd')

--- Strip common preamble patterns (e.g. "Here is the response:").
--- Exported for use in race-all flow where response is parsed outside request().
local function strip_preamble(text)
  return text:gsub('^[^\n]*[Hh]ere.*:\n+', ''):gsub('^%s+', '')
end

--- Normalize input to a single string (table of lines -> newline-joined string).
--- @param input string|table
--- @return string
local function normalize_input(input)
  if type(input) == 'table' then
    return table.concat(input, '\n')
  end
  return input
end

--- Run a single provider request: resolve API key, build body/headers, curl, parse response.
--- @param opts table Provider-specific options:
---   - api_url (string)
---   - get_api_key (function) -> string|nil
---   - build_body (function)(normalized_input: string) -> string JSON body
---   - build_headers (function)(api_key: string|nil) -> string[] header values (e.g. "Authorization: Bearer ...")
---   - parse_response (function)(response: table) -> string|nil extracted text or nil on invalid shape
---   - optional_credentials (boolean|nil) if true, do not error when get_api_key returns nil
--- @param input string|table User input (string or table of lines)
--- @return string Response text
local function request(opts, input)
  local api_key = opts.get_api_key()
  if not opts.optional_credentials and not api_key then
    error('No API key found!')
  end

  local normalized = normalize_input(input)
  local body = opts.build_body(normalized)

  local curl_args = { 'curl', '-s', opts.api_url, '-H', 'Content-Type: application/json' }
  for _, header_value in ipairs(opts.build_headers(api_key)) do
    table.insert(curl_args, '-H')
    table.insert(curl_args, header_value)
  end
  table.insert(curl_args, '-d')
  table.insert(curl_args, body)

  local ok, result = pcall(exec_cmd, curl_args)
  if not ok or (result == nil or result == '') then
    error(result == nil and 'Unknown error' or result, 0)
  end

  local parsed_ok, response = pcall(vim.json.decode, result)
  if not parsed_ok then
    error('Failed to parse API response: ' .. tostring(result), 0)
  end

  local text = opts.parse_response(response)
  if not text then
    error('Failed to parse API response: ' .. tostring(result), 0)
  end

  return strip_preamble(text)
end

--- Build curl argv for a provider request (no execution). Used for parallel "race" calls.
--- @param opts table Same shape as request()
--- @param input string|table User input
--- @return string[] argv for vim.system() or jobstart
local function build_argv(opts, input)
  local api_key = opts.get_api_key()
  if not opts.optional_credentials and not api_key then
    error('No API key found!')
  end
  local normalized = normalize_input(input)
  local body = opts.build_body(normalized)
  local curl_args = { 'curl', '-s', opts.api_url, '-H', 'Content-Type: application/json' }
  for _, header_value in ipairs(opts.build_headers(api_key)) do
    table.insert(curl_args, '-H')
    table.insert(curl_args, header_value)
  end
  table.insert(curl_args, '-d')
  table.insert(curl_args, body)
  return curl_args
end

return {
  request = request,
  normalize_input = normalize_input,
  build_argv = build_argv,
  strip_preamble = strip_preamble,
}
