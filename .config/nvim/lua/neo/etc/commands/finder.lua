local M = M or { }
M.find_files = function()
  return require('neo/lib/functions/imports')('fzf-lua', function(fzf)
    if vim.fn.system('git rev-parse --is-inside-work-tree') == true then
      return fzf.git_files()
    else
      return fzf.files()
    end
  end)
end
return M
