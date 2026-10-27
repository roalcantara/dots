-- Small models copy example values verbatim (issue numbers, footers),
-- so the only examples given are the repository's own recent subjects.
local MAX_CHANGES_CHARS = 12000
local RECENT_SUBJECTS = 12
local HISTORY_SUBJECTS = 300
local KNOWN_SCOPES = 15

local rules = [[
Rules:
- First line: <type>(<scope>): <Subject>, at most 50 characters in total
- Types: feat, fix, docs, style, ref, test, revert, chore, ci, build, perf, git
- Scope: exactly one lowercase word for the main area changed, never a list;
  prefer a scope this repository already uses; omit it if no single area fits
- Subject: imperative mood, capitalized, no period
- Optionally a blank line and a short body explaining why
- Body: wrap every line at 70 characters
- If multiple changes exist, cover the primary one in the subject and mention others in the body
- Return ONLY the commit message: no markdown fences, no explanations, no alternatives]]

local exec_cmd = require('core/etc/sys/exec_cmd')

--- Run a git command, returning its output lines (empty on failure, e.g. no commits yet).
--- @param args string[]
--- @return string[]
local function git_lines(args)
  local ok, output = pcall(exec_cmd, vim.list_extend({ 'git' }, args))
  return (ok and output and output ~= '') and vim.split(output, '\n', { plain = true }) or {}
end

--- How often each scope appears in the given subjects.
--- @param subjects string[]
--- @return table<string, integer>
local function count_scopes(subjects)
  local counts = {}
  for _, subject in ipairs(subjects) do
    local scope = subject:match('^%w+%(([^)]+)%)!?:')
    if scope and scope ~= '*' then
      counts[scope] = (counts[scope] or 0) + 1
    end
  end
  return counts
end

--- Scope names ordered by use, most used first.
--- @param counts table<string, integer>
--- @return string[]
local function top_scopes(counts)
  local names = vim.tbl_keys(counts)
  table.sort(names, function(a, b)
    return counts[a] == counts[b] and a < b or counts[a] > counts[b]
  end)
  return vim.list_slice(names, 1, KNOWN_SCOPES)
end

--- @class ConventionalCommitsInstructions
--- @field system string Instructions for the model
--- @field user string The changes to describe
--- @field hints { scopes: table<string, integer>, paths: string[] } Inputs for format_conventional_commit

--- @return ConventionalCommitsInstructions|nil
return function()
  local changes, change_type = require('core/etc/git/get_changes')()
  if not changes or changes == '' then
    return nil
  end

  if #changes > MAX_CHANGES_CHARS then
    changes = changes:sub(1, MAX_CHANGES_CHARS) .. '\n[diff truncated]'
  end

  local subjects = git_lines({ 'log', '-' .. HISTORY_SUBJECTS, '--format=%s' })
  local scopes = count_scopes(subjects)
  local paths =
    git_lines(change_type == 'staged' and { 'diff', '--cached', '--name-only' } or { 'diff', '--name-only' })

  local system = 'You write git commit messages in the Conventional Commits style used by this repository.'
  if #subjects > 0 then
    system = system
      .. '\nRecent subjects from this repository, for style only:\n'
      .. table.concat(vim.list_slice(subjects, 1, RECENT_SUBJECTS), '\n')
  end
  local known = top_scopes(scopes)
  if #known > 0 then
    system = system .. '\nScopes this repository uses: ' .. table.concat(known, ', ')
  end

  return {
    system = system .. '\n\n' .. rules,
    user = ('Write the commit message for these %s changes:\n\n%s'):format(change_type, changes),
    hints = { scopes = scopes, paths = paths },
  }
end
