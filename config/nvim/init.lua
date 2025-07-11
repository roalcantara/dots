-- Enables or disables the experimental Lua module loader to speed up the loading of Lua modules.
-- • overrides |loadfile()|
-- • adds the Lua loader using the byte-compilation cache
-- • adds the libs loader
-- • removes the default Nvim loader
vim.loader.enable(true)

-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")
