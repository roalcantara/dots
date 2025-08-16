--- Gets the git root for a buffer or path. Defaults to the current buffer
--- @param path? number|string buffer or path
--- @return boolean
--- @see https://github.com/folke/snacks.nvim/blob/main/docs/git.md#snacksgitget_root
local function is_git_repo(path)
  return Snacks.git.get_root(path) ~= nil
end

return is_git_repo
