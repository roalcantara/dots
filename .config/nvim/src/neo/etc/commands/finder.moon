M = M or {}

-- Detects if we are in a Git repository and invokes either the files or git_files command
-- Mapping: <cmd>lua require('neo/etc/commands/finder').find_files()<cr>
-- https://alpha2phi.medium.com/neovim-for-beginners-fuzzy-file-search-part-1-9df21c0e2c84
M.find_files = ()->
  require('neo/lib/functions/imports') 'fzf-lua', (fzf) ->
    if vim.fn.system('git rev-parse --is-inside-work-tree') == true
      fzf.git_files!
    else
      fzf.files!

return M
