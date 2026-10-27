local git = require('core/etc/git')
local M = {}

--- Fill the commit message buffer with generated content
--- @param buf integer The buffer the command was run from
--- @param message string The generated commit message
local function fill_commit_buffer(buf, message)
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

  -- Generation runs in the background: only move the cursor if the user is still there
  if vim.api.nvim_get_current_buf() ~= buf then
    return
  end

  -- Position cursor at the beginning of the message
  vim.api.nvim_win_set_cursor(0, { 1, 0 })

  -- Enter insert mode for easy editing
  --- @diagnostic disable-next-line: undefined-field
  vim.cmd.startinsert()
end

--- Generate a conventional commit message
--- @return table|nil On success: { provider = string, response = string, ... }.
---   On LLM failure: { error = string }. Throws via error() for invalid repo state.
function M.generate_conventional_commit_message()
  local instructions = git.get_conventional_commits_instructions()

  if not instructions or not instructions.user or instructions.user == '' then
    return error('No changes found! Skipping...')
  end

  local provider = require('core/opt/llm/commons/call.provider')

  -- Local models first: MLX in a one-shot process (swap 'mlx' for 'omlx' to use
  -- a running oMLX server instead), then Apple's on-device fm (~4k-token
  -- context), then race the remote providers.
  local chain = { 'mlx', 'fm', 'all' }
  local ok, result
  for i, name in ipairs(chain) do
    ok, result = pcall(provider.call, name, instructions)
    if ok and result ~= nil and not result.error then
      break
    end
    if i < #chain then
      local reason = ok and result and result.error or tostring(result)
      vim.notify(
        ('%s failed (%s), trying %s…'):format(name, reason, chain[i + 1]),
        vim.log.levels.WARN,
        { title = 'LLM' }
      )
    end
  end

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

  result.response = git.format_conventional_commit(result.response, instructions.hints)
  return result
end

function M.generate_conventional_commit()
  if not git.is_git_repo() then
    return error('Not a git repository! Skipping..')
  end

  local buf = vim.api.nvim_get_current_buf()
  local loading = require('core/ui/loading')
  local title = 'Generating commit message...'
  loading.run(title)

  local function fail(reason)
    loading.stop(title, 'Commit message generation failed.')
    return error('Failed to generate commit message: ' .. reason)
  end

  -- Runs as a task so model processes and HTTP calls do not freeze the editor
  require('core/etc/sys/async').run(M.generate_conventional_commit_message, function(ok, result)
    if not ok or result == nil then
      return fail(vim.inspect(result))
    end
    if type(result) ~= 'table' then
      return fail('unexpected ' .. type(result) .. ' — ' .. vim.inspect(result))
    end
    if result.error then
      return fail('"' .. result.error .. '"')
    end
    local message = result.response
    if not message or message == '' then
      return fail('no response')
    end

    loading.stop(title, ('Commit message generated (%s).'):format(result.provider or 'LLM'))
    fill_commit_buffer(buf, message)
  end)
end

return M
