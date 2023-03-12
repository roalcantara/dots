-- Default Settings
-- Besides Vimscript files, Lua files can be loaded automatically from special folders in your runtimepath (:h load-plugins).
-- All *.vim files are sourced before *.lua files.

-- Highlight on yank
vim.cmd([[
  augroup YankHighlight
    autocmd!
    autocmd TextYankPost * silent! lua vim.highlight.on_yank()
  augroup end
]])
