--- Get git diff for unstaged changes (fallback; file summary followed by the patch)
--- @return string|nil Unstaged changes or nil if error
return function()
  return require('core/etc/sys/exec_cmd')({ 'git', 'diff', '--stat', '--patch' })
end
