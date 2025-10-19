local helper = require('core/ui/noice')

local M = {
  icon = helper.ICONS.search
}

M.pick = function()
  return Snacks.notifier.show_history({
    filter = 'info',
    event = helper.QUERIES.SEARCH.filter.event,
    opts = helper.QUERIES.SEARCH.opts,
  })
end

M.total = function()
  return helper.noice_count_history('search', helper.QUERIES.SEARCH_COUNT)
end

M.show_info = function()
  Snacks.notify.info('Total History Searches Notifications: ' .. tostring(M.total()))
end

return M
