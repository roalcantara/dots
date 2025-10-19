local helper = require('core/ui/noice')

local M = {
  icon = helper.ICONS.history
}

M.pick = function()
  return Snacks.notifier.show_history({
    filter = 'info',
    event = helper.QUERIES.HISTORY.filter.event
  })
end

M.total = function()
  return helper.noice_count_history('history', helper.QUERIES.HISTORY)
end

M.show_info = function()
  Snacks.notify.info('Total History Notifications: ' .. tostring(M.total()))
end

return M
