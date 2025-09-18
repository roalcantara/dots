local conventional_commits_format = [[
<type>[(scope)]: <subject>

[optional body]

[optional footer(s)]

- Types: feat, fix, docs, style, ref, test, revert, chore, ci, build, perf, git
- Include a scope if relevant (e.g. api, ui, auth, admin/users)
- Subject: imperative mood, capitalized, concise, ≤50 characters, no period
- Separate subject from body with a blank line
- Body: explain what and why (not how), wrap at 72 characters
- Reference issues with # (e.g. #123)
- Footer:
    - Breaking changes: BREAKING CHANGE: <description>
    - Issue closure: Closes #<issue-number>
    - Long links: More: <url>
    ]]

return function()
  local changes, change_type = require('core/etc/git/get_changes')()
  if not changes or changes == '' then
    return nil
  end

  local instructions = {
    'Generate the commit message for the following git '
      .. change_type
      .. ' changes:\n\n'
      .. changes
      .. '\n\n'
      .. 'Use the Conventional Commits format:\n\n'
      .. conventional_commits_format
      .. '\n\n'
      .. 'Return only the commit message, no other text or comments.\n\n',
  }

  return instructions
end
