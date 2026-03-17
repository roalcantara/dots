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

  local instructions = [[
      Generate a commit for %s changes using the following CONVENTIONAL COMMITS format:
      '''
      %s
      '''

      RULES:
      - Return ONLY the commit message — no explanations, no markdown fences, no alternatives
      - If multiple changes exist, cover the primary one in the subject and mention others in the body
      - Omit body and footer sections if the subject line is self-explanatory

      CHANGES:
      '''
      %s
      '''
    ]]

  return {
    system = 'You are a senior software engineer writing a git commit message.',
    user = string.format(instructions, change_type, changes, conventional_commits_format)
  }
end
