return require('neo/etc/pkg')({
  'nvim-lua/plenary.nvim',
  'nvim-lua/popup.nvim',
  'nathom/filetype.nvim',
  'MunifTanjim/nui.nvim',
  {
    'nvim-tree/nvim-web-devicons',
    config = function()
      return require('neo/plugins/plug-nvim-web-devicons')
    end
  },
  {
    'folke/which-key.nvim',
    config = function()
      return require('neo/plugins/plug-which-key')
    end
  },
  {
    'stevearc/dressing.nvim',
    config = function()
      return require('neo/plugins/plug-dressing')
    end
  },
  {
    'lukas-reineke/indent-blankline.nvim',
    config = function()
      return require('neo/plugins/plug-indent-blankline')
    end
  },
  {
    'folke/tokyonight.nvim',
    config = function()
      return require('neo/plugins/plug-tokyonight')
    end
  },
  {
    'akinsho/nvim-bufferline.lua',
    tag = 'v2.*',
    config = function()
      return require('neo/plugins/plug-bufferline')
    end
  },
  {
    'nvim-lualine/lualine.nvim',
    config = function()
      return require('neo/plugins/plug-lualine')
    end
  },
  {
    'glepnir/dashboard-nvim',
    event = 'VimEnter',
    requires = {
      'nvim-tree/nvim-web-devicons'
    },
    config = function()
      return require('neo/plugins/plug-dashboard')
    end
  },
  {
    'kyazdani42/nvim-tree.lua',
    config = function()
      return require('neo/plugins/plug-tree')
    end
  },
  {
    'mrjones2014/legendary.nvim',
    config = function()
      return require('neo/plugins/plug-legendary')
    end
  },
  {
    'nvim-treesitter/nvim-treesitter',
    run = ':TSUpdate',
    requires = {
      'windwp/nvim-ts-autotag',
      'nvim-treesitter/nvim-treesitter-textobjects'
    },
    config = function()
      return require('neo/plugins/plug-treesitter')
    end
  },
  {
    'hrsh7th/nvim-cmp',
    requires = {
      {
        'hrsh7th/vim-vsnip',
        config = function()
          return require('neo/plugins/plug-vsnip')
        end
      },
      {
        'onsails/lspkind-nvim',
        config = function()
          return require('neo/plugins/plug-lspkind')
        end
      },
      {
        'uga-rosa/cmp-dictionary',
        config = function()
          return require('neo/plugins/plug-cmp-dictionary')
        end
      },
      {
        'petertriho/cmp-git',
        config = function()
          return require('neo/plugins/plug-cmp-git')
        end
      },
      'hrsh7th/cmp-nvim-lua',
      'hrsh7th/cmp-nvim-lsp',
      'hrsh7th/cmp-cmdline',
      'hrsh7th/cmp-buffer',
      'hrsh7th/cmp-emoji',
      'hrsh7th/cmp-path',
      'hrsh7th/cmp-vsnip',
      'tamago324/cmp-zsh',
      'ray-x/cmp-treesitter',
      'saadparwaiz1/cmp_luasnip',
      'davidsierradz/cmp-conventionalcommits'
    },
    config = function()
      return require('neo/plugins/plug-cmp')
    end
  },
  {
    'williamboman/mason.nvim',
    config = function()
      return require('neo/plugins/plug-mason')
    end
  },
  {
    'williamboman/mason-lspconfig.nvim',
    config = function()
      return require('neo/plugins/plug-mason-lspconfig')
    end
  },
  {
    'neovim/nvim-lspconfig',
    requires = {
      'hrsh7th/cmp-nvim-lsp',
      'folke/neodev.nvim',
      'tjdevries/manillua.nvim',
      'euclidianAce/BetterLua.vim',
      'b0o/schemastore.nvim',
      'folke/lsp-colors.nvim',
      'RRethy/vim-illuminate',
      'ray-x/lsp_signature.nvim',
      'arkav/lualine-lsp-progress',
      'jose-elias-alvarez/nvim-lsp-ts-utils',
      {
        'folke/trouble.nvim',
        config = function()
          return require('neo/plugins/plug-trouble')
        end
      },
      {
        'ray-x/guihua.lua',
        requires = 'ray-x/go.nvim',
        run = 'cd lua/fzy && make',
        config = function()
          return require('neo/plugins/plug-guihua')
        end
      },
      {
        'j-hui/fidget.nvim',
        config = function()
          local status, plugin = pcall(require, 'fidget')
          if status then
            return plugin.setup()
          end
        end
      }
    },
    config = function()
      return require('neo/plugins/plug-lspconfig')
    end
  },
  {
    'lewis6991/gitsigns.nvim',
    requires = 'tpope/vim-git',
    config = function()
      return require('neo/plugins/plug-gitsigns')
    end
  },
  {
    'ibhagwan/fzf-lua',
    config = function()
      return require('neo/plugins/plug-fzf')
    end
  },
  {
    'windwp/nvim-autopairs',
    after = 'nvim-cmp',
    config = function()
      return require('neo/plugins/plug-autopairs')
    end
  },
  {
    'numToStr/Comment.nvim',
    config = function()
      return require('neo/plugins/plug-comment')
    end
  },
  {
    'mg979/vim-visual-multi',
    config = function()
      return require('neo/plugins/plug-visual-multi')
    end
  },
  {
    'rcarriga/nvim-notify',
    config = function()
      return require('neo/plugins/plug-notify')
    end
  },
  {
    'cappyzawa/trim.nvim',
    config = function()
      return require('neo/plugins/plug-trim')
    end
  },
  {
    'udalov/kotlin-vim',
    ft = 'kt'
  },
  'editorconfig/editorconfig-vim',
  'norcalli/nvim-colorizer.lua',
  'vijaymarupudi/nvim-fzf',
  'wakatime/vim-wakatime',
  'zimbatm/direnv.vim',
  'fladson/vim-kitty',
  'lnl7/vim-nix',
  'leafo/moonscript-vim'
})
