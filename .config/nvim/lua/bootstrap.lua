local bootstraped = false
local fn = vim.fn
local install_dir = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not vim.loop.fs_stat(install_dir) then
  bootstraped = fn.system({
    'git',
    'clone',
    '--filter=blob:none',
    'https://github.com/folke/lazy.nvim.git',
    '--branch=stable',
    install_dir,
  })
  -- vim.schedule(function()
  --   require('neo/lsp').setup()
  -- end)
end
if not vim.tbl_contains(vim.opt.rtp:get(), install_dir) then
  vim.opt.rtp:append(install_dir)
end
