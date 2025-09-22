-- Minimal Neovim configuration
-- https://youtu.be/xGkL2N8w0H4

-- DEBUG MODE
-- By default, vim.log.level is set to vim.log.levels.INFO,
-- so DEBUG messages won't show unless you explicitly lower the log level
-- -----------------------------------------------------------------------------
-- vim.log.level = vim.log.levels.DEBUG
-- nvim --cmd "lua vim.log.level = vim.log.levels.DEBUG"
-- export NVIM_LOG_LEVEL=DEBUG nvim
-- -----------------------------------------------------------------------------

-- Enables or disables the experimental Lua module loader to speed up the loading of Lua modules.
-- • overrides |loadfile()|
-- • adds the Lua loader using the byte-compilation cache
-- • adds the libs loader
-- • removes the default Nvim loader
vim.loader.enable(true)

--- @class Neo
--- @field level number
--- @field debug function
--- @field info function
--- @field warn function
--- @field error function
--- @field mini table
--- @field paths table
_G.Neo = require('core/neo')

-- bootstrap lazy.nvim and your plugins
require('config')
