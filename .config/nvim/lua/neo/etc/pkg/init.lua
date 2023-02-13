local path = require('core/paths/path')
local url = 'https://github.com/wbthomason/packer.nvim'
local packer_config = {
  ensure_dependencies = true,
  plugin_package = 'packer',
  auto_clean = false,
  compile_on_sync = true,
  disable_commands = false,
  opt_default = false,
  transitive_opt = true,
  transitive_disable = true,
  auto_reload_compiled = true,
  display = {
    non_interactive = false,
    open_fn = function()
      return require('packer/util').float({
        border = 'single'
      })
    end,
    open_cmd = 'tabnew [packer]',
    working_sym = '⟳',
    error_sym = '',
    done_sym = '﫠',
    removed_sym = '✘',
    moved_sym = '»',
    header_lines = 2,
    header_sym = '━',
    show_all_info = true,
    prompt_border = 'single',
    keybindings = {
      quit = '<Esc>',
      toggle_info = '<CR>',
      diff = 'd',
      prompt_revert = 'r'
    }
  },
  log = {
    level = 'warn'
  },
  profile = {
    enable = true,
    threshold = 1
  }
}
local clone
clone = function()
  vim.fn.setenv('MACOSX_DEPLOYMENT_TARGET', '10.15')
  local bootstraped = vim.fn.system({
    'git',
    'clone',
    '--depth',
    '1',
    url,
    path.packer.path()
  })
  vim.cmd('packadd packer.nvim')
  return bootstraped
end
local setup_packer
setup_packer = function(packer)
  vim.cmd([[    augroup PackerAutoSync
      autocmd!
      autocmd BufWritePost plugins.lua source bootstrap.lua | PackerCompile
      autocmd User PackerCompileDone ++once source bootstrap.lua | PackerSync
    augroup end
  ]])
  return packer.sync()
end
local boostrap_packer
boostrap_packer = function(packer, plugins, packer_bootstrap)
  return packer.startup({
    function(use)
      use('wbthomason/packer.nvim')
      for _index_0 = 1, #plugins do
        local plugin = plugins[_index_0]
        use(plugin)
      end
      if packer_bootstrap then
        return setup_packer(packer)
      end
    end,
    config = packer_config
  })
end
local load_plugins
load_plugins = function(plugins, packer_bootstrap)
  local status, packer = pcall(require, 'packer')
  if status then
    return boostrap_packer(packer, plugins, packer_bootstrap)
  end
end
local pkg
pkg = function(plugins)
  local packer_bootstrap = false
  if not (path.packer.exists()) then
    packer_bootstrap = clone()
  end
  return load_plugins(plugins, packer_bootstrap)
end
return pkg
