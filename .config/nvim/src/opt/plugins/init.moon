path = require('etc/fn/path')
---Loads all plugins
---@param plugins table @The list of plugins to load
---@return any
pkgs = (plugins) ->
  require('bootstrap')((bootstraped = false)->
    vim.cmd('packadd packer.nvim')
    packer = require 'packer'
    if bootstraped
      vim.cmd([[
        augroup PackerAutoSync
          autocmd!
          autocmd User PackerCompileDone ++once source <afile> | PackerSync
        augroup end
      ]])
      packer.init {
        plugin_package: 'packer'
        disable_commands: true,
        display:
          open_fn: () -> require('packer/util').float { border: 'single' }
      }
    else
      packer.startup {
        (use) ->
          use('wbthomason/packer.nvim')
          for plugin in *plugins
            use(plugin)
          -- Automatically set up your configuration after cloning packer.nvim
          if bootstraped
            vim.cmd([[
              augroup PackerAutoSync
                autocmd!
                autocmd BufWritePost plugins.lua source <afile> | PackerCompile
              augroup end
            ]])
            packer.compile(path.packer.plugins.path) unless path.packer.plugins.exists!
            packer.sync!
        {
          auto_clean: true
          compile_on_sync: true
          disable_commands: false
          ensure_dependencies: true
          plugin_package: 'packer'
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
        }
      }
  )

return pkgs
