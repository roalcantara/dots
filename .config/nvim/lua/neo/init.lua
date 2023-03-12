local M = {}

function M.setup()
  _G.neo = {
    e = require('fn/log').err,
    i = require('fn/log').info,
    require_safe = require('fn/modules').require_safe,
    is_headless = require 'fn/is_headless',
    is_dir = require('fn/io').is_dir,
  }
  require('neo/bootstrap').setup()
end

return M
