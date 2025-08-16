--- Get git diff for staged changes
--- @return string|nil Staged changes or nil if error
return function()
  return require('core/etc/sys/exec_cmd')({ 'git', 'diff', '--cached', '--name-status' })
end
