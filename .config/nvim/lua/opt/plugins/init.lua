local path = require('etc/fn/path')
local pkgs
pkgs = function(plugins)
  return require('bootstrap')(function(bootstraped)
    if bootstraped == nil then
      bootstraped = false
    end
    vim.cmd('packadd packer.nvim')
    local packer = require('packer')
    if bootstraped then
      vim.cmd([[        augroup PackerAutoSync
          autocmd!
          autocmd User PackerCompileDone ++once source <afile> | PackerSync
        augroup end
      ]])
      return packer.init({
        plugin_package = 'packer',
        disable_commands = true,
        display = {
          open_fn = function()
            return require('packer/util').float({
              border = 'single'
            })
          end
        }
      })
    else
      return packer.startup({
        function(use)
          use('wbthomason/packer.nvim')
          for _index_0 = 1, #plugins do
            local plugin = plugins[_index_0]
            use(plugin)
          end
          if bootstraped then
            vim.cmd([[              augroup PackerAutoSync
                autocmd!
                autocmd BufWritePost plugins.lua source <afile> | PackerCompile
              augroup end
            ]])
            if not (path.packer.plugins.exists()) then
              packer.compile(path.packer.plugins.path)
            end
            return packer.sync()
          end
        end,
        {
          auto_clean = true,
          compile_on_sync = true,
          disable_commands = false,
          ensure_dependencies = true,
          plugin_package = 'packer',
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
      })
    end
  end)
end
return pkgs
