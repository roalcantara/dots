-- Smooth scrolling for Vim done right
-- https://github.com/psliwka/vim-smoothie
-- Set it to 0 (or v:false) to disable vim-smoothie
vim.g.smoothie_enabled = true

-- True prevents the plugin from overriding default scrolling keys
-- <C-d> : scroll down one line
-- <C-u> : scroll up one line
-- <C-f> : scroll right one char
-- <C-b> : scroll left one char
-- <C-n> : scroll down one page
-- <C-p> : scroll up one page
vim.g.smoothie_no_default_mappings = false

-- additional, experimental mappings
-- currently gg and G
vim.g.smoothie_experimental_mappings = true
