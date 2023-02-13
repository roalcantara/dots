path = require 'core/paths/path'
url = 'https://github.com/wbthomason/packer.nvim'

packer_config =
  ensure_dependencies: true
  plugin_package: 'packer'
  auto_clean: false
  compile_on_sync: true
  disable_commands: false
  opt_default: false
  transitive_opt: true
  transitive_disable: true
  auto_reload_compiled: true
  display:
    non_interactive: false
    open_fn: () -> require('packer/util').float { border: 'single' }
    open_cmd: 'tabnew [packer]'
    working_sym: '⟳'
    error_sym: ''
    done_sym: '﫠'
    removed_sym: '✘'
    moved_sym: '»'
    header_lines: 2
    header_sym: '━'
    show_all_info: true
    prompt_border: 'single'
    keybindings:
      quit: '<Esc>'
      toggle_info: '<CR>'
      diff: 'd'
      prompt_revert: 'r'
  log:
    level: 'warn'
  profile:
    enable: true
    threshold: 1

---Setup packer
---@return boolean result is true if packer is installed
clone = () ->
  vim.fn.setenv('MACOSX_DEPLOYMENT_TARGET', '10.15')
  bootstraped = vim.fn.system({
    'git'
    'clone'
    '--depth'
    '1'
    url
    path.packer.path!
  })
  vim.cmd('packadd packer.nvim')
  bootstraped

setup_packer = (packer) ->
  vim.cmd([[
    augroup PackerAutoSync
      autocmd!
      autocmd BufWritePost plugins.lua source bootstrap.lua | PackerCompile
      autocmd User PackerCompileDone ++once source bootstrap.lua | PackerSync
    augroup end
  ]])
  packer.sync!

boostrap_packer = (packer, plugins, packer_bootstrap) ->
  packer.startup {
    (use) ->
      use('wbthomason/packer.nvim')
      for plugin in *plugins
        use(plugin)
      -- Automatically set up your configuration after cloning packer.nvim
      -- Put this at the end after all plugins
      setup_packer(packer) if packer_bootstrap
    config: packer_config
  }

---Loads all plugins
---@param plugins table @The list of plugins to load
---@return any
load_plugins = (plugins, packer_bootstrap) ->
  status, packer = pcall(require, 'packer')
  boostrap_packer(packer, plugins, packer_bootstrap) if status

---Loads all plugins
---@param plugins table @The list of plugins to load
---@return any
pkg = (plugins) ->
  packer_bootstrap = false
  packer_bootstrap = clone! unless path.packer.exists!
  load_plugins(plugins, packer_bootstrap)

return pkg
