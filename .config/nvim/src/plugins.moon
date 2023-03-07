require('opt/plugins')({
  'nvim-lua/plenary.nvim',
  'nvim-lua/popup.nvim',
  'nathom/filetype.nvim',
  'MunifTanjim/nui.nvim',
  { 'nvim-tree/nvim-web-devicons', config: () -> require('opt/plugins/plug-nvim-web-devicons') },
  { 'folke/which-key.nvim', config: () -> require('opt/plugins/plug-which-key') },
  { 'stevearc/dressing.nvim', config: () -> require('opt/plugins/plug-dressing') },
  { 'lukas-reineke/indent-blankline.nvim', config: () -> require('opt/plugins/plug-indent-blankline') },
  -- look and feel
  { 'folke/tokyonight.nvim', config: () -> require('opt/plugins/plug-tokyonight') },
  { 'akinsho/nvim-bufferline.lua', tag: 'v2.*', config: () -> require('opt/plugins/plug-bufferline') },
  { 'nvim-lualine/lualine.nvim', config: () -> require('opt/plugins/plug-lualine') },
  { 'glepnir/dashboard-nvim', event: 'VimEnter', requires: {'nvim-tree/nvim-web-devicons'}, config: () -> require('opt/plugins/plug-dashboard') },
  { 'kyazdani42/nvim-tree.lua', config: () -> require('opt/plugins/plug-tree') },
  { 'mrjones2014/legendary.nvim', config: () -> require('opt/plugins/plug-legendary') },
  -- treesitter
  { 'nvim-treesitter/nvim-treesitter',
     run: ()->
      ts_update = require('nvim-treesitter/install').update({ with_sync: true })
      ts_update()
    requires: {
      'windwp/nvim-ts-autotag',
      'nvim-treesitter/nvim-treesitter-textobjects'
    },
    config: () -> require('opt/plugins/plug-treesitter')
  },
  -- completion
  { 'hrsh7th/nvim-cmp', requires: {
      { 'hrsh7th/vim-vsnip', config: () -> require('opt/plugins/plug-vsnip') },
      { 'onsails/lspkind-nvim', config: () -> require('opt/plugins/plug-lspkind') },
      { 'uga-rosa/cmp-dictionary', config: () -> require('opt/plugins/plug-cmp-dictionary') },
      { 'petertriho/cmp-git', config: () -> require('opt/plugins/plug-cmp-git') },
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
    config: () -> require('opt/plugins/plug-cmp')
  },
  -- LSP
  -- setup mason so it can manage external tooling
  { 'williamboman/mason.nvim', config: ()-> require('opt/plugins/plug-mason') },
  -- ensure the servers above are installed
  { 'williamboman/mason-lspconfig.nvim', config: ()-> require('opt/plugins/plug-mason-lspconfig') },
  -- automatically install servers
  { 'neovim/nvim-lspconfig', requires: {
      -- Additional lua configuration, makes nvim stuff amazing
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
      { 'folke/trouble.nvim', config: () -> require('opt/plugins/plug-trouble') },
      { 'ray-x/guihua.lua', requires: 'ray-x/go.nvim', run: 'cd lua/fzy && make', config: () ->
        require('opt/plugins/plug-guihua')
      },
      { 'j-hui/fidget.nvim', config: ()->
        status, plugin = pcall(require, 'fidget')
        plugin.setup! if status
      }
    },
    config: ()-> require('opt/plugins/plug-lspconfig')
  },
  { 'lewis6991/gitsigns.nvim', requires: 'tpope/vim-git', config: () ->
    require('opt/plugins/plug-gitsigns')
  },
  { 'ibhagwan/fzf-lua', config: () -> require('opt/plugins/plug-fzf') },
  { 'windwp/nvim-autopairs', config: () -> require('opt/plugins/plug-autopairs') },
  { 'numToStr/Comment.nvim', config: () -> require('opt/plugins/plug-comment') },
  { 'mg979/vim-visual-multi', config: () -> require('opt/plugins/plug-visual-multi') },
  { 'rcarriga/nvim-notify', config: () -> require('opt/plugins/plug-notify') },
  { 'cappyzawa/trim.nvim', config: () -> require('opt/plugins/plug-trim') },
  { 'zimbatm/direnv.vim', config: () -> require('opt/plugins/plug-direnv') }
  { 'leafo/moonscript-vim', ft: 'moon' },
  { 'udalov/kotlin-vim', ft: 'kt' },
  { 'lnl7/vim-nix', ft: 'nix' },
  'editorconfig/editorconfig-vim',
  'norcalli/nvim-colorizer.lua',
  'vijaymarupudi/nvim-fzf',
  'fladson/vim-kitty'
})
