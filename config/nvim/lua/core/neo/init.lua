local mini = require('core/neo/mini')
local neo_logger = require('core/neo/logger')

return {
  mini = mini,
  logger = neo_logger,
  level = neo_logger.level,
  debug = neo_logger.debug,
  info = neo_logger.info,
  warn = neo_logger.warn,
  error = neo_logger.error,
  paths = require('core/vi/paths'),
}
