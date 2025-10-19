local helper = require('core/ui/noice')

local M = {
  icon = helper.ICONS.message
}

M.pick = function()
  return Snacks.notifier.show_history({
    filter = 'info',
    event = helper.QUERIES.MESSAGES.filter.event,
    kind = helper.QUERIES.MESSAGES.filter.kind
  })
end

M.total = function()
  return helper.noice_count_history('messages', helper.QUERIES.MESSAGES)
end

M.show_info = function()
  Snacks.notify.info('Total History Messages Notifications: ' .. tostring(M.total()))
end

return M
