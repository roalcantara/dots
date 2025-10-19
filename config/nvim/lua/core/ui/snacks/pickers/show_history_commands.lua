local helper = require('core/ui/noice')

local M = {
  icon = helper.ICONS.history
}

M.pick = function()
  return Snacks.notifier.show_history({
    filter = 'info',
    event = helper.QUERIES.SHOW_COMMANDLINE.filter.event,
    kind = helper.QUERIES.SHOW_COMMANDLINE.filter.kind
  })
end

M.total = function()
  return helper.noice_count_history('history', helper.QUERIES.SHOW_COMMANDLINE)
end

M.show_info = function()
  Snacks.notify.info('Total History Command Notifications: ' .. tostring(M.total()))
end

return M
