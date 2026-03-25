local git = require('core/etc/git')
local M = {}

--- Fill the commit message buffer with generated content
--- @param message string The generated commit message
local function fill_commit_buffer(message)
  local buf = vim.api.nvim_get_current_buf()
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end

  -- Split the message by newlines to handle multi-line commit messages
  local message_lines = vim.split(message, '\n', { plain = true })

  -- Prepend the message at the beginning of the existing content without clearing
  local existing_lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local new_lines = {}

  -- Add message lines first
  for _, line in ipairs(message_lines) do
    table.insert(new_lines, line)
  end

  -- Add existing lines
  for _, line in ipairs(existing_lines) do
    table.insert(new_lines, line)
  end

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, new_lines)

  -- Position cursor at the beginning of the message
  vim.api.nvim_win_set_cursor(0, { 1, 0 })

  -- Enter insert mode for easy editing
  --- @diagnostic disable-next-line: undefined-field
  vim.cmd.startinsert()
end

--- Generate a conventional commit message
--- @return table|nil On success: { provider = string, response = string, ... }. On LLM failure: { error = string }. Throws via error() for invalid repo state.
function M.generate_conventional_commit_message()
  local instructions = git.get_conventional_commits_instructions()

  if not instructions or not instructions.user or instructions.user == '' then
    return error('No changes found! Skipping...')
  end

  local provider = require('core/opt/llm/commons/call.provider')

  local ok, result = pcall(provider.call, 'all', instructions)

  if not ok then
    return { error = tostring(result) }
  end
  if result == nil then
    return { error = 'No result from provider' }
  end
  if result.response == nil or result.response == '' then
    return type(result) == 'table' and result or { error = tostring(result) }
  end

  if result.error then
    return error('Failed to generate commit message: "' .. result.error .. '"')
  end

  return result
end

function M.generate_conventional_commit()
  if not git.is_git_repo() then
    return error('Not a git repository! Skipping..')
  end

  local loading = require('core/ui/loading')
  loading.run('Generating commit message...')

  vim.schedule(function()
    local ok, result = pcall(M.generate_conventional_commit_message)
    if not ok or result == nil then
      return error('Failed to generate commit message: "' .. vim.inspect(result) .. '"')
    end
    if type(result) ~= 'table' then
      return error('Failed to generate commit message: unexpected ' .. type(result) .. ' — ' .. vim.inspect(result))
    end
    if result.error then
      return error('Failed to generate commit message: "' .. result.error .. '"')
    end
    local message = result.response
    if not message or message == '' then
      return error('Failed to generate commit message: no response')
    end

    loading.stop('Generating commit message...', ('Commit message generated (%s).'):format((type(result) == 'table' and result.provider) or 'LLM'))
    fill_commit_buffer(message)
  end)
end

return M
