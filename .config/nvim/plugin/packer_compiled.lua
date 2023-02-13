-- Automatically generated packer.nvim plugin loader code

if vim.api.nvim_call_function('has', {'nvim-0.5'}) ~= 1 then
  vim.api.nvim_command('echohl WarningMsg | echom "Invalid Neovim version for packer.nvim! | echohl None"')
  return
end

vim.api.nvim_command('packadd packer.nvim')

local no_errors, error_msg = pcall(function()

_G._packer = _G._packer or {}
_G._packer.inside_compile = true

local time
local profile_info
local should_profile = true
if should_profile then
  local hrtime = vim.loop.hrtime
  profile_info = {}
  time = function(chunk, start)
    if start then
      profile_info[chunk] = hrtime()
    else
      profile_info[chunk] = (hrtime() - profile_info[chunk]) / 1e6
    end
  end
else
  time = function(chunk, start) end
end

local function save_profiles(threshold)
  local sorted_times = {}
  for chunk_name, time_taken in pairs(profile_info) do
    sorted_times[#sorted_times + 1] = {chunk_name, time_taken}
  end
  table.sort(sorted_times, function(a, b) return a[2] > b[2] end)
  local results = {}
  for i, elem in ipairs(sorted_times) do
    if not threshold or threshold and elem[2] > threshold then
      results[i] = elem[1] .. ' took ' .. elem[2] .. 'ms'
    end
  end
  if threshold then
    table.insert(results, '(Only showing plugins that took longer than ' .. threshold .. ' ms ' .. 'to load)')
  end

  _G._packer.profile_output = results
end

time([[Luarocks path setup]], true)
local package_path_str = "/Users/roalcantara/.cache/nvim/packer_hererocks/2.1.0-beta3/share/lua/5.1/?.lua;/Users/roalcantara/.cache/nvim/packer_hererocks/2.1.0-beta3/share/lua/5.1/?/init.lua;/Users/roalcantara/.cache/nvim/packer_hererocks/2.1.0-beta3/lib/luarocks/rocks-5.1/?.lua;/Users/roalcantara/.cache/nvim/packer_hererocks/2.1.0-beta3/lib/luarocks/rocks-5.1/?/init.lua"
local install_cpath_pattern = "/Users/roalcantara/.cache/nvim/packer_hererocks/2.1.0-beta3/lib/lua/5.1/?.so"
if not string.find(package.path, package_path_str, 1, true) then
  package.path = package.path .. ';' .. package_path_str
end

if not string.find(package.cpath, install_cpath_pattern, 1, true) then
  package.cpath = package.cpath .. ';' .. install_cpath_pattern
end

time([[Luarocks path setup]], false)
time([[try_loadstring definition]], true)
local function try_loadstring(s, component, name)
  local success, result = pcall(loadstring(s), name, _G.packer_plugins[name])
  if not success then
    vim.schedule(function()
      vim.api.nvim_notify('packer.nvim: Error running ' .. component .. ' for ' .. name .. ': ' .. result, vim.log.levels.ERROR, {})
    end)
  end
  return result
end

time([[try_loadstring definition]], false)
time([[Defining packer_plugins]], true)
_G.packer_plugins = {
  ["BetterLua.vim"] = {
    loaded = true,
    path = "/Users/roalcantara/.local/share/nvim/site/pack/packer/start/BetterLua.vim",
    url = "https://github.com/euclidianAce/BetterLua.vim"
  },
  ["Comment.nvim"] = {
    config = { "\27LJ\2\n4\0\0\3\0\2\0\0036\0\0\0'\2\1\0D\0\2\0\29neo/plugins/plug-comment\frequire\0" },
    loaded = true,
    path = "/Users/roalcantara/.local/share/nvim/site/pack/packer/start/Comment.nvim",
    url = "https://github.com/numToStr/Comment.nvim"
  },
  ["cmp-buffer"] = {
    loaded = true,
    path = "/Users/roalcantara/.local/share/nvim/site/pack/packer/start/cmp-buffer",
    url = "https://github.com/hrsh7th/cmp-buffer"
  },
  ["cmp-cmdline"] = {
    loaded = true,
    path = "/Users/roalcantara/.local/share/nvim/site/pack/packer/start/cmp-cmdline",
    url = "https://github.com/hrsh7th/cmp-cmdline"
  },
  ["cmp-conventionalcommits"] = {
    loaded = true,
    path = "/Users/roalcantara/.local/share/nvim/site/pack/packer/start/cmp-conventionalcommits",
    url = "https://github.com/davidsierradz/cmp-conventionalcommits"
  },
  ["cmp-dictionary"] = {
    config = { "\27LJ\2\n;\0\0\3\0\2\0\0036\0\0\0'\2\1\0D\0\2\0$neo/plugins/plug-cmp-dictionary\frequire\0" },
    loaded = true,
    path = "/Users/roalcantara/.local/share/nvim/site/pack/packer/start/cmp-dictionary",
    url = "https://github.com/uga-rosa/cmp-dictionary"
  },
  ["cmp-emoji"] = {
    loaded = true,
    path = "/Users/roalcantara/.local/share/nvim/site/pack/packer/start/cmp-emoji",
    url = "https://github.com/hrsh7th/cmp-emoji"
  },
  ["cmp-git"] = {
    config = { "\27LJ\2\n4\0\0\3\0\2\0\0036\0\0\0'\2\1\0D\0\2\0\29neo/plugins/plug-cmp-git\frequire\0" },
    loaded = true,
    path = "/Users/roalcantara/.local/share/nvim/site/pack/packer/start/cmp-git",
    url = "https://github.com/petertriho/cmp-git"
  },
  ["cmp-nvim-lsp"] = {
    loaded = true,
    path = "/Users/roalcantara/.local/share/nvim/site/pack/packer/start/cmp-nvim-lsp",
    url = "https://github.com/hrsh7th/cmp-nvim-lsp"
  },
  ["cmp-nvim-lua"] = {
    loaded = true,
    path = "/Users/roalcantara/.local/share/nvim/site/pack/packer/start/cmp-nvim-lua",
    url = "https://github.com/hrsh7th/cmp-nvim-lua"
  },
  ["cmp-path"] = {
    loaded = true,
    path = "/Users/roalcantara/.local/share/nvim/site/pack/packer/start/cmp-path",
    url = "https://github.com/hrsh7th/cmp-path"
  },
  ["cmp-treesitter"] = {
    loaded = true,
    path = "/Users/roalcantara/.local/share/nvim/site/pack/packer/start/cmp-treesitter",
    url = "https://github.com/ray-x/cmp-treesitter"
  },
  ["cmp-vsnip"] = {
    loaded = true,
    path = "/Users/roalcantara/.local/share/nvim/site/pack/packer/start/cmp-vsnip",
    url = "https://github.com/hrsh7th/cmp-vsnip"
  },
  ["cmp-zsh"] = {
    loaded = true,
    path = "/Users/roalcantara/.local/share/nvim/site/pack/packer/start/cmp-zsh",
    url = "https://github.com/tamago324/cmp-zsh"
  },
  cmp_luasnip = {
    loaded = true,
    path = "/Users/roalcantara/.local/share/nvim/site/pack/packer/start/cmp_luasnip",
    url = "https://github.com/saadparwaiz1/cmp_luasnip"
  },
  ["dashboard-nvim"] = {
    config = { "\27LJ\2\n6\0\0\3\0\2\0\0036\0\0\0'\2\1\0D\0\2\0\31neo/plugins/plug-dashboard\frequire\0" },
    loaded = false,
    needs_bufread = false,
    only_cond = false,
    path = "/Users/roalcantara/.local/share/nvim/site/pack/packer/opt/dashboard-nvim",
    url = "https://github.com/glepnir/dashboard-nvim"
  },
  ["direnv.vim"] = {
    loaded = true,
    path = "/Users/roalcantara/.local/share/nvim/site/pack/packer/start/direnv.vim",
    url = "https://github.com/zimbatm/direnv.vim"
  },
  ["dressing.nvim"] = {
    config = { "\27LJ\2\n5\0\0\3\0\2\0\0036\0\0\0'\2\1\0D\0\2\0\30neo/plugins/plug-dressing\frequire\0" },
    loaded = true,
    path = "/Users/roalcantara/.local/share/nvim/site/pack/packer/start/dressing.nvim",
    url = "https://github.com/stevearc/dressing.nvim"
  },
  ["editorconfig-vim"] = {
    loaded = true,
    path = "/Users/roalcantara/.local/share/nvim/site/pack/packer/start/editorconfig-vim",
    url = "https://github.com/editorconfig/editorconfig-vim"
  },
  ["fidget.nvim"] = {
    config = { "\27LJ\2\nF\0\0\4\0\4\0\t6\0\0\0006\2\1\0'\3\2\0B\0\3\3\15\0\0\0X\2\2€9\2\3\1D\2\1\0K\0\1\0\nsetup\vfidget\frequire\npcall\0" },
    loaded = true,
    path = "/Users/roalcantara/.local/share/nvim/site/pack/packer/start/fidget.nvim",
    url = "https://github.com/j-hui/fidget.nvim"
  },
  ["filetype.nvim"] = {
    loaded = true,
    path = "/Users/roalcantara/.local/share/nvim/site/pack/packer/start/filetype.nvim",
    url = "https://github.com/nathom/filetype.nvim"
  },
  ["fzf-lua"] = {
    config = { "\27LJ\2\n0\0\0\3\0\2\0\0036\0\0\0'\2\1\0D\0\2\0\25neo/plugins/plug-fzf\frequire\0" },
    loaded = true,
    path = "/Users/roalcantara/.local/share/nvim/site/pack/packer/start/fzf-lua",
    url = "https://github.com/ibhagwan/fzf-lua"
  },
  ["gitsigns.nvim"] = {
    config = { "\27LJ\2\n5\0\0\3\0\2\0\0036\0\0\0'\2\1\0D\0\2\0\30neo/plugins/plug-gitsigns\frequire\0" },
    loaded = true,
    path = "/Users/roalcantara/.local/share/nvim/site/pack/packer/start/gitsigns.nvim",
    url = "https://github.com/lewis6991/gitsigns.nvim"
  },
  ["go.nvim"] = {
    loaded = true,
    path = "/Users/roalcantara/.local/share/nvim/site/pack/packer/start/go.nvim",
    url = "https://github.com/ray-x/go.nvim"
  },
  ["guihua.lua"] = {
    config = { "\27LJ\2\n3\0\0\3\0\2\0\0036\0\0\0'\2\1\0D\0\2\0\28neo/plugins/plug-guihua\frequire\0" },
    loaded = true,
    path = "/Users/roalcantara/.local/share/nvim/site/pack/packer/start/guihua.lua",
    url = "https://github.com/ray-x/guihua.lua"
  },
  ["indent-blankline.nvim"] = {
    config = { "\27LJ\2\n=\0\0\3\0\2\0\0036\0\0\0'\2\1\0D\0\2\0&neo/plugins/plug-indent-blankline\frequire\0" },
    loaded = true,
    path = "/Users/roalcantara/.local/share/nvim/site/pack/packer/start/indent-blankline.nvim",
    url = "https://github.com/lukas-reineke/indent-blankline.nvim"
  },
  ["kotlin-vim"] = {
    loaded = false,
    needs_bufread = true,
    only_cond = false,
    path = "/Users/roalcantara/.local/share/nvim/site/pack/packer/opt/kotlin-vim",
    url = "https://github.com/udalov/kotlin-vim"
  },
  ["legendary.nvim"] = {
    config = { "\27LJ\2\n6\0\0\3\0\2\0\0036\0\0\0'\2\1\0D\0\2\0\31neo/plugins/plug-legendary\frequire\0" },
    loaded = true,
    path = "/Users/roalcantara/.local/share/nvim/site/pack/packer/start/legendary.nvim",
    url = "https://github.com/mrjones2014/legendary.nvim"
  },
  ["lsp-colors.nvim"] = {
    loaded = true,
    path = "/Users/roalcantara/.local/share/nvim/site/pack/packer/start/lsp-colors.nvim",
    url = "https://github.com/folke/lsp-colors.nvim"
  },
  ["lsp_signature.nvim"] = {
    loaded = true,
    path = "/Users/roalcantara/.local/share/nvim/site/pack/packer/start/lsp_signature.nvim",
    url = "https://github.com/ray-x/lsp_signature.nvim"
  },
  ["lspkind-nvim"] = {
    config = { "\27LJ\2\n4\0\0\3\0\2\0\0036\0\0\0'\2\1\0D\0\2\0\29neo/plugins/plug-lspkind\frequire\0" },
    loaded = true,
    path = "/Users/roalcantara/.local/share/nvim/site/pack/packer/start/lspkind-nvim",
    url = "https://github.com/onsails/lspkind-nvim"
  },
  ["lualine-lsp-progress"] = {
    loaded = true,
    path = "/Users/roalcantara/.local/share/nvim/site/pack/packer/start/lualine-lsp-progress",
    url = "https://github.com/arkav/lualine-lsp-progress"
  },
  ["lualine.nvim"] = {
    config = { "\27LJ\2\n4\0\0\3\0\2\0\0036\0\0\0'\2\1\0D\0\2\0\29neo/plugins/plug-lualine\frequire\0" },
    loaded = true,
    path = "/Users/roalcantara/.local/share/nvim/site/pack/packer/start/lualine.nvim",
    url = "https://github.com/nvim-lualine/lualine.nvim"
  },
  ["manillua.nvim"] = {
    loaded = true,
    path = "/Users/roalcantara/.local/share/nvim/site/pack/packer/start/manillua.nvim",
    url = "https://github.com/tjdevries/manillua.nvim"
  },
  ["mason-lspconfig.nvim"] = {
    config = { "\27LJ\2\n<\0\0\3\0\2\0\0036\0\0\0'\2\1\0D\0\2\0%neo/plugins/plug-mason-lspconfig\frequire\0" },
    loaded = true,
    path = "/Users/roalcantara/.local/share/nvim/site/pack/packer/start/mason-lspconfig.nvim",
    url = "https://github.com/williamboman/mason-lspconfig.nvim"
  },
  ["mason.nvim"] = {
    config = { "\27LJ\2\n2\0\0\3\0\2\0\0036\0\0\0'\2\1\0D\0\2\0\27neo/plugins/plug-mason\frequire\0" },
    loaded = true,
    path = "/Users/roalcantara/.local/share/nvim/site/pack/packer/start/mason.nvim",
    url = "https://github.com/williamboman/mason.nvim"
  },
  ["moonscript-vim"] = {
    loaded = true,
    path = "/Users/roalcantara/.local/share/nvim/site/pack/packer/start/moonscript-vim",
    url = "https://github.com/leafo/moonscript-vim"
  },
  ["neodev.nvim"] = {
    loaded = true,
    path = "/Users/roalcantara/.local/share/nvim/site/pack/packer/start/neodev.nvim",
    url = "https://github.com/folke/neodev.nvim"
  },
  ["nui.nvim"] = {
    loaded = true,
    path = "/Users/roalcantara/.local/share/nvim/site/pack/packer/start/nui.nvim",
    url = "https://github.com/MunifTanjim/nui.nvim"
  },
  ["nvim-autopairs"] = {
    config = { "\27LJ\2\n6\0\0\3\0\2\0\0036\0\0\0'\2\1\0D\0\2\0\31neo/plugins/plug-autopairs\frequire\0" },
    load_after = {},
    loaded = true,
    needs_bufread = false,
    path = "/Users/roalcantara/.local/share/nvim/site/pack/packer/opt/nvim-autopairs",
    url = "https://github.com/windwp/nvim-autopairs"
  },
  ["nvim-bufferline.lua"] = {
    config = { "\27LJ\2\n7\0\0\3\0\2\0\0036\0\0\0'\2\1\0D\0\2\0 neo/plugins/plug-bufferline\frequire\0" },
    loaded = true,
    path = "/Users/roalcantara/.local/share/nvim/site/pack/packer/start/nvim-bufferline.lua",
    url = "https://github.com/akinsho/nvim-bufferline.lua"
  },
  ["nvim-cmp"] = {
    after = { "nvim-autopairs" },
    config = { "\27LJ\2\n0\0\0\3\0\2\0\0036\0\0\0'\2\1\0D\0\2\0\25neo/plugins/plug-cmp\frequire\0" },
    loaded = true,
    only_config = true,
    path = "/Users/roalcantara/.local/share/nvim/site/pack/packer/start/nvim-cmp",
    url = "https://github.com/hrsh7th/nvim-cmp"
  },
  ["nvim-colorizer.lua"] = {
    loaded = true,
    path = "/Users/roalcantara/.local/share/nvim/site/pack/packer/start/nvim-colorizer.lua",
    url = "https://github.com/norcalli/nvim-colorizer.lua"
  },
  ["nvim-fzf"] = {
    loaded = true,
    path = "/Users/roalcantara/.local/share/nvim/site/pack/packer/start/nvim-fzf",
    url = "https://github.com/vijaymarupudi/nvim-fzf"
  },
  ["nvim-lsp-ts-utils"] = {
    loaded = true,
    path = "/Users/roalcantara/.local/share/nvim/site/pack/packer/start/nvim-lsp-ts-utils",
    url = "https://github.com/jose-elias-alvarez/nvim-lsp-ts-utils"
  },
  ["nvim-lspconfig"] = {
    config = { "\27LJ\2\n6\0\0\3\0\2\0\0036\0\0\0'\2\1\0D\0\2\0\31neo/plugins/plug-lspconfig\frequire\0" },
    loaded = true,
    path = "/Users/roalcantara/.local/share/nvim/site/pack/packer/start/nvim-lspconfig",
    url = "https://github.com/neovim/nvim-lspconfig"
  },
  ["nvim-notify"] = {
    config = { "\27LJ\2\n3\0\0\3\0\2\0\0036\0\0\0'\2\1\0D\0\2\0\28neo/plugins/plug-notify\frequire\0" },
    loaded = true,
    path = "/Users/roalcantara/.local/share/nvim/site/pack/packer/start/nvim-notify",
    url = "https://github.com/rcarriga/nvim-notify"
  },
  ["nvim-tree.lua"] = {
    config = { "\27LJ\2\n1\0\0\3\0\2\0\0036\0\0\0'\2\1\0D\0\2\0\26neo/plugins/plug-tree\frequire\0" },
    loaded = true,
    path = "/Users/roalcantara/.local/share/nvim/site/pack/packer/start/nvim-tree.lua",
    url = "https://github.com/kyazdani42/nvim-tree.lua"
  },
  ["nvim-treesitter"] = {
    config = { "\27LJ\2\n7\0\0\3\0\2\0\0036\0\0\0'\2\1\0D\0\2\0 neo/plugins/plug-treesitter\frequire\0" },
    loaded = true,
    path = "/Users/roalcantara/.local/share/nvim/site/pack/packer/start/nvim-treesitter",
    url = "https://github.com/nvim-treesitter/nvim-treesitter"
  },
  ["nvim-treesitter-textobjects"] = {
    loaded = true,
    path = "/Users/roalcantara/.local/share/nvim/site/pack/packer/start/nvim-treesitter-textobjects",
    url = "https://github.com/nvim-treesitter/nvim-treesitter-textobjects"
  },
  ["nvim-ts-autotag"] = {
    loaded = true,
    path = "/Users/roalcantara/.local/share/nvim/site/pack/packer/start/nvim-ts-autotag",
    url = "https://github.com/windwp/nvim-ts-autotag"
  },
  ["nvim-web-devicons"] = {
    config = { "\27LJ\2\n>\0\0\3\0\2\0\0036\0\0\0'\2\1\0D\0\2\0'neo/plugins/plug-nvim-web-devicons\frequire\0" },
    loaded = true,
    path = "/Users/roalcantara/.local/share/nvim/site/pack/packer/start/nvim-web-devicons",
    url = "https://github.com/nvim-tree/nvim-web-devicons"
  },
  ["packer.nvim"] = {
    loaded = true,
    path = "/Users/roalcantara/.local/share/nvim/site/pack/packer/start/packer.nvim",
    url = "https://github.com/wbthomason/packer.nvim"
  },
  ["plenary.nvim"] = {
    loaded = true,
    path = "/Users/roalcantara/.local/share/nvim/site/pack/packer/start/plenary.nvim",
    url = "https://github.com/nvim-lua/plenary.nvim"
  },
  ["popup.nvim"] = {
    loaded = true,
    path = "/Users/roalcantara/.local/share/nvim/site/pack/packer/start/popup.nvim",
    url = "https://github.com/nvim-lua/popup.nvim"
  },
  ["schemastore.nvim"] = {
    loaded = true,
    path = "/Users/roalcantara/.local/share/nvim/site/pack/packer/start/schemastore.nvim",
    url = "https://github.com/b0o/schemastore.nvim"
  },
  ["tokyonight.nvim"] = {
    config = { "\27LJ\2\n7\0\0\3\0\2\0\0036\0\0\0'\2\1\0D\0\2\0 neo/plugins/plug-tokyonight\frequire\0" },
    loaded = true,
    path = "/Users/roalcantara/.local/share/nvim/site/pack/packer/start/tokyonight.nvim",
    url = "https://github.com/folke/tokyonight.nvim"
  },
  ["trim.nvim"] = {
    config = { "\27LJ\2\n1\0\0\3\0\2\0\0036\0\0\0'\2\1\0D\0\2\0\26neo/plugins/plug-trim\frequire\0" },
    loaded = true,
    path = "/Users/roalcantara/.local/share/nvim/site/pack/packer/start/trim.nvim",
    url = "https://github.com/cappyzawa/trim.nvim"
  },
  ["trouble.nvim"] = {
    config = { "\27LJ\2\n4\0\0\3\0\2\0\0036\0\0\0'\2\1\0D\0\2\0\29neo/plugins/plug-trouble\frequire\0" },
    loaded = true,
    path = "/Users/roalcantara/.local/share/nvim/site/pack/packer/start/trouble.nvim",
    url = "https://github.com/folke/trouble.nvim"
  },
  ["vim-git"] = {
    loaded = true,
    path = "/Users/roalcantara/.local/share/nvim/site/pack/packer/start/vim-git",
    url = "https://github.com/tpope/vim-git"
  },
  ["vim-illuminate"] = {
    loaded = true,
    path = "/Users/roalcantara/.local/share/nvim/site/pack/packer/start/vim-illuminate",
    url = "https://github.com/RRethy/vim-illuminate"
  },
  ["vim-kitty"] = {
    loaded = true,
    path = "/Users/roalcantara/.local/share/nvim/site/pack/packer/start/vim-kitty",
    url = "https://github.com/fladson/vim-kitty"
  },
  ["vim-nix"] = {
    loaded = true,
    path = "/Users/roalcantara/.local/share/nvim/site/pack/packer/start/vim-nix",
    url = "https://github.com/lnl7/vim-nix"
  },
  ["vim-visual-multi"] = {
    config = { "\27LJ\2\n9\0\0\3\0\2\0\0036\0\0\0'\2\1\0D\0\2\0\"neo/plugins/plug-visual-multi\frequire\0" },
    loaded = true,
    path = "/Users/roalcantara/.local/share/nvim/site/pack/packer/start/vim-visual-multi",
    url = "https://github.com/mg979/vim-visual-multi"
  },
  ["vim-vsnip"] = {
    config = { "\27LJ\2\n2\0\0\3\0\2\0\0036\0\0\0'\2\1\0D\0\2\0\27neo/plugins/plug-vsnip\frequire\0" },
    loaded = true,
    path = "/Users/roalcantara/.local/share/nvim/site/pack/packer/start/vim-vsnip",
    url = "https://github.com/hrsh7th/vim-vsnip"
  },
  ["vim-wakatime"] = {
    loaded = true,
    path = "/Users/roalcantara/.local/share/nvim/site/pack/packer/start/vim-wakatime",
    url = "https://github.com/wakatime/vim-wakatime"
  },
  ["which-key.nvim"] = {
    config = { "\27LJ\2\n6\0\0\3\0\2\0\0036\0\0\0'\2\1\0D\0\2\0\31neo/plugins/plug-which-key\frequire\0" },
    loaded = true,
    path = "/Users/roalcantara/.local/share/nvim/site/pack/packer/start/which-key.nvim",
    url = "https://github.com/folke/which-key.nvim"
  }
}

time([[Defining packer_plugins]], false)
-- Config for: fzf-lua
time([[Config for fzf-lua]], true)
try_loadstring("\27LJ\2\n0\0\0\3\0\2\0\0036\0\0\0'\2\1\0D\0\2\0\25neo/plugins/plug-fzf\frequire\0", "config", "fzf-lua")
time([[Config for fzf-lua]], false)
-- Config for: legendary.nvim
time([[Config for legendary.nvim]], true)
try_loadstring("\27LJ\2\n6\0\0\3\0\2\0\0036\0\0\0'\2\1\0D\0\2\0\31neo/plugins/plug-legendary\frequire\0", "config", "legendary.nvim")
time([[Config for legendary.nvim]], false)
-- Config for: tokyonight.nvim
time([[Config for tokyonight.nvim]], true)
try_loadstring("\27LJ\2\n7\0\0\3\0\2\0\0036\0\0\0'\2\1\0D\0\2\0 neo/plugins/plug-tokyonight\frequire\0", "config", "tokyonight.nvim")
time([[Config for tokyonight.nvim]], false)
-- Config for: gitsigns.nvim
time([[Config for gitsigns.nvim]], true)
try_loadstring("\27LJ\2\n5\0\0\3\0\2\0\0036\0\0\0'\2\1\0D\0\2\0\30neo/plugins/plug-gitsigns\frequire\0", "config", "gitsigns.nvim")
time([[Config for gitsigns.nvim]], false)
-- Config for: which-key.nvim
time([[Config for which-key.nvim]], true)
try_loadstring("\27LJ\2\n6\0\0\3\0\2\0\0036\0\0\0'\2\1\0D\0\2\0\31neo/plugins/plug-which-key\frequire\0", "config", "which-key.nvim")
time([[Config for which-key.nvim]], false)
-- Config for: trim.nvim
time([[Config for trim.nvim]], true)
try_loadstring("\27LJ\2\n1\0\0\3\0\2\0\0036\0\0\0'\2\1\0D\0\2\0\26neo/plugins/plug-trim\frequire\0", "config", "trim.nvim")
time([[Config for trim.nvim]], false)
-- Config for: nvim-tree.lua
time([[Config for nvim-tree.lua]], true)
try_loadstring("\27LJ\2\n1\0\0\3\0\2\0\0036\0\0\0'\2\1\0D\0\2\0\26neo/plugins/plug-tree\frequire\0", "config", "nvim-tree.lua")
time([[Config for nvim-tree.lua]], false)
-- Config for: cmp-dictionary
time([[Config for cmp-dictionary]], true)
try_loadstring("\27LJ\2\n;\0\0\3\0\2\0\0036\0\0\0'\2\1\0D\0\2\0$neo/plugins/plug-cmp-dictionary\frequire\0", "config", "cmp-dictionary")
time([[Config for cmp-dictionary]], false)
-- Config for: lspkind-nvim
time([[Config for lspkind-nvim]], true)
try_loadstring("\27LJ\2\n4\0\0\3\0\2\0\0036\0\0\0'\2\1\0D\0\2\0\29neo/plugins/plug-lspkind\frequire\0", "config", "lspkind-nvim")
time([[Config for lspkind-nvim]], false)
-- Config for: nvim-treesitter
time([[Config for nvim-treesitter]], true)
try_loadstring("\27LJ\2\n7\0\0\3\0\2\0\0036\0\0\0'\2\1\0D\0\2\0 neo/plugins/plug-treesitter\frequire\0", "config", "nvim-treesitter")
time([[Config for nvim-treesitter]], false)
-- Config for: nvim-bufferline.lua
time([[Config for nvim-bufferline.lua]], true)
try_loadstring("\27LJ\2\n7\0\0\3\0\2\0\0036\0\0\0'\2\1\0D\0\2\0 neo/plugins/plug-bufferline\frequire\0", "config", "nvim-bufferline.lua")
time([[Config for nvim-bufferline.lua]], false)
-- Config for: cmp-git
time([[Config for cmp-git]], true)
try_loadstring("\27LJ\2\n4\0\0\3\0\2\0\0036\0\0\0'\2\1\0D\0\2\0\29neo/plugins/plug-cmp-git\frequire\0", "config", "cmp-git")
time([[Config for cmp-git]], false)
-- Config for: trouble.nvim
time([[Config for trouble.nvim]], true)
try_loadstring("\27LJ\2\n4\0\0\3\0\2\0\0036\0\0\0'\2\1\0D\0\2\0\29neo/plugins/plug-trouble\frequire\0", "config", "trouble.nvim")
time([[Config for trouble.nvim]], false)
-- Config for: lualine.nvim
time([[Config for lualine.nvim]], true)
try_loadstring("\27LJ\2\n4\0\0\3\0\2\0\0036\0\0\0'\2\1\0D\0\2\0\29neo/plugins/plug-lualine\frequire\0", "config", "lualine.nvim")
time([[Config for lualine.nvim]], false)
-- Config for: fidget.nvim
time([[Config for fidget.nvim]], true)
try_loadstring("\27LJ\2\nF\0\0\4\0\4\0\t6\0\0\0006\2\1\0'\3\2\0B\0\3\3\15\0\0\0X\2\2€9\2\3\1D\2\1\0K\0\1\0\nsetup\vfidget\frequire\npcall\0", "config", "fidget.nvim")
time([[Config for fidget.nvim]], false)
-- Config for: nvim-web-devicons
time([[Config for nvim-web-devicons]], true)
try_loadstring("\27LJ\2\n>\0\0\3\0\2\0\0036\0\0\0'\2\1\0D\0\2\0'neo/plugins/plug-nvim-web-devicons\frequire\0", "config", "nvim-web-devicons")
time([[Config for nvim-web-devicons]], false)
-- Config for: dressing.nvim
time([[Config for dressing.nvim]], true)
try_loadstring("\27LJ\2\n5\0\0\3\0\2\0\0036\0\0\0'\2\1\0D\0\2\0\30neo/plugins/plug-dressing\frequire\0", "config", "dressing.nvim")
time([[Config for dressing.nvim]], false)
-- Config for: guihua.lua
time([[Config for guihua.lua]], true)
try_loadstring("\27LJ\2\n3\0\0\3\0\2\0\0036\0\0\0'\2\1\0D\0\2\0\28neo/plugins/plug-guihua\frequire\0", "config", "guihua.lua")
time([[Config for guihua.lua]], false)
-- Config for: nvim-notify
time([[Config for nvim-notify]], true)
try_loadstring("\27LJ\2\n3\0\0\3\0\2\0\0036\0\0\0'\2\1\0D\0\2\0\28neo/plugins/plug-notify\frequire\0", "config", "nvim-notify")
time([[Config for nvim-notify]], false)
-- Config for: nvim-lspconfig
time([[Config for nvim-lspconfig]], true)
try_loadstring("\27LJ\2\n6\0\0\3\0\2\0\0036\0\0\0'\2\1\0D\0\2\0\31neo/plugins/plug-lspconfig\frequire\0", "config", "nvim-lspconfig")
time([[Config for nvim-lspconfig]], false)
-- Config for: mason-lspconfig.nvim
time([[Config for mason-lspconfig.nvim]], true)
try_loadstring("\27LJ\2\n<\0\0\3\0\2\0\0036\0\0\0'\2\1\0D\0\2\0%neo/plugins/plug-mason-lspconfig\frequire\0", "config", "mason-lspconfig.nvim")
time([[Config for mason-lspconfig.nvim]], false)
-- Config for: indent-blankline.nvim
time([[Config for indent-blankline.nvim]], true)
try_loadstring("\27LJ\2\n=\0\0\3\0\2\0\0036\0\0\0'\2\1\0D\0\2\0&neo/plugins/plug-indent-blankline\frequire\0", "config", "indent-blankline.nvim")
time([[Config for indent-blankline.nvim]], false)
-- Config for: vim-visual-multi
time([[Config for vim-visual-multi]], true)
try_loadstring("\27LJ\2\n9\0\0\3\0\2\0\0036\0\0\0'\2\1\0D\0\2\0\"neo/plugins/plug-visual-multi\frequire\0", "config", "vim-visual-multi")
time([[Config for vim-visual-multi]], false)
-- Config for: Comment.nvim
time([[Config for Comment.nvim]], true)
try_loadstring("\27LJ\2\n4\0\0\3\0\2\0\0036\0\0\0'\2\1\0D\0\2\0\29neo/plugins/plug-comment\frequire\0", "config", "Comment.nvim")
time([[Config for Comment.nvim]], false)
-- Config for: mason.nvim
time([[Config for mason.nvim]], true)
try_loadstring("\27LJ\2\n2\0\0\3\0\2\0\0036\0\0\0'\2\1\0D\0\2\0\27neo/plugins/plug-mason\frequire\0", "config", "mason.nvim")
time([[Config for mason.nvim]], false)
-- Config for: nvim-cmp
time([[Config for nvim-cmp]], true)
try_loadstring("\27LJ\2\n0\0\0\3\0\2\0\0036\0\0\0'\2\1\0D\0\2\0\25neo/plugins/plug-cmp\frequire\0", "config", "nvim-cmp")
time([[Config for nvim-cmp]], false)
-- Config for: vim-vsnip
time([[Config for vim-vsnip]], true)
try_loadstring("\27LJ\2\n2\0\0\3\0\2\0\0036\0\0\0'\2\1\0D\0\2\0\27neo/plugins/plug-vsnip\frequire\0", "config", "vim-vsnip")
time([[Config for vim-vsnip]], false)
-- Load plugins in order defined by `after`
time([[Sequenced loading]], true)
vim.cmd [[ packadd nvim-autopairs ]]

-- Config for: nvim-autopairs
try_loadstring("\27LJ\2\n6\0\0\3\0\2\0\0036\0\0\0'\2\1\0D\0\2\0\31neo/plugins/plug-autopairs\frequire\0", "config", "nvim-autopairs")

time([[Sequenced loading]], false)
vim.cmd [[augroup packer_load_aucmds]]
vim.cmd [[au!]]
  -- Filetype lazy-loads
time([[Defining lazy-load filetype autocommands]], true)
vim.cmd [[au FileType kt ++once lua require("packer.load")({'kotlin-vim'}, { ft = "kt" }, _G.packer_plugins)]]
time([[Defining lazy-load filetype autocommands]], false)
  -- Event lazy-loads
time([[Defining lazy-load event autocommands]], true)
vim.cmd [[au VimEnter * ++once lua require("packer.load")({'dashboard-nvim'}, { event = "VimEnter *" }, _G.packer_plugins)]]
time([[Defining lazy-load event autocommands]], false)
vim.cmd("augroup END")
vim.cmd [[augroup filetypedetect]]
time([[Sourcing ftdetect script at: /Users/roalcantara/.local/share/nvim/site/pack/packer/opt/kotlin-vim/ftdetect/kotlin.vim]], true)
vim.cmd [[source /Users/roalcantara/.local/share/nvim/site/pack/packer/opt/kotlin-vim/ftdetect/kotlin.vim]]
time([[Sourcing ftdetect script at: /Users/roalcantara/.local/share/nvim/site/pack/packer/opt/kotlin-vim/ftdetect/kotlin.vim]], false)
vim.cmd("augroup END")

_G._packer.inside_compile = false
if _G._packer.needs_bufread == true then
  vim.cmd("doautocmd BufRead")
end
_G._packer.needs_bufread = false

if should_profile then save_profiles(1) end

end)

if not no_errors then
  error_msg = error_msg:gsub('"', '\\"')
  vim.api.nvim_command('echohl ErrorMsg | echom "Error in packer_compiled: '..error_msg..'" | echom "Please check your config for correctness" | echohl None')
end
