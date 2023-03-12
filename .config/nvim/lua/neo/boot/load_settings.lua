local M = {}
local log = require('fn/log').d
local io = require 'fn/io'
local paths = require 'fn/paths'

M.load_default_options = function()
  local io = require 'fn/io'

  if not io.is_dir(undodir) then
    vim.fn.mkdir(undodir, 'p')
  end

  ---  SETTINGS  ---
  vim.opt.spelllang:append 'cjk' -- disable spellchecking for asian characters (VIM algorithm does not support it)
  vim.opt.shortmess:append 'c' -- don't show redundant messages from ins-completion-menu
  vim.opt.shortmess:append 'I' -- don't show the default intro message
  vim.opt.whichwrap:append '<,>,[,],h,l'

  ---  DIRECTORIES  ---
  vim.o.undodir = paths.undo()
  vim.go.shadafile = paths.shada()
  vim.go.backupdir = path.backup()
  vim.go.directory = path.swap()
  vim.opt.viewdir = path.view()
  vim.opt.spellfile = path.spellfile()

  for k, v in pairs(require 'settings') do
    vim.opt[k] = v
  end

  vim.filetype.add {
    extension = {
      tex = 'tex',
      zir = 'zir',
      cr = 'crystal',
    },
    pattern = {
      ['[jt]sconfig.*.json'] = 'jsonc',
    },
  }
end

M.load_headless_options = function()
  vim.opt.shortmess = '' -- try to prevent echom from cutting messages off or prompting
  vim.opt.more = false -- don't pause listing when screen is filled
  vim.opt.cmdheight = 9999 -- helps avoiding |hit-enter| prompts.
  vim.opt.columns = 9999 -- set the widest screen possible
  vim.opt.swapfile = false -- don't use a swap file
end

M.load_defaults = function()
  if _G.neo.is_headless then
    M.load_headless_options()
    return
  end
  M.load_default_options()
end

return M
