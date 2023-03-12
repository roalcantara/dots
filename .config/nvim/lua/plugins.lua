-- A modern plugin manager for Neovim
-- https://github.com/folke/lazy.nvim
require('lazy').setup({
  'nvim-lua/plenary.nvim',
  'nvim-lua/popup.nvim',
  'nathom/filetype.nvim',
  'MunifTanjim/nui.nvim',
  {
    'folke/tokyonight.nvim',
    lazy = false, -- make sure we load this during startup if it is your main colorscheme
    priority = 1000, -- make sure to load this before all the other start plugins
    opts = {
      transparent = true,
      terminal_colors = true,
      styles = {
        comments = {
          italic = true,
        },
        keywords = {
          italic = true,
        },
        functions = {},
        variables = {},
        sidebars = 'dark',
        floats = 'dark',
      },
      sidebars = {
        'qf',
        'vista_kind',
        'terminal',
        'packer',
      },
      hide_inactive_statusline = false,
      dim_inactive = true,
      lualine_bold = true,
    },
    config = true,
    init = function()
      -- load the colorscheme here
      vim.cmd([[colorscheme tokyonight]])
    end,
  },
  {
    'nvim-tree/nvim-web-devicons',
    opts = {
      color_icons = true,
      default = true,
      override = {
        lock = {
          icon = '',
          color = '#DE6B74',
          name = 'lock',
        },
        zip = {
          icon = '',
          color = '#EBCB8B',
          name = 'zip',
        },
        xz = {
          icon = '',
          color = '#EBCB8B',
          name = 'xz',
        },
        deb = {
          icon = '',
          color = '#a3b8ef',
          name = 'deb',
        },
        rpm = {
          icon = '',
          color = '#fca2aa',
          name = 'rpm',
        },
        moon = {
          icon = '',
          color = '#FFB13B',
          name = 'moon',
        },
        jquery = {
          icon = '',
          color = '#1B75BB',
          name = 'JQuery',
        },
        angular = {
          icon = '',
          color = '#E23237',
          name = 'Angular',
        },
        backbone = {
          icon = '',
          color = '#0071B5',
          name = 'Backbone',
        },
        requirejs = {
          icon = '',
          color = '#F44A41',
          name = 'Requirejs',
        },
        materialize = {
          icon = '',
          color = '#EE6E73',
          name = 'Materialize',
        },
        mootools = {
          icon = '',
          color = '#ECECEC',
          name = 'MooTools',
        },
        puppet = {
          icon = '',
          color = '#cbcb41',
          name = 'Pupet',
        },
        gruntfile = {
          icon = '',
          color = '#e37933',
          name = 'Gruntfile',
        },
        gulpfile = {
          icon = '',
          color = '#cc3e44',
          name = 'Gulpfile',
        },
        dropbox = {
          icon = '',
          color = '#0061FE',
          name = 'Dropbox',
        },
        xls = {
          icon = '',
          color = '#207245',
          name = 'Xls',
        },
        doc = {
          icon = '',
          color = '#185abd',
          name = 'Doc',
        },
        ppt = {
          icon = '',
          color = '#cb4a32',
          name = 'Ppt',
        },
        xml = {
          icon = '謹',
          color = '#e37933',
          name = 'Xml',
        },
        webpack = {
          icon = 'ﰩ',
          color = '#519aba',
          name = 'Webpack',
        },
        cs = {
          icon = '',
          color = '#596706',
          name = 'Cs',
        },
        procfile = {
          icon = '',
          color = '#a074c4',
          name = 'Procfile',
        },
        svg = {
          icon = 'ﰟ',
          color = '#FFB13B',
          name = 'Svg',
        },
        git = {
          icon = '',
          color = '#e37933',
          name = 'GitLogo',
        },
        COMMIT_EDITMSG = {
          icon = '',
          color = '#41535b',
          name = 'GitCommit',
        },
        COPYING = {
          icon = '',
          color = '#cbcb41',
          name = 'License',
        },
        Dockerfile = {
          icon = '',
          color = '#185abd',
          name = 'Dockerfile',
        },
        LICENSE = {
          icon = '',
          color = '#d0bf41',
          name = 'License',
        },
        _gvimrc = {
          icon = '',
          color = '#019833',
          name = 'Gvimrc',
        },
        _vimrc = {
          icon = '',
          color = '#019833',
          name = 'Vimrc',
        },
        ai = {
          icon = '',
          color = '#cbcb41',
          name = 'Ai',
        },
        awk = {
          icon = '',
          color = '#4d5a5e',
          name = 'Awk',
        },
        bash = {
          icon = '',
          color = '#89e051',
          name = 'Bash',
        },
        bat = {
          icon = '',
          color = '#C1F12E',
          name = 'Bat',
        },
        bmp = {
          icon = '',
          color = '#a074c4',
          name = 'Bmp',
        },
        c = {
          icon = '',
          color = '#599eff',
          name = 'C',
        },
        cc = {
          icon = '',
          color = '#f34b7d',
          name = 'CPlusPlus',
        },
        clj = {
          icon = '',
          color = '#8dc149',
          name = 'Clojure',
        },
        cljc = {
          icon = '',
          color = '#8dc149',
          name = 'ClojureC',
        },
        cljs = {
          icon = '',
          color = '#519aba',
          name = 'ClojureJS',
        },
        cmake = {
          icon = '',
          color = '#6d8086',
          name = 'CMake',
        },
        coffee = {
          icon = '',
          color = '#cbcb41',
          name = 'Coffee',
        },
        conf = {
          icon = '',
          color = '#6d8086',
          name = 'Conf',
        },
        cp = {
          icon = '',
          color = '#519aba',
          name = 'Cp',
        },
        cpp = {
          icon = '',
          color = '#519aba',
          name = 'Cpp',
        },
        csh = {
          icon = '',
          color = '#4d5a5e',
          name = 'Csh',
        },
        cson = {
          icon = '',
          color = '#cbcb41',
          name = 'Cson',
        },
        css = {
          icon = '',
          color = '#563d7c',
          name = 'Css',
        },
        cxx = {
          icon = '',
          color = '#519aba',
          name = 'Cxx',
        },
        d = {
          icon = '',
          color = '#427819',
          name = 'D',
        },
        dart = {
          icon = '',
          color = '#03589C',
          name = 'Dart',
        },
        db = {
          icon = '',
          color = '#dad8d8',
          name = 'Db',
        },
        diff = {
          icon = '',
          color = '#41535b',
          name = 'Diff',
        },
        dockerfile = {
          icon = '',
          color = '#384d54',
          name = 'Dockerfile',
        },
        dump = {
          icon = '',
          color = '#dad8d8',
          name = 'Dump',
        },
        edn = {
          icon = '',
          color = '#519aba',
          name = 'Edn',
        },
        eex = {
          icon = '',
          color = '#a074c4',
          name = 'Eex',
        },
        ejs = {
          icon = '',
          color = '#cbcb41',
          name = 'Ejs',
        },
        elm = {
          icon = '',
          color = '#519aba',
          name = 'Elm',
        },
        erl = {
          icon = '',
          color = '#B83998',
          name = 'Erl',
        },
        ex = {
          icon = '',
          color = '#a074c4',
          name = 'Ex',
        },
        exs = {
          icon = '',
          color = '#a074c4',
          name = 'Exs',
        },
        fish = {
          icon = '',
          color = '#4d5a5e',
          name = 'Fish',
        },
        fs = {
          icon = '',
          color = '#519aba',
          name = 'Fs',
        },
        fsi = {
          icon = '',
          color = '#519aba',
          name = 'Fsi',
        },
        fsscript = {
          icon = '',
          color = '#519aba',
          name = 'Fsscript',
        },
        fsx = {
          icon = '',
          color = '#519aba',
          name = 'Fsx',
        },
        gemspec = {
          icon = '',
          color = '#701516',
          name = 'Gemspec',
        },
        gif = {
          icon = '',
          color = '#a074c4',
          name = 'Gif',
        },
        go = {
          icon = '',
          color = '#519aba',
          name = 'Go',
        },
        h = {
          icon = '',
          color = '#a074c4',
          name = 'H',
        },
        haml = {
          icon = '',
          color = '#eaeae1',
          name = 'Haml',
        },
        hbs = {
          icon = '',
          color = '#f0772b',
          name = 'Hbs',
        },
        hh = {
          icon = '',
          color = '#a074c4',
          name = 'Hh',
        },
        hpp = {
          icon = '',
          color = '#a074c4',
          name = 'Hpp',
        },
        hrl = {
          icon = '',
          color = '#B83998',
          name = 'Hrl',
        },
        hs = {
          icon = '',
          color = '#a074c4',
          name = 'Hs',
        },
        erb = {
          icon = '',
          color = '#701516',
          name = 'Erb',
        },
        hxx = {
          icon = '',
          color = '#a074c4',
          name = 'Hxx',
        },
        ico = {
          icon = '',
          color = '#cbcb41',
          name = 'Ico',
        },
        ini = {
          icon = '',
          color = '#6d8086',
          name = 'Ini',
        },
        java = {
          icon = '',
          color = '#cc3e44',
          name = 'Java',
        },
        jl = {
          icon = '',
          color = '#a270ba',
          name = 'Jl',
        },
        jpeg = {
          icon = '',
          color = '#a074c4',
          name = 'Jpeg',
        },
        jpg = {
          icon = '',
          color = '#a074c4',
          name = 'Jpg',
        },
        json = {
          icon = '',
          color = '#89e051',
          name = 'Json',
        },
        ksh = {
          icon = '',
          color = '#4d5a5e',
          name = 'Ksh',
        },
        leex = {
          icon = '',
          color = '#a074c4',
          name = 'Leex',
        },
        less = {
          icon = '',
          color = '#563d7c',
          name = 'Less',
        },
        lhs = {
          icon = '',
          color = '#a074c4',
          name = 'Lhs',
        },
        license = {
          icon = '',
          color = '#cbcb41',
          name = 'License',
        },
        lua = {
          icon = '',
          color = '#51a0cf',
          name = 'Lua',
        },
        makefile = {
          icon = '',
          color = '#6d8086',
          name = 'makefile',
        },
        Makefile = {
          icon = '',
          color = '#6d8086',
          name = 'Makefile',
        },
        markdown = {
          icon = '',
          color = '#519aba',
          name = 'Markdown',
        },
        md = {
          icon = '',
          color = '#519aba',
          name = 'Md',
        },
        mdx = {
          icon = '',
          color = '#519aba',
          name = 'Mdx',
        },
        mjs = {
          icon = '',
          color = '#f1e05a',
          name = 'Mjs',
        },
        ml = {
          icon = 'λ',
          color = '#e37933',
          name = 'Ml',
        },
        mli = {
          icon = 'λ',
          color = '#e37933',
          name = 'Mli',
        },
        mustache = {
          icon = '',
          color = '#e37933',
          name = 'Mustache',
        },
        nix = {
          icon = '',
          color = '#7ebae4',
          name = 'Nix',
        },
        node_modules = {
          icon = '',
          color = '#358a5b',
          name = 'NodeModules',
        },
        php = {
          icon = '',
          color = '#a074c4',
          name = 'Php',
        },
        pl = {
          icon = '',
          color = '#519aba',
          name = 'Pl',
        },
        pm = {
          icon = '',
          color = '#519aba',
          name = 'Pm',
        },
        png = {
          icon = '',
          color = '#a074c4',
          name = 'Png',
        },
        pp = {
          icon = '',
          color = '#302B6D',
          name = 'Pp',
        },
        ps1 = {
          icon = '',
          color = '#4d5a5e',
          name = 'PromptPs1',
        },
        psb = {
          icon = '',
          color = '#519aba',
          name = 'Psb',
        },
        psd = {
          icon = '',
          color = '#519aba',
          name = 'Psd',
        },
        py = {
          icon = '',
          color = '#a074c4',
          name = 'Py',
        },
        pyc = {
          icon = '',
          color = '#519aba',
          name = 'Pyc',
        },
        pyd = {
          icon = '',
          color = '#519aba',
          name = 'Pyd',
        },
        pyo = {
          icon = '',
          color = '#519aba',
          name = 'Pyo',
        },
        r = {
          icon = 'ﳒ',
          color = '#358a5b',
          name = 'R',
        },
        R = {
          icon = 'ﳒ',
          color = '#358a5b',
          name = 'R',
        },
        rake = {
          icon = '',
          color = '#701516',
          name = 'Rake',
        },
        rakefile = {
          icon = '',
          color = '#701516',
          name = 'Rakefile',
        },
        rb = {
          icon = '',
          color = '#701516',
          name = 'Rb',
        },
        rlib = {
          icon = '',
          color = '#dea584',
          name = 'Rlib',
        },
        rmd = {
          icon = '',
          color = '#519aba',
          name = 'Rmd',
        },
        Rmd = {
          icon = '',
          color = '#519aba',
          name = 'Rmd',
        },
        rproj = {
          icon = '鉶',
          color = '#358a5b',
          name = 'Rproj',
        },
        rs = {
          icon = '',
          color = '#dea584',
          name = 'Rs',
        },
        rss = {
          icon = '',
          color = '#FB9D3B',
          name = 'Rss',
        },
        sass = {
          icon = '',
          color = '#f55385',
          name = 'Sass',
        },
        scala = {
          icon = '',
          color = '#cc3e44',
          name = 'Scala',
        },
        scss = {
          icon = '',
          color = '#f55385',
          name = 'Scss',
        },
        sh = {
          icon = '',
          color = '#4d5a5e',
          name = 'Sh',
        },
        sig = {
          icon = 'λ',
          color = '#e37933',
          name = 'Sig',
        },
        slim = {
          icon = '',
          color = '#e34c26',
          name = 'Slim',
        },
        sln = {
          icon = '',
          color = '#854CC7',
          name = 'Sln',
        },
        sml = {
          icon = 'λ',
          color = '#e37933',
          name = 'Sml',
        },
        sql = {
          icon = '',
          color = '#dad8d8',
          name = 'Sql',
        },
        styl = {
          icon = '',
          color = '#8dc149',
          name = 'Styl',
        },
        suo = {
          icon = '',
          color = '#854CC7',
          name = 'Suo',
        },
        swift = {
          icon = '',
          color = '#e37933',
          name = 'Swift',
        },
        t = {
          icon = '',
          color = '#519aba',
          name = 'Tor',
        },
        tex = {
          icon = 'ﭨ',
          color = '#3D6117',
          name = 'Tex',
        },
        toml = {
          icon = '',
          color = '#6d8086',
          name = 'Toml',
        },
        tsx = {
          icon = '',
          color = '#519aba',
          name = 'Tsx',
        },
        twig = {
          icon = '',
          color = '#8dc149',
          name = 'Twig',
        },
        vim = {
          icon = '',
          color = '#019833',
          name = 'Vim',
        },
        vue = {
          icon = '﵂',
          color = '#8dc149',
          name = 'Vue',
        },
        webmanifest = {
          icon = '',
          color = '#f1e05a',
          name = 'Webmanifest',
        },
        webp = {
          icon = '',
          color = '#a074c4',
          name = 'Webp',
        },
        xcplayground = {
          icon = '',
          color = '#e37933',
          name = 'XcPlayground',
        },
        xul = {
          icon = '',
          color = '#e37933',
          name = 'Xul',
        },
        yaml = {
          icon = '',
          color = '#F88A02',
          name = 'Yaml',
        },
        yml = {
          icon = '',
          color = '#F88A02',
          name = 'Yml',
        },
        zsh = {
          icon = '',
          color = '#89e051',
          name = 'Zsh',
        },
        terminal = {
          icon = '',
          color = '#31B53E',
          name = 'Terminal',
        },
        pdf = {
          icon = '',
          color = '#b30b00',
          name = 'Pdf',
        },
        kt = {
          icon = '𝙆',
          color = '#F88A02',
          name = 'Kotlin',
        },
        gd = {
          icon = '',
          color = '#6d8086',
          name = 'GDScript',
        },
        tscn = {
          icon = '',
          color = '#a074c4',
          name = 'TextScene',
        },
        godot = {
          icon = '',
          color = '#6d8086',
          name = 'GodotProject',
        },
        tres = {
          icon = '',
          color = '#cbcb41',
          name = 'TextResource',
        },
        glb = {
          icon = '',
          color = '#FFB13B',
          name = 'BinaryGLTF',
        },
        import = {
          icon = '',
          color = '#ECECEC',
          name = 'ImportConfiguration',
        },
        material = {
          icon = '',
          color = '#B83998',
          name = 'Material',
        },
        otf = {
          icon = '',
          color = '#ECECEC',
          name = 'OpenTypeFont',
        },
        cfg = {
          icon = '',
          color = '#ECECEC',
          name = 'Configuration',
        },
        pck = {
          icon = '',
          color = '#6d8086',
          name = 'PackedResource',
        },
        desktop = {
          icon = '',
          color = '#563d7c',
          name = 'DesktopEntry',
        },
        opus = {
          icon = '',
          color = '#F88A02',
          name = 'OPUS',
        },
        svelte = {
          icon = '',
          color = '#ff3e00',
          name = 'Svelte',
        },
        ['COPYING.LESSER'] = {
          icon = '',
          color = '#cbcb41',
          name = 'License',
        },
        ['f#'] = {
          icon = '',
          color = '#519aba',
          name = 'Fsharp',
        },
        ['favicon.ico'] = {
          icon = '',
          color = '#cbcb41',
          name = 'Favicon',
        },
        ['mix.lock'] = {
          icon = '',
          color = '#a074c4',
          name = 'MixLock',
        },
        ['Gemfile.lock'] = {
          icon = '',
          color = '#701516',
          name = 'Gemfile',
        },
        ['Gemfile'] = {
          icon = '',
          color = '#701516',
          name = 'Gemfile',
        },
        ['Vagrantfile$'] = {
          icon = '',
          color = '#1563FF',
          name = 'Vagrantfile',
        },
        ['c++'] = {
          icon = '',
          color = '#f34b7d',
          name = 'CPlusPlus',
        },
        ['CMakeLists.txt'] = {
          icon = '',
          color = '#6d8086',
          name = 'CMakeLists',
        },
        ['config.ru'] = {
          icon = '',
          color = '#701516',
          name = 'ConfigRu',
        },
        ['.settings.json'] = {
          icon = '',
          color = '#854CC7',
          name = 'SettingsJson',
        },
        ['.bashprofile'] = {
          icon = '',
          color = '#89e051',
          name = 'BashProfile',
        },
        ['.bashrc'] = {
          icon = '',
          color = '#89e051',
          name = 'Bashrc',
        },
        ['.babelrc'] = {
          icon = 'ﬥ',
          color = '#cbcb41',
          name = 'Babelrc',
        },
        ['.DS_Store'] = {
          icon = '',
          color = '#519aba',
          name = 'DsStore',
        },
        ['.gitattributes'] = {
          icon = '',
          color = '#e37933',
          name = 'GitAttributes',
        },
        ['.gitconfig'] = {
          icon = '',
          color = '#e37933',
          name = 'GitConfig',
        },
        ['.gitignore'] = {
          icon = '',
          color = '#FFB13B',
          name = 'GitIgnore',
        },
        ['.gitmodules'] = {
          icon = '',
          color = '#e37933',
          name = 'GitModules',
        },
        ['.gitlab-ci.yml'] = {
          icon = '',
          color = '#e24329',
          name = 'GitlabCI',
        },
        ['.gvimrc'] = {
          icon = '',
          color = '#019833',
          name = 'Gvimrc',
        },
        ['.npmignore'] = {
          icon = '',
          color = '#E8274B',
          name = 'NPMIgnore',
        },
        ['.vimrc'] = {
          icon = '',
          color = '#019833',
          name = 'Vimrc',
        },
        ['.zshrc'] = {
          icon = '',
          color = '#89e051',
          name = 'Zshrc',
        },
        ['.zshenv'] = {
          icon = '',
          color = '#89e051',
          name = 'Zshenv',
        },
        ['.zprofile'] = {
          icon = '',
          color = '#89e051',
          name = 'Zshprofile',
        },
      },
    },
    config = true,
  },
  {
    'nvim-lualine/lualine.nvim',
    opts = {
      options = {
        theme = 'auto',
        icons_enabled = true,
        padding = 1,
        globalstatus = true,
      },
      sections = {
        lualine_x = {
          {
            require('lazy.status').updates,
            cond = require('lazy.status').has_updates,
            color = { fg = '#ff9e64' },
          },
        },
      },
      extensions = {
        'quickfix',
        'fzf',
        'quickfix',
        'symbols-outline',
      },
    },
  },
  {
    'goolord/alpha-nvim',
    config = function()
      require('plugins/alpha')
    end,
  },
  {
    'nvim-treesitter/nvim-treesitter',
    run = function()
      local ts_update = require('nvim-treesitter/install').update({
        with_sync = true,
      })
      return ts_update()
    end,
    dependencies = {
      'windwp/nvim-ts-autotag',
      'nvim-treesitter/nvim-treesitter-textobjects',
      {
        'lukas-reineke/indent-blankline.nvim',
        opts = {
          use_treesitter = true,
          show_end_of_line = true,
          show_current_context = true,
          show_current_context_start = false,
          indent_blankline_show_foldtext = true,
          show_trailing_blankline_indent = false,
          buftype_exclude = {
            'terminal',
            'dashboard',
            'packer',
            'lazy',
            'nofile',
          },
          filetype_exclude = {
            'help',
            'startify',
            'alpha',
            'dashboard',
            'packer',
            'lazy',
            'neogitstatus',
            'NvimTree',
            'Trouble',
          },
        },
        config = true,
      },
    },
    opts = {
      indent = {
        enable = true,
      },
      autotag = {
        enable = true,
      },
      rainbow = {
        enable = true,
      },
      autopairs = {
        enable = true,
      },
      playground = {
        enable = true,
      },
      highlight = {
        enable = true,
        use_languagetree = true,
        additional_vim_regex_highlighting = false,
      },
      refactor = {
        highlight_definitions = {
          enable = true,
        },
        smart_rename = {
          enable = true,
        },
      },
      context_commentstring = {
        enable = true,
      },
      tree_docs = {
        enable = true,
      },
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = '<c-space>',
          node_incremental = '<c-space>',
          scope_incremental = '<c-s>',
          node_decremental = '<c-backspace>',
        },
      },
      textobjects = {
        select = {
          enable = true,
          lookahead = true,
          keymaps = {
            ['aa'] = '@parameter.outer',
            ['ia'] = '@parameter.inner',
            ['af'] = '@function.outer',
            ['if'] = '@function.inner',
            ['ac'] = '@class.outer',
            ['ic'] = '@class.inner',
          },
        },
        move = {
          enable = true,
          set_jumps = true,
          goto_next_start = {
            [']m'] = '@function.outer',
            [']]'] = '@class.outer',
          },
          goto_next_end = {
            [']M'] = '@function.outer',
            [']['] = '@class.outer',
          },
          goto_previous_start = {
            ['[m'] = '@function.outer',
            ['[['] = '@class.outer',
          },
          goto_previous_end = {
            ['[M'] = '@function.outer',
            ['[]'] = '@class.outer',
          },
        },
        swap = {
          enable = true,
          swap_next = {
            ['<leader>a'] = '@parameter.inner',
          },
          swap_previous = {
            ['<leader>A'] = '@parameter.inner',
          },
        },
      },
      ensure_installed = {
        'bash',
        'css',
        'dockerfile',
        'git_rebase',
        'gitattributes',
        'gitcommit',
        'gitignore',
        'go',
        'help',
        'json',
        'jsonc',
        'lua',
        'make',
        'markdown',
        'python',
        'ruby',
        'scss',
        'toml',
        'tsx',
        'typescript',
        'vim',
        'yaml',
      },
      auto_install = true,
      sync_install = true,
    },
    config = true,
  },
  {
    'ibhagwan/fzf-lua',
    opts = {
      global_resume = false,
      global_resume_query = true,
      file_icon_padding = ' ',
      file_icon_colors = {
        ['lua'] = 'blue',
      },
      winopts = {
        height = 0.85,
        width = 0.90,
        row = 0.35,
        col = 0.50,
        fullscreen = false,
        on_create = function()
          return vim.api.nvim_buf_set_keymap(0, 't', '<C-j>', '<Down>', {
            silent = true,
            noremap = true,
          })
        end,
      },
    },
    dependencies = { 'vijaymarupudi/nvim-fzf' },
    config = true,
  },
  {
    'mrjones2014/legendary.nvim',
    config = function()
      return require('plugins/legendary')
    end,
    dependencies = {
      {
        'folke/which-key.nvim',
        opts = {
          triggers = 'auto',
          plugins = {
            marks = true,
            registers = true,
            spelling = {
              enabled = false,
              suggestions = 20,
            },
            presets = {
              text_objects = true,
              operators = true,
              windows = true,
              motions = true,
              nav = true,
              z = true,
              g = true,
            },
          },
          operators = {
            gc = 'Comments',
          },
          key_labels = {
            ['<space>'] = 'Spc',
          },
          icons = {
            breadcrumb = '»',
            separator = '➜',
            group = '+',
          },
          popup_mappings = {
            scroll_down = '<c-d>',
            scroll_up = '<c-u>',
          },
          window = {
            border = 'none',
            position = 'bottom',
            margin = {
              0,
              0,
              1,
              0,
            },
            padding = {
              2,
              2,
              2,
              2,
            },
            winblend = 0,
          },
          layout = {
            height = {
              min = 4,
              max = 25,
            },
            width = {
              min = 20,
              max = 50,
            },
            spacing = 8,
            align = 'left',
          },
          ignore_missing = false,
          hidden = {
            '<silent>',
            '<cmd>',
            '<Cmd>',
            '<CR>',
            'call',
            'lua',
            '^:',
            '^ ',
          },
          show_help = true,
          show_keys = true,
          triggers_blacklist = {
            i = {
              'j',
              'k',
            },
            v = {
              'j',
              'k',
            },
          },
          disable = {
            buftypes = {},
            filetypes = {
              'TelescopePrompt',
            },
          },
        },
        config = true,
      },
    },
  },
  {
    'TimUntersberger/neogit',
    config = true,
  },
  {
    'kyazdani42/nvim-tree.lua',
    config = function()
      require('plugins/nvimtree')
    end,
    cmd = { 'NvimTreeToggle', 'NvimTreeOpen', 'NvimTreeFocus', 'NvimTreeFindFileToggle' },
    event = 'User DirOpened',
  },
  { 'windwp/nvim-autopairs', config = true, opts = { check_ts = true } },
  { 'euclidianAce/BetterLua.vim', ft = 'lua' },
  { 'tjdevries/manillua.nvim', ft = 'lua' },
  {
    'hrsh7th/nvim-cmp',
    event = 'InsertEnter',
    config = function()
      require('plugins/cmp')
    end,
    dependencies = {
      'hrsh7th/cmp-path',
      'hrsh7th/cmp-calc',
      'hrsh7th/cmp-emoji',
      'hrsh7th/cmp-buffer',
      'hrsh7th/cmp-cmdline',
      'hrsh7th/cmp-nvim-lsp',
      'hrsh7th/cmp-nvim-lua',
      'saadparwaiz1/cmp_luasnip',
      'ray-x/cmp-treesitter',
      'f3fora/cmp-spell',
      'tamago324/cmp-zsh',
      'davidsierradz/cmp-conventionalcommits',
      {
        'L3MON4D3/LuaSnip',
        dependencies = {
          'rafamadriz/friendly-snippets',
        },
        config = function()
          local luasnip = require('luasnip')

          luasnip.config.set_config({
            history = false,
            updateevents = 'TextChanged,TextChangedI',
          })

          require('luasnip/loaders/from_vscode').load()
        end,
      },
    },
  },
  { 'stevearc/dressing.nvim', event = 'VeryLazy' },
  { 'norcalli/nvim-colorizer.lua', event = 'VeryLazy' },
  'editorconfig/editorconfig-vim',
})
