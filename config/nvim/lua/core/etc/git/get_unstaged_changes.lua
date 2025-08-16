--- Get git diff for unstaged changes (fallback)
--- @return string|nil Unstaged changes or nil if error
return function()
  return require('core/etc/sys/exec_cmd')({ 'git', 'diff', '--name-status' })
end
