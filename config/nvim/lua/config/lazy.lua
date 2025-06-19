-- Bootstrap lazy.nvim
-- https://lazy.folke.io/installation
local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
  local out = vim.fn.system({ 'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { 'Failed to clone lazy.nvim:\n', 'ErrorMsg' },
      { out,                            'WarningMsg' },
      { '\nPress any key to exit...' },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- lazy.nvim comes with the following defaults:
-- https://lazy.folke.io/configuration
require('lazy').setup({
  spec = {
    -- Import LazyVim core plugins and an optional plugin
    { 'LazyVim/LazyVim', import = 'lazyvim.plugins' },
    -- import extras plugins
    -- Import local plugins
    { import = 'plugins' },
  },
  -- Configure any other settings here. See the documentation for more details.
  defaults = {
    -- By default, only LazyVim plugins will be lazy-loaded. Your custom plugins will load during startup.
    -- If you know what you're doing, you can set this to `true` to have all your custom plugins lazy-loaded by default.
    lazy = false,
    -- It's recommended to leave version=false for now, since a lot the plugin that support versioning,
    -- have outdated releases, which may break your Neovim install.
    version = false, -- always use the latest git commit
    -- version = '*', -- try installing the latest stable version for plugins that support semver
  },
  -- colorscheme that will be used when installing plugins.
  install = {
    missing = true,
    colorscheme = { 'tokyonight', 'habamax' }
  },
  -- automatically check for plugin updates
  checker = { enabled = true, notify = false },
  change_detection = {
    enabled = true,
    notify = false,
  },
  ui = {
    border = "rounded"
  },
  performance = {
    rtp = {
      -- disable some rtp plugins
      disabled_plugins = {
        "gzip",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
        -- 'gzip',
        -- 'netrw',
        -- 'netrwPlugin',
        -- 'netrwSettings',
        -- 'netrwFileHandlers',
        -- 'tarPlugin',
        -- 'tohtml',
        -- 'tutor',
        -- 'zipPlugin',
        -- 'vimball',
        -- 'vimballPlugin',
        -- '2html_plugin',
        -- 'spellfile_plugin',
        -- -- 'matchit',
        -- -- 'matchparen',
      },
    },
  },
  rocks = { enabled = false }, -- disable `luarocks` support completely
})
