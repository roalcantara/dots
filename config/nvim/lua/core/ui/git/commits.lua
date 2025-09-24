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
--- @return string? result
function M.generate_conventional_commit_message()
  local instructions = git.get_conventional_commits_instructions()

  if not instructions or instructions == '' then
    return error('No changes found! Skipping...')
  end

  local openai = require('core/opt/openai')

  local ok, result = pcall(openai.api.responses, instructions)

  if not ok or result == nil or result == '' then
    return result
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
    if not ok or result == nil or result == '' then
      return error('Failed to generate commit message: "' .. vim.inspect(result) .. '"')
    end

    loading.stop('Generating commit message...', 'Commit message generated successfully!')
    fill_commit_buffer(result)
  end)
end

return M
