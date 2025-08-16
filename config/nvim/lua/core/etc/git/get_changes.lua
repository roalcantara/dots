return function()
  local changes = require('core/etc/git/get_staged_changes')()
  local change_type = "staged"
  if not changes or changes == "" then
    changes = require('core/etc/git/get_unstaged_changes')()
    change_type = "unstaged"
  end
  return changes, change_type
end
