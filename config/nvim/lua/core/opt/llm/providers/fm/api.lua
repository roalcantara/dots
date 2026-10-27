-- fm respond --no-stream -m system --guardrails permissive-content-transformations -g
-- -i "You are a senior software engineer..." -- "Generate a commit for..."

local exec_cmd = require('core/etc/sys/exec_cmd')
local handle_provider = require('core/opt/llm/commons/handle_provider')

local M = {
  config = {
    bin = 'fm',
    model = 'system',
    guardrails = 'permissive-content-transformations',
    greedy = true,
  },
}

--- Whether the Foundation Models CLI is installed (macOS 27+).
--- @return boolean
function M.is_available()
  return vim.fn.executable(M.config.bin) == 1
end

--- Build fm argv for a request (no execution).
--- @param input string|table User input (string, or table with user/system keys)
--- @return string[]
function M.build_argv(input)
  local system, user = handle_provider.split_input(input)
  local argv = { M.config.bin, 'respond', '--no-stream', '-m', M.config.model, '--guardrails', M.config.guardrails }
  if M.config.greedy then
    table.insert(argv, '-g')
  end
  if system and system ~= '' then
    vim.list_extend(argv, { '-i', system })
  end
  vim.list_extend(argv, { '--', user })
  return argv
end

--- Generate a response with the on-device Apple Foundation Model.
--- @param input string|table User input (string, or table with user/system keys)
--- @return string Response text
function M.messages(input)
  if not M.is_available() then
    error('fm not found (requires macOS 27)', 0)
  end
  return handle_provider.strip_preamble(exec_cmd(M.build_argv(input)))
end

return M
