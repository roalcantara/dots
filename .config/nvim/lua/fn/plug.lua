local M = {}

---Bootstrap packer.nvim
---@return boolean bootstraped true if first time installation
local function bootstrap()
  local bootstraped = false
  local fn = vim.fn
  local lazy_install_dir = vim.fn.stdpath('data') .. '/site/pack/lazy/start/lazy.nvim'

  return bootstraped
end

---Setup packer plugins
---@param dependencies table @plugins
---Run PackerCompile if there are changes in this file
function M.setup(dependencies)
  local bootstraped = bootstrap()
  local packer = require('packer')
  packer.init({
    auto_clean = true,
    compile_on_sync = true,
    opt_default = false,
    transitive_opt = true,
    transitive_disable = true,
    auto_reload_compiled = true,
    display = {
      open_fn = function()
        return require('packer/util').float({
          border = 'rounded',
        })
      end,
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
        prompt_revert = 'r',
      },
    },
  })

  packer.startup(function(use)
    use({ 'wbthomason/packer.nvim' })

    for _index_0 = 1, #dependencies do
      local plugin = dependencies[_index_0]
      use(plugin)
    end

    if bootstraped then
      packer.sync()
    end
  end)
end

return M
