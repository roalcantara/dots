--- Get git diff for staged changes (file summary followed by the patch)
--- @return string|nil Staged changes or nil if error
return function()
  return require('core/etc/sys/exec_cmd')({ 'git', 'diff', '--cached', '--stat', '--patch' })
end
